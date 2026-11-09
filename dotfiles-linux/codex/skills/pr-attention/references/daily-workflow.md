# Daily terminal workflow

Use Bart's existing Neovim, Octo, tmux, and worktree tools for the daily pass.
The queue records review checkpoints. Codex handles selected assessments and proposals through the existing worker skills.

## Open the queue

In Neovim, run `:PrAttention` or press `<leader>pp`.
The former combined picker remains available through `<leader>pi`. The other PR filters remain available.
The configuration lives under `/home/barts/dotfiles/nvim/lua/helpers/pr_attention.lua`.
Discovery reuses `helpers/pr_inbox.lua` and the account-aware `gh` wrapper from Bart's dotfiles.

The daily queue shows direct requests, team requests, review follow-ups, and then Bart's authored PRs.
Discovery includes previously reviewed open PRs even without a current review request.
These entries are candidates for inspection, not automatic review obligations.
Authored PRs that await others stay in the overview, available with `a`.

## Choose the appropriate route

| Key | Action |
| --- | --- |
| `o` | Open the PR in Octo for inspection, comments, or a manual review. |
| `D` | Show the code comparison from the last local assessment or submitted review. |
| `w` | Open the PR through `tsp-pr`, with the selected head as an explicit requirement. |
| `c` | Open the PR worktree and insert its brief into the Codex window. |
| `C` | Show and copy the brief for manual use. |
| `b` | Open the PR in the browser for media or other context. |
| `d` | Mark the displayed snapshot as checked locally. |
| `s` | Defer the displayed snapshot until tomorrow. |
| `u` | Remove the local checkpoint and deferral for the selected PR. |
| `a` | Show or hide checked, deferred, and waiting entries. |
| `r` | Collect a fresh snapshot from GitHub. |

For a quick review, use Octo directly and return with `<leader>pp`.
For an approval-only decision, inspect the relevant context and use Octo's normal review submission flow.
The queue does not submit an approval automatically.
After finishing the assessment, mark the snapshot checked with `d`.

For deeper assessment, press `c` to prepare the worktree and open its project session.
The shortcut waits for a Codex pane in that worktree, inserts the exact brief, and focuses the pane.
It uses `key2pane` for literal text, like `<leader>as`. It leaves submission to the user and does not interrupt Codex.
Press Enter in Codex to start the assessment with `pr-post` or `pr-respond` as appropriate.
If multiple panes remain ambiguous, use `C` to inspect and copy the brief for manual delivery.
Use `w` to open the project layout without inserting a prompt.
The brief requests preparation only. Existing approval rules still control changes and GitHub writes.

The shortcut fetches the current PR head through the base repository, including PRs from forks.
If a clean checkout is behind, `w` fast-forwards it before opening the tmux session.
If the remote head differs from the selected snapshot, refresh the queue before opening the worktree.
If an update needs local changes removed or history rewritten, the shortcut stops and explains the blocker.
It also stops for unfinished Git operations and ignored files that the update would overwrite.
Inspect these blockers before updating the worktree. The shortcut preserves local commits and changes.
Return to the queue and refresh after completing work through Octo, Codex, or the browser.

## Interpret checkpoints

Checkpoints use this shared location:

`${XDG_STATE_HOME:-$HOME/.local/state}/codex/pr-attention/<host>/<login>/checkpoints/<sha256-of-PR-URL>.json`

The terminal queue owns these versioned records. They contain no write authorization.
Keep `queue.json`, proposal history, and checkpoint files separate.
Read a checkpoint only for the matching authenticated host, login, and canonical PR URL.
Use `baseline_head` and `baseline_at` as the last explicit local assessment.
A record without those fields represents deferral only, not completed assessment.
Prefer a newer submitted review when its timestamp follows that assessment.
Never represent a local checkpoint as `/review` output or GitHub approval.

The fingerprint covers the head, PR activity, recent reviews, the latest review request, merge state, checks, and inclusion sources.
New evidence resurfaces a checked or deferred PR. A due deferral becomes eligible again.
Activity is a discovery signal. Inspect the conversation before claiming that a reply needs action.
Deferral alone does not advance the assessment baseline.

## Coverage and limits

The queue collects metadata first and reports searches that exceed GitHub's 1,000-result limit.
It inspects the latest 20 reviews per PR. It labels missing review baselines when earlier history exists.
Request history and recent metadata do not replace a complete conversation assessment for selected work.
The queue currently uses all accessible repositories for the selected account and host.

The comparison uses GitHub's commit comparison API. Missing patches and the 300-file limit remain visible.
After a force push or divergent history, inspect both snapshots in the worktree and the complete PR in Octo.
A comparison alone cannot establish that an earlier concern is resolved.
The worktree shortcut currently supports github.com. Other hosts retain Octo and browser inspection.
