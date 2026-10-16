# Local progress records

Store runtime state outside repositories and the skill source:

`${XDG_STATE_HOME:-$HOME/.local/state}/codex/pr-attention/<host>/<login>/`

Use `queue.json` for the queue and `proposals/<stable-id>.md` for exact drafts and supporting evidence.
Separate scopes within the queue. Record the organization or repository filters for each collection.
Sanitize path components. Do not put access tokens, credentials, or complete CI logs in state.
Restrict directory and file access to the user. Write updates atomically and preserve existing records.

## Queue contents

Record the schema version, authenticated host and login, collection time, scope, source coverage, and entries.
Each entry contains:

- A stable queue ID and canonical PR URL or host/repository/number key.
- Current group, inclusion reasons, evidence links, and proposed next action.
- Current head SHA, relevant review/comment identifiers, and assessment time.
- A feedback snapshot sufficient to detect edited comments, new replies, resolved threads, and changed review requests.
- The last assessed head and the last verified completed action, kept separately.
- Progress status: `new`, `preparing`, `proposed`, `stale`, `applying`, `partial`, `done`, `deferred`, or `blocked`.
- Proposal path and revision; selected actions and approval history when available.
- Verified action results, remote IDs, local checkout paths, validation results, and failures.
- For deferrals, the reason and optional resume date.

Allocate IDs once, using prefixes such as `R`, `A`, `T`, and `F` plus a monotonically increasing number.
The prefix records the initial group. Keep the ID when a PR changes groups; the current group controls ordering.
Never reuse an ID for a different PR. Deduplicate by canonical PR identity across scopes.

## Proposal contents

Record the PR, head SHA, relevant feedback snapshot, revision, exact numbered actions, and exact external text.
Include review targets and anchors, affected files, intended validation, and worker skill used.
Include only evidence needed to resume the work; link to remote sources for larger material.
Store the final attribution line as part of the exact proposed text.

## Refresh and recovery

`done` means the selected actions succeeded at the recorded state. It does not suppress future requests or feedback.
Reopen completed entries when new evidence requires action. Keep prior results to prevent duplicate writes.
Use `partial` for confirmed partial completion and `blocked` for a missing capability or inaccessible evidence.
Report the blocker and continue discovery or other independent work.

A proposal is stale when its head or relevant feedback changes. Preserve the previous revision for action history.
Unrelated activity alone does not make it stale.
On interrupted preparation, keep finished proposals and rebuild only the unfinished item.
On interrupted application, reconcile remote review/comment IDs and local file state before repeating any operation.
If reconciliation cannot establish whether a write succeeded, stop writes for that PR and report the uncertainty.

Approval history records what happened. It never authorizes new writes by itself.
Keep terminal entries in history. Do not remove entries because a source failed or search results were incomplete.
