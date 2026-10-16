---
name: pr-attention
description: Collect a daily GitHub PR attention queue and process selected batches through code-review drafts or proposed author changes and replies. Use for daily PR triage and resumable review work across repositories; use pr-respond or pr-post directly for a single specified PR.
---

# PR Attention

Collect PR work, prepare a selected batch, and apply approved actions. Keep progress between sessions.
Start with collection unless the user requests another operation. Collection does not authorize code changes or GitHub writes.

## Order and scope

Always present and process work in this order unless the user explicitly selects other items:

1. Direct review requests on PRs authored by others, including direct requests for another review.
2. The user's authored PRs that need a response, repair, or merge decision.
3. Team review requests on PRs authored by others.
4. Review follow-ups without a current request, assignment-only candidates, and reminders.

Within each group, prioritize explicit requests and unresolved conversations, then the oldest outstanding request.
Do not move authored work ahead of direct review requests because its CI failed.
Keep an authored PR in the authored group even if a team also needs to review it.
Use one queue entry per PR. Preserve every reason for inclusion without repeating the PR in multiple groups.

This workflow supports GitHub. Resolve the authenticated login, host, and any requested repository or organization scope.
Use the connected GitHub plugin first. Use `gh` when a required operation is unavailable through the plugin.
Use the `twg` CLI if the user requests Atlassian or connected-company context; do not expand discovery to Bitbucket by default.
Do not initiate login or installation as part of collection.

## Collect

Read [references/discovery.md](references/discovery.md) for candidate sources and classification rules.
Read [references/state.md](references/state.md) before creating or updating local progress records.

Collect metadata first. Batch independent reads and paginate results before claiming that a queue is complete.
Do not read every repository or perform every code review during collection.
Fetch only the additional evidence needed to classify candidates. Reserve deep assessment for selected items.
Include team requests and reminders in collection, after the first two groups.
Keep unavailable sources and uncertain candidates visible. Do not invent their contents or classify uncertainty as confirmed work.

Show a compact queue with stable ID, PR link, group, reason, proposed next step, and progress status.
Show counts per group, the scope and collection time, and any coverage gaps.
Summarize authored PRs that await others separately from actionable work. Keep drafts visible without treating every draft as urgent.
Preserve deferred entries and their reasons. Do not repeat a deferral prompt unless relevant state changes or its chosen date arrives.

Finish collection by asking which IDs to prepare. Suggest the first two eligible items in priority order.
Do not prepare them until the user selects them or requests the next batch.

## Prepare

Accept selected IDs or an instruction such as `prepare the next two`.
For `next` without a count, prepare at most two eligible PRs in priority order.
Skip deferred, completed, blocked, and unchanged items with an existing valid proposal.
Do not expand the batch without user direction. Save progress after each PR so a large item does not erase completed work.

For each selected PR, re-fetch its head, relevant comments, and review state. Read the current diff and necessary file context.
Use a separate checkout or worktree when local inspection is necessary. Preserve the user's working tree.

- **Review work:** Read and follow [pr-post](../pr-post/SKILL.md). Reuse current-head `/review` findings or run `/review`, then prepare its exact review draft. If the review capability is unavailable, report the limitation; do not claim that `/review` ran. A reply to a review conversation needs its own exact draft and target comment.
- **Author feedback:** Read and follow [pr-respond](../pr-respond/SKILL.md). Assess feedback critically and prepare numbered changes, clarifications, and replies.
- **CI failure or conflict:** Inspect current checks, available failure logs, or conflicting code. Propose the smallest justified repair, affected files, and validation. Identify unrelated or transient failures. Do not edit PR files during preparation. If a conflict cannot be assessed without edits, report that limit and propose an explicitly scoped resolution step.
- **Merge candidate:** Show the current requirements, checks, reviews, and blockers. Present a decision item. Do not merge, enable auto-merge, or close a PR without an explicit approved action.
- **Reminder:** Explain the evidence and draft an exact message only when the user selects reminder work. Collection does not authorize sending it.

Identify proposal items by PR and number, such as `R1.1` and `A2.3`. Do not make `approve item 1` ambiguous across PRs.
Keep complete proposals in local files. Present the exact actionable drafts for the current batch before requesting approval.
Include this final line in each proposed external comment, reply, or review summary:

`_Codex (AI) for Bart Steensma._`

If a review finds no actionable issues, report that result. Do not infer permission to approve the PR.
Stop the batch at proposals. Do not edit code, stage a GitHub pending review, or post replies during preparation.

### Review documents

For Markdown approval documents, use one task checkbox per action. Do not require the user to type a decision word.
Start every checkbox unchecked. Include the stable action ID in its label:

```markdown
### A5.2 — Handle a missing feature UUID

- [ ] Apply A5.2

**Your notes:** _None._

**Proposed action:** Replace the missing-UUID assertion with an explicit error.
```

A checked box approves the displayed action, including the user's edits.
An unchecked box authorizes no work. In a finished review, treat it as declined unless the notes request deferral or revision.
Read the notes with the checkbox. Preserve explicit instructions to leave an action pending.
After the user asks for execution, apply the selected actions. Do not act while the user edits the document.

If actions need separate approval, give code changes, replies, descriptions, commits, pushes, and merges separate checkboxes.
Accept existing documents with written decisions. Preserve their decisions and notes unless the user requests conversion.

## Apply

Queue selection authorizes assessment only. Require approval of the numbered changes and exact external text before applying them.
Use each worker skill's approval and finalization rules. Combine approvals across PRs only when targets and selections are unambiguous.
Do not request another confirmation for unchanged actions and exact text already approved in the current conversation.

Revalidate the head, relevant comments, diff anchors, check state, and target review immediately before the relevant action.
If relevant state changes, mark the proposal stale and rebuild the affected part before requesting approval again.
Apply only approved actions, run appropriate validation, and report results per PR.
Code approval does not implicitly approve committing, pushing, merging, resolving threads, or sending reminders. List these as distinct actions when proposed.

On a partial failure, stop writes for that PR. Record successful operations and returned identifiers.
Do not retry successful comments or submit a partial review without a revised approved draft.
Continue independent approved PR work only when the failure does not affect it.

## Resume

Load the saved queue for the authenticated host, login, and scope. Refresh discovery and remote state before selecting the next batch.
Preserve stable IDs, deferrals, proposals, and verified action results.
Invalidate proposals when the head or relevant feedback changes, even if the PR remains in the same group.
Do not invalidate a proposal solely because an unrelated timestamp changes.
Check changed feedback even when the head SHA stays the same.

Treat saved approval records as history, not permission to write in a new conversation.
Present an unfinished proposal again for approval unless the active conversation contains valid authorization for that exact proposal.
If a saved write has an uncertain outcome, reconcile remote state before retrying it.
Report completed items, remaining work, stale proposals, and the next suggested batch in the required order.

## Example requests

- `$pr-attention collect my daily queue.`
- `$pr-attention prepare R1 and R2.`
- `$pr-attention apply R1 comments 1 and 3, keep pending.`
- `$pr-attention resume and prepare the next two.`
