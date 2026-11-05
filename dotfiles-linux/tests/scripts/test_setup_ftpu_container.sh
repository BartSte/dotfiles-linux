#!/usr/bin/env bash
# Run only in the disposable container described in setup-ftpu.md.
set -euo pipefail
[[ -f /.dockerenv && ${FTPU_TEST_CONTAINER:-} == 1 && $EUID == 0 ]] || {
    echo 'This test requires the disposable Docker test container.' >&2
    exit 1
}
# shellcheck source=../../scripts/setup-ftpu
source /work/scripts/setup-ftpu
finish() {
    [[ -z ${SERVER_PID:-} ]] || kill "$SERVER_PID"
    [[ -z ${ADMIN_PID:-} ]] || kill "$ADMIN_PID"
    if mountpoint -q "$JAIL/data"; then umount "$JAIL/data" || true; fi
    if mountpoint -q "$JAIL/drive"; then umount "$JAIL/drive" || true; fi
    if mountpoint -q "$DRIVE_MOUNT"; then umount "$DRIVE_MOUNT" || true; fi
    rm -rf /tmp/ftpu-integration
}
trap finish EXIT
install -d -m 755 /run/sshd
install -d -m 755 /run/ftpu-sftp
ssh-keygen -A
useradd -m -s /bin/bash barts
useradd -M -d /data -s /usr/sbin/nologin ftpu
printf 'barts:integration-only\nftpu:integration-only\n' | chpasswd
ALLOW_FROM=127.0.0.1/32
PHONE_JSON='{"phone":{"id":"test-phone","name":"Test phone","ips":["100.100.100.101","fd7a:115c:a1e0::1234"]}}'
ip address add 100.100.100.101/32 dev lo
ip address add 100.100.100.102/32 dev lo
ip -6 address add fd7a:115c:a1e0::1234/128 dev lo
WORK=/tmp/ftpu-integration
mkdir -m 700 "$WORK"
DRIVE_MOUNT="$WORK/drive"
JAIL=/home/ftpu
install -d -o root -g root -m 755 "$JAIL"
install -d -o root -g root -m 555 "$JAIL/data"
install -d -o root -g root -m 555 "$JAIL/drive"
runuser -u ftpu -- test ! -w "$JAIL/data"
runuser -u ftpu -- test ! -w "$JAIL/drive"

# An NTFS image uses FUSE directly, without touching host loop devices.
truncate -s 80M "$WORK/ntfs.img"
mkntfs -F -Q "$WORK/ntfs.img"
mkdir "$DRIVE_MOUNT"
mount -t ntfs-3g -o "$(ntfs_options "$(id -u ftpu)" "$(id -g ftpu)")" "$WORK/ntfs.img" "$DRIVE_MOUNT"
# The private staging directory is only for this image fixture; give ftpu
# traversal so that runuser can test the real NTFS ownership and masks.
chmod 711 "$WORK"
mkdir "$DRIVE_MOUNT/PhoneBackups"
mount --bind "$DRIVE_MOUNT/PhoneBackups" "$JAIL/data"
mount -o remount,bind,nosuid,nodev,noexec "$JAIL/data"
mount --bind "$DRIVE_MOUNT" "$JAIL/drive"
mount -o remount,bind,nosuid,nodev,noexec "$JAIL/drive"
UUID=$(blkid -s UUID -o value "$WORK/ntfs.img")
# NTFS-3G reports "fuse" for an image and "fuseblk" for a partition.
# Normalize only that fixture difference; UUID, subdirectory, mount options
# and permissions are still checked against the real image mount.
[[ $(findmnt -rn --mountpoint "$DRIVE_MOUNT" -o FSTYPE) == fuse ]]
mount_at() {
    if [[ $2 == FSTYPE ]]; then
        [[ $(findmnt -rn --mountpoint "$1" -o SOURCE) == "$WORK/ntfs.img" ]]
        printf 'fuseblk\n'
    else
        findmnt -rn --mountpoint "$1" -o "$2"
    fi
}
verify_mounts
verify_covered_directory
verify_covered_directory drive
[[ $(stat -c '%u:%g:%a' "$JAIL/data") == "$(id -u ftpu):$(id -g ftpu):700" ]]
runuser -u ftpu -- test -w "$JAIL/data"
printf 'secret\n' > "$DRIVE_MOUNT/not-shared"
mkdir "$DRIVE_MOUNT/Documents"
printf 'existing document\n' > "$DRIVE_MOUNT/Documents/existing.txt"

cat > "$WORK/sshd.base" <<'EOF'
Port 22
ListenAddress 127.0.0.1
UsePAM no
PasswordAuthentication yes
Subsystem sftp internal-sftp
EOF
SSHD_CONFIG="$WORK/sshd.base"
ssh_block > "$WORK/ssh.block"
render_config ssh "$SSHD_CONFIG" "$WORK/ssh.block" "$WORK/sshd.admin"
validate_ssh "$WORK/sshd.admin"
sshd -D -e -f "$WORK/sshd.admin" > "$WORK/admin.log" 2>&1 &
ADMIN_PID=$!
sftp_config > "$WORK/sshd.test"
validate_sftp "$WORK/sshd.test"
sshd -D -e -f "$WORK/sshd.test" > "$WORK/server.log" 2>&1 &
SERVER_PID=$!
for _ in {1..50}; do
    if ssh-keyscan -T 1 -p 2222 127.0.0.1 > /dev/null 2>&1; then break; fi
    sleep 0.1
