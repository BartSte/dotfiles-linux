# Daily terminal workflow

Use Bart's existing Neovim, Octo, tmux, and worktree tools for the daily pass.
The queue records review checkpoints. Codex handles selected assessments and proposals through the existing worker skills.

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
| `c` | Open the PR worktree and insert its brief into the Codex window. |
| `C` | Show and copy the brief for manual use. |
| `m` | Resolve conflicts locally, or resume the existing merge with your decision. |
| `M` | Open the selected PR's saved conflict report. |
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

For deeper assessment, press `c` to prepare the worktree and open its project session.
The shortcut waits for a Codex pane in that worktree, inserts the exact brief, and focuses the pane.
It uses `key2pane` for literal text, like `<leader>as`. It leaves submission to the user and does not interrupt Codex.
Press Enter in Codex to start the assessment with `pr-post` or `pr-respond` as appropriate.
If multiple panes remain ambiguous, use `C` to inspect and copy the brief for manual delivery.
Use `w` to open the project layout without inserting a prompt.
The brief requests preparation only. Existing approval rules still control changes and GitHub writes.

For your own PR, press `m` to start conflict resolution without an extra Enter in Codex.
The shortcut reads fresh PR metadata and starts a separate `codex exec` task in the PR worktree.
The queue keeps focus. This action does not open or switch tmux sessions and does not require tmux.
The task uses the existing Codex configuration and leaves the local merge uncommitted for review.
For a new resolution, the task must stop for local changes or unfinished Git operations.
For a continuation, the task preserves the recorded merge and its resolved files.
Unclear product decisions remain unresolved and appear in the final report.
Progress and completion appear through Neovim notifications, with the worktree path.
Press `M` to open the saved report. Completion does not open a buffer automatically.
Reports remain available after closing their buffers or restarting Neovim.
Keep the original Neovim process open until the task finishes.
The saved process ID blocks another task while the recorded resolver process remains alive.
Codex also saves its final response directly, so a completed response can remain available without the original callback.
This action does not authorize a commit, push, GitHub comment, or PR merge.

The queue shows local status beside GitHub status. GitHub can still report conflicts before a push.
The shortcut inspects Git after the task finishes and when you open the report or refresh the queue.
A zero task exit code does not prove that Git conflicts are resolved.

| Local status | Meaning |
| --- | --- |
| Ready for review | The expected checkout has an open merge with no unresolved Git files. Commit and push remain pending. |
| Needs a decision | Git still lists unresolved files. Read the blocker and task report. |
| Failed | The task failed, the checkout changed unexpectedly, or Git cannot inspect the merge. |
| Committed locally | You explicitly committed the reviewed merge. A push remains pending. |
| Published | You explicitly pushed the recorded commit to the PR source branch. Refresh GitHub status. |

In the report, press `d` to inspect the staged and unstaged diffs.
Press `m` to supply the missing decision and resume an unresolved merge.
For example, enter `Use policy version 5.` The continuation preserves the existing merge.
Read the test results before committing. Ready for review does not prove that tests passed or that the resolution is correct.
Press `c` to confirm review and enter a commit message. Normal Git hooks still run.
Press `p` to confirm a separate push to the source branch from fresh PR metadata.
The push never uses force. Neither action runs automatically after conflict resolution.

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
