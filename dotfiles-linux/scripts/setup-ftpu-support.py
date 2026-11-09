#!/usr/bin/env python3
"""Read Tailscale state and calculate narrowly scoped firewall changes."""
import ipaddress
import json
from pathlib import Path
import shlex
import sys

TAILNETS = (ipaddress.ip_network('100.64.0.0/10'),
            ipaddress.ip_network('fd7a:115c:a1e0::/48'))


def select_phone(status, selector='', saved=None):
    if status.get('BackendState') != 'Running':
        raise ValueError('Tailscale is not connected. Run sudo tailscale up first.')
    peers = [p for p in (status.get('Peer') or {}).values()
             if p.get('OS') == 'android' and not p.get('Expired')]
    saved_id = (saved or {}).get('phone', {}).get('id')
    if selector:
        needle = selector.lower().rstrip('.')
        selected = [p for p in peers if needle in {
            str(p.get('ID', '')).lower(), str(p.get('HostName', '')).lower(),
            str(p.get('DNSName', '')).lower().rstrip('.'),
            str(p.get('DNSName', '')).lower().split('.')[0],
            *[ip.lower() for ip in p.get('TailscaleIPs', [])],
        }]
    elif saved_id:
        selected = [p for p in peers if p.get('ID') == saved_id]
        if not selected:
            raise ValueError('Saved phone is missing or expired. Select its replacement with --tailscale-phone NAME.')
    else:
        selected = peers if len(peers) == 1 else [p for p in peers if p.get('Online')]
    if len(selected) != 1:
        names = ', '.join(p.get('DNSName') or p.get('HostName', '?') for p in peers) or '(none)'
        raise ValueError(f'Cannot select exactly one Android phone. Use --tailscale-phone NAME. Candidates: {names}')
    peer = selected[0]
    addresses = []
    for value in peer.get('TailscaleIPs', []):
        address = ipaddress.ip_address(value)
        if not any(address.version == net.version and address in net for net in TAILNETS):
            raise ValueError('Phone has an unexpected non-Tailscale address.')
        addresses.append(str(address))
    if not peer.get('ID') or not addresses:
        raise ValueError('Selected phone has no stable identity or Tailscale address.')
    server = status.get('Self') or {}
    server_ips = [str(ipaddress.ip_address(ip)) for ip in server.get('TailscaleIPs', [])]
    if not server_ips:
        raise ValueError('The Pi has no Tailscale address.')
    # Keep one peer identity, including both address families, even while offline.
    return {
        'phone': {'id': peer['ID'], 'name': peer.get('HostName', ''), 'ips': addresses},
        'server': {'name': (server.get('DNSName') or '').rstrip('.'), 'ips': server_ips},
    }


def firewall_plan(text, sources):
    desired = [('allow', 'from', source, 'to', 'any', 'port', '2222', 'proto', 'tcp',
                'comment', 'setup-ftpu') for source in sources]
    existing = []
    for line in text.splitlines():
        args = shlex.split(line)
        if args[:1] == ['ufw']:
            existing.append(tuple(args[1:]))
    # Only remove this script's narrowly shaped rules. Never interpret arbitrary
    # text as shell code or delete an unrelated administrator rule.
    managed = [rule for rule in existing if len(rule) == 11
               and rule[:2] == ('allow', 'from')
               and rule[3:] == ('to', 'any', 'port', '2222', 'proto', 'tcp', 'comment', 'setup-ftpu')]
    remove = [list(rule) for rule in managed if rule not in desired]
    # UFW considers comments metadata: re-adding an administrator's identical
    # rule would replace its comment and incorrectly claim ownership of it.
    existing_core = {rule[:rule.index('comment')] if 'comment' in rule else rule
                     for rule in existing}
    add = [list(rule) for rule in desired if rule[:9] not in existing_core]
    return {'remove': remove, 'add': add}


def main():
    try:
        if sys.argv[1] == 'phone':
            saved = Path(sys.argv[3])
            result = select_phone(json.load(sys.stdin), sys.argv[2],
                                  json.loads(saved.read_text()) if saved.exists() else None)
        elif sys.argv[1] == 'firewall':
            result = firewall_plan(sys.stdin.read(), sys.argv[2:])
        else:
            raise ValueError('Unknown helper operation.')
        print(json.dumps(result))
    except (ValueError, OSError) as error:
        sys.exit(f'Error: {error}')


if __name__ == '__main__':
    main()