done

ssh_options=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3)
sftp_options=("${ssh_options[@]}" -P 2222)
export SSHPASS=integration-only
printf 'a photo\n' > "$WORK/photo"
cat > "$WORK/batch" <<EOF
put $WORK/photo /data/photo
get /data/photo $WORK/download
rename /data/photo /data/renamed
rm /data/renamed
get /drive/Documents/existing.txt $WORK/existing-download
mkdir /drive/Documents/manual-test
put $WORK/photo /drive/Documents/manual-test/upload
get /drive/Documents/manual-test/upload $WORK/manual-download
rename /drive/Documents/manual-test/upload /drive/Documents/manual-test/renamed
rm /drive/Documents/manual-test/renamed
rmdir /drive/Documents/manual-test
EOF
sshpass -e sftp "${sftp_options[@]}" -o BatchMode=no -b "$WORK/batch" ftpu@127.0.0.1
cmp "$WORK/photo" "$WORK/download"
cmp "$WORK/photo" "$WORK/manual-download"
cmp "$DRIVE_MOUNT/Documents/existing.txt" "$WORK/existing-download"
[[ ! -e $DRIVE_MOUNT/PhoneBackups/renamed ]]

printf 'get /not-shared %s/leaked\n' "$WORK" > "$WORK/batch"
if sshpass -e sftp "${sftp_options[@]}" -o BatchMode=no -b "$WORK/batch" ftpu@127.0.0.1; then
    die 'SFTP escaped the shared directory.'
fi
[[ ! -e $WORK/leaked ]]
# A forced SFTP process must never execute the requested command.
sshpass -e ssh "${ssh_options[@]}" -p 2222 -T ftpu@127.0.0.1 "touch /data/shell-executed" </dev/null || true
[[ ! -e $DRIVE_MOUNT/PhoneBackups/shell-executed ]]
if timeout 10 sshpass -e ssh "${ssh_options[@]}" -p 2222 -o ExitOnForwardFailure=yes -R 0:127.0.0.1:22 -N ftpu@127.0.0.1; then
    die 'Forwarding unexpectedly succeeded.'
else
    [[ $? != 124 ]] || die 'Forwarding did not fail promptly.'
fi
if sshpass -e ssh "${ssh_options[@]}" -p 2222 -b 127.0.0.2 ftpu@127.0.0.1 true; then
    die 'A source outside the allowed subnet authenticated.'
fi
[[ $(sshpass -e ssh "${ssh_options[@]}" barts@127.0.0.1 'printf admin-ok') == admin-ok ]]
if sshpass -e ssh "${ssh_options[@]}" -p 2222 barts@127.0.0.1 true; then
    die 'The dedicated service accepted an administrative account.'
fi
# Simulate the selected phone's actual source-address families on loopback.
printf 'pwd\n' > "$WORK/batch"
sshpass -e sftp "${sftp_options[@]}" -o BindAddress=100.100.100.101 -o BatchMode=no -b "$WORK/batch" ftpu@127.0.0.1
sshpass -e sftp "${sftp_options[@]}" -o BindAddress=fd7a:115c:a1e0::1234 -o BatchMode=no -b "$WORK/batch" 'ftpu@[::1]'
if sshpass -e ssh "${ssh_options[@]}" -p 2222 -b 100.100.100.102 ftpu@127.0.0.1 true; then
    die 'Another tailnet device authenticated.'
fi

# A missing upload mount exposes only a root-owned, unwritable directory.
umount "$JAIL/data"
umount "$JAIL/drive"
umount "$DRIVE_MOUNT"
runuser -u ftpu -- test ! -w "$JAIL/data"
runuser -u ftpu -- test ! -w "$JAIL/drive"
printf 'put %s/photo /data/sd-card-leak\n' "$WORK" > "$WORK/batch"
if sshpass -e sftp "${sftp_options[@]}" -o BatchMode=no -b "$WORK/batch" ftpu@127.0.0.1; then
    die 'Upload succeeded without the drive.'
fi
[[ ! -e $JAIL/data/sd-card-leak ]]
printf 'put %s/photo /drive/sd-card-leak\n' "$WORK" > "$WORK/batch"
if sshpass -e sftp "${sftp_options[@]}" -o BatchMode=no -b "$WORK/batch" ftpu@127.0.0.1; then
    die 'Manual upload succeeded without the drive.'
fi
[[ ! -e $JAIL/drive/sd-card-leak ]]
printf 'PASS: NTFS permissions, SFTP on 2222, confinement, LAN and phone IPv4/IPv6, denied second device, preserved admin SSH and missing-drive protection\n'
