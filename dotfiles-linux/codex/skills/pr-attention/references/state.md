# Local progress records

Store runtime state outside repositories and the skill source:

`${XDG_STATE_HOME:-$HOME/.local/state}/codex/pr-attention/<host>/<login>/`

Use `queue.json` for the queue and `proposals/<stable-id>/rev-001.md` for the first proposal revision.
For the daily terminal queue, read [daily-workflow.md](daily-workflow.md#interpret-checkpoints) before interpreting its separate checkpoint files.
Increment the revision number for each replacement proposal. Preserve earlier revisions and point the queue to the current revision.
Keep one PR record per canonical identity across scopes, with collection time, filters, and source coverage stored per scope.
Record a default scope only when the user explicitly establishes one. Keep the latest collection scope separately for resume.
During a narrow refresh, update only that scope's coverage. Preserve other scopes and their entries.
Accept existing flat proposal paths. Preserve them as history when creating the next revision in the new directory layout.
Sanitize path components. Do not put access tokens, credentials, or complete CI logs in state.
Restrict directory and file access to the user. Write updates atomically and preserve existing records.

## Queue contents

Record the schema version, authenticated host and login, per-scope collections, optional explicit default scope, latest scope, and entries.
When updating older state, preserve existing data and record the schema migration without resetting IDs or action history.
Each entry contains:

- A stable queue ID and canonical PR URL or host/repository/number key.
- Current group, inclusion reasons, evidence links, and proposed next action.
- Current head SHA, relevant review/comment identifiers, and assessment time.
- A feedback snapshot sufficient to detect edited comments, new replies, resolved threads, and changed review requests.
- The last assessed head and the last verified completed action, kept separately.
- Progress status: `new`, `preparing`, `proposed`, `stale`, `applying`, `partial`, `done`, `deferred`, or `blocked`.
- Proposal path and revision; selected actions and approval history when available.
- Verified action results linked to their proposal revision and action ID, remote IDs, local checkout paths, validation results, and failures.
- For blockers, the cause, evidence, and condition that permits reassessment.
- For deferrals, the reason, optional resume date, and any condition that ends the deferral.

Allocate IDs once, using prefixes such as `R`, `A`, `T`, and `F` plus a monotonically increasing number.
The prefix records the initial group. Keep the ID when a PR changes groups; the current group controls ordering.
Never reuse an ID for a different PR. Deduplicate by canonical PR identity across scopes.

## Proposal contents

Record the PR, head SHA, relevant feedback snapshot, revision, exact numbered actions, and exact external text.
Keep IDs for unchanged actions across revisions.
If an action's meaning or target changes, retire its ID. Never reuse it for another action.
Record each action's prerequisites, expected effects, and success evidence, including required validation.
Record verified effects separately from predictions. Only verified effects update the expected state for dependent actions.
Include review targets and anchors, affected files, intended validation, and worker skill used.
Include only evidence needed to resume the work; link to remote sources for larger material.
Store the final attribution line as part of the exact proposed text.

## Refresh and recovery

`done` means the selected actions succeeded at the recorded state. It does not suppress future requests or feedback.
Reopen completed entries when new evidence requires action. Keep prior results to prevent duplicate writes.
Use `partial` for confirmed partial completion and `blocked` for a missing capability or inaccessible evidence.
Report the blocker and continue discovery or other independent work.
During refresh, reassess each blocker once using available capability or access evidence.
If it clears, restore a valid proposal to `proposed`, an invalid proposal to `stale`, or an unprepared entry to `new`.
If it persists, retain `blocked` and avoid repeated attempts during that refresh.
When a deferral date arrives or its stated condition changes, reassess the entry before selecting the next batch.
Restore eligible deferred entries using the same proposal rules. Keep deferrals without a due date or changed condition deferred.
Recovery never restores write permission from a previous conversation.

A proposal is stale when its head or relevant feedback differs from the last verified expected state.
Verified effects of approved actions update the expected state for their dependent actions, subject to reassessment of their assumptions.
Material changes to an action still require a new proposal and approval. Preserve the previous revision for action history.
Unrelated activity alone does not make it stale.
On interrupted preparation, keep finished proposals and rebuild only the unfinished item.
On interrupted application, reconcile remote review/comment IDs and local file state before repeating any operation.
If reconciliation cannot establish whether a write succeeded, stop writes for that PR and report the uncertainty.

Approval history records what happened. It never authorizes new writes by itself.
Keep terminal entries in history. Do not remove entries because a source failed or search results were incomplete.
