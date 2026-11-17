# Daily terminal workflow

Use Bart's existing Neovim, Octo, tmux, and worktree tools for the daily pass.
The queue records review checkpoints. Codex reviews PRs and resolves conflicts in separate interactive tmux windows.

## Open the queue

In Neovim, run `:PrAttention` or press `<leader>pp`.
The former combined picker remains available through `<leader>pi`. The other PR filters remain available.
The configuration lives under `/home/barts/dotfiles/nvim/lua/helpers/pr_attention.lua`.
Discovery reuses `helpers/pr_inbox.lua` and the account-aware `gh` wrapper from Bart's dotfiles.

The daily queue shows direct requests, team requests, review follow-ups, and then Bart's authored PRs.
Secondary details appear below the selected PR as the cursor moves.
Selected details include the author, target branch, CI result, and available review decision.
Missing CI metadata appears as `CI not reported`.
Unresolved decisions and failures remain visible without selection.
Discovery includes previously reviewed open PRs even without a current review request.
These entries are candidates for inspection, not automatic review obligations.
Authored PRs that await others stay in the overview, available with `a`.

## Choose the appropriate route

| Key | Action |
| --- | --- |
| `o` | Open the PR in Octo for inspection, comments, or a manual review. |
| `D` | Show the code comparison from the last local assessment or submitted review. |
| `w` | Open the PR through `tsp-pr`, with the selected head as an explicit requirement. |
| `R` | Review the PR and your pending comments with Codex. Approve the exact draft before GitHub writes. |
| `F` | Rebase your PR and resolve conflicts with Codex. Finish with committed changes; approve or run the force push yourself. |
| `b` | Open the PR in the browser for media or other context. |
| `d` | Mark the displayed snapshot as checked locally. |
| `s` | Defer the displayed snapshot until tomorrow. |
| `u` | Remove the local checkpoint and deferral for the selected PR. |
| `a` | Show or hide checked, deferred, and waiting entries. |
| `r` | Collect a fresh snapshot from GitHub. |
| `?` | Show the complete key list. |

For a quick review, use Octo directly and return with `<leader>pp`.
For an approval-only decision, inspect the relevant context and use Octo's normal review submission flow.
The queue does not submit an approval automatically.
After finishing the assessment, mark the snapshot checked with `d`.

Press `R` to start an interactive Codex review in a separate tmux window.
The shortcut prepares the selected PR worktree and starts Codex there with the PR URL and expected head.
It uses `pr-post` directly. It does not collect another queue or switch to author-feedback work.
Codex reviews the code and critically assesses your existing pending review body and comments.
It proposes exact changes to stale, duplicate, or incorrect comments and preserves them until you approve those changes.
The complete draft includes every existing pending comment that submission will publish.
You can select findings, request edits, and choose submission or a pending review.
GitHub writes require your approval. If Codex cannot retrieve all pending comments, it must leave the review unsubmitted.

Press `F` for conflicts in your own open PR.
Codex starts in a separate tmux window and rebases the PR onto the current base branch.
This action authorizes local conflict resolutions, tests, and commits.
Codex must preserve the intent of both changes and ask you about unclear product decisions.
On success, the rebase is complete and all intended changes are committed.
The worktree must be clean, with no staged changes or unfinished Git operation.
Codex shows the commits, resolution diff, test results, and exact push command for inspection.
The command targets the PR source repository and branch, including forks.
It uses an explicit `--force-with-lease=refs/heads/<source-branch>:<recorded-remote-SHA>` lease.
Codex stops before pushing. Approve that push in the session or run the displayed command yourself.
If tests fail or a decision blocks progress, Codex must report the blocker instead of claiming success.

Both actions require Neovim inside tmux and the `codex` executable.
The queue stays open in its original window. Codex opens in the same tmux session.
Each PR gets a window named `codex-<owner>-<repo>-<number>`.
The initial prompt starts the interactive task automatically. You can reply and approve actions in that window.
A repeated shortcut returns to the existing Codex window for that PR instead of starting another task.
This also works after a Neovim restart and preserves the conversation and local worktree changes.
After Codex exits or its window closes, a shortcut prepares a new session through the usual worktree checks.
Use `Alt+<window number>` to return to the Neovim window or select another tmux window.
Codex continues while you use Neovim and does not depend on Neovim remaining open.
Use `w` to open the project through tmux without starting Codex.
The old `c`, `C`, `m`, and `M` queue actions and saved conflict reports are removed.
Existing report files remain on disk but the queue does not read them.

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
