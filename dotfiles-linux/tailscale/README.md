# Tailscale (Raspberry Pi)

Installs Tailscale and enables SSH over Tailscale.

## Usage

```bash
~/dotfiles-linux/tailscale/main
```

If you want non-interactive setup, set an auth key:

```bash
export TS_AUTHKEY="tskey-..."
~/dotfiles-linux/tailscale/main
```

Otherwise, it will print:

```
sudo tailscale up --ssh
```

and you complete the login in a browser.
