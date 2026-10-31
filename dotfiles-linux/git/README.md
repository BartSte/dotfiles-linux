# GitHub account selection

Git selects the personal or work configuration through its `includeIf` rules.
The `bin/gh` wrapper reads `gh.user` from that effective configuration.

- Personal configuration: `gh.user = BartSte`.
- Work configuration: `gh.user = b-steensma_fleet`.

The wrapper retrieves the selected account's stored token with `gh auth token`.
It passes that token to the GitHub CLI through `GH_TOKEN` for one command.
It does not change the globally active account or write tokens to files.

The wrapper must precede the GitHub CLI on `PATH`. The dotfiles shell configuration
already includes `dotfiles-linux/bin`. Octo uses the same executable through `PATH`.
The PR inbox cache includes the configured account in its cache key.

Authentication commands and explicit `GH_TOKEN` or `GITHUB_TOKEN` values retain
the normal GitHub CLI behavior. Explicit non-default hosts also bypass account
selection. Without a configured account, the wrapper uses the active gh account,
except inside `~/code/personal`.
An unavailable configured account produces an error.

Account selection follows the working directory, including subdirectories and
Git worktrees. An explicit repository argument does not select a different account.
Inside `~/code/personal` or its subdirectories, the wrapper uses the personal
configuration even before a repository exists. This also selects the personal
account for clone commands from that directory. An explicit repository account
takes precedence over this directory fallback. Other directories retain the
active account when Git supplies no account.

The PR inbox cache also includes the working directory to distinguish these
directory-based selections.

Run `gh api user --jq .login` inside a repository to show the selected account.
Run `gh auth status` to inspect the stored accounts and global active account.
