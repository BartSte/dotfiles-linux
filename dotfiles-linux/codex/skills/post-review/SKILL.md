---
name: post-review
description: Curate `/review` findings and add them as a user-approved GitHub pull-request review, either submitting the review or leaving it pending. Use when the user wants to inspect, select, edit, stage, post, publish, submit, or finalize code-review findings on a specific GitHub PR. Reuse earlier `/review` output when available; otherwise run `/review` first.
---

# Post a GitHub Pull-Request Review

Turn `/review` findings into precise inline GitHub comments. Treat every GitHub write as consequential: show the exact draft and require explicit approval before adding comments or submitting a review.

## GitHub integration

Use the connected GitHub plugin first for PR metadata, diffs, file context, reviews, pending-review state, and writes. Use `gh` only when the plugin lacks a required operation, especially for targeting or creating a pending review through GraphQL. Keep local and remote PR context aligned. Never use standalone issue comments as a fallback.

## 1. Resolve the PR and findings

- Require a specific PR URL or `owner/repo#number`. Ask if it cannot be inferred unambiguously.
- Resolve the open PR, current head SHA, changed-file patches, authenticated user, and that user's pending review.
- Reuse earlier `/review` output only when it applies to this PR and head, then verify every finding against the current diff.
- If there is no usable `/review` output, execute `/review` for the PR first.
- Keep actionable, non-duplicate findings. Preserve supplied priority or severity labels. Report stale, addressed, duplicate, disputed, and non-actionable findings separately.

## 2. Prepare review candidates

- Anchor each finding to a changed diff line. Prefer `RIGHT`; use the appropriate side for deletions only when GitHub supports it.
- Fetch surrounding file content when needed to verify the anchor or wording.
- Mark findings without a valid diff anchor as `UNPOSTABLE`. Offer an explicitly drafted review-body alternative; never silently move or convert a comment.
- Exclude equivalent comments already present in the user's pending or submitted reviews.
- Write GitHub-facing text in plain, simple, informal English. Keep it concise, factual, and actionable. Preserve code identifiers, error messages, technical meaning, and user-supplied severity.

Show numbered candidates with the complete body, path, line, side, and supplied severity or title. Show unpostable and excluded findings separately.

Ask the user:

1. Which comments should be included (`1,3`, `all`, or `none`)?
2. Should any selected comment or the review summary be edited?
3. Should the result be `submit` or `keep pending`?

Do not treat selection as posting approval.

## 3. Choose finalization behavior

### Submit

- Default the review action to `COMMENT`.
- Use `REQUEST_CHANGES` only when the user chooses it.
- Never use `APPROVE` while selected unresolved findings remain; use it only on explicit user direction.
- Prefer the authenticated user's existing pending review: add the selected comments, then submit that exact review with the approved action and summary.
- If no user-owned pending review exists, create and submit one review containing all selected comments and the summary.

### Keep pending

- Add the selected comments to the authenticated user's existing pending review and do not submit it.
- If none exists, create a new pending review when the available GitHub operation supports this safely. Otherwise stop and explain that no pending review could be created; never substitute a submitted review.
- Do not add a final submitted review action such as `COMMENT`, `REQUEST_CHANGES`, or `APPROVE`.
- Never modify another user's pending review.

## 4. Require exact-draft approval

Add a short summary covering only the selected points. For `keep pending`, include it in the pending review only when the chosen operation can store an unsubmitted review body; otherwise show it as deferred until submission.

Show the exact final draft with:

- repository, PR, and head SHA;
- finalization mode: `submit` or `keep pending`;
- review action for `submit`;
- target: existing pending review ID, new submitted review, or new pending review;
- every inline path, line, side, and complete body;
- the complete review summary or its deferred status;
- an explicit statement of whether the result will be submitted.

Ask: `Approve applying this review exactly as shown?`

Require an explicit affirmative response such as `yes`, `approved`, `post it`, or `add them`. If any body, anchor, selection, action, summary, target, or finalization mode changes, show the revised exact draft and obtain approval again.

## 5. Revalidate and write

Immediately before writing:

- Re-fetch the head SHA, review state, selected patches, and duplicates.
- Stop and rebuild the draft if the head, anchor, target review, or selected content changed.
- Ensure the pending review belongs to the authenticated user.

Then apply only the approved draft:

- For `submit`, target the approved pending review or create one new review, and submit it with the approved action and summary.
- For `keep pending`, target or create the approved pending review, add the comments, and leave it unsubmitted.
- Never add unselected, duplicate, or unpostable comments.
- If a write fails partway through, stop. Report exactly what was added and do not retry successful comments. Never submit a partial review without a newly approved draft.

## 6. Verify and report

- For `submit`, verify the review was submitted with the intended action, comments, and summary.
- For `keep pending`, verify the review remains `PENDING` and `submitted_at` is unset.
- Report the review URL or ID when available, posted and skipped counts, partial failures, and whether the review is submitted or pending.

## Draft format

```markdown
Ready to apply this review exactly as shown:

Repo: `owner/repo`
PR: `#123`
Head commit: `abc123...`
Finalization: `submit` # or `keep pending`
Review action: `COMMENT` # submit only
Target: existing pending review `987654` by `login` # or new review

Inline comments:
1. `[P1] src/example.py:42` RIGHT
   Body: This fails when `limit` is missing. Please handle the default first.

Review summary:
Please handle the missing `limit` case before this call.

This review will be submitted. # or: This review will remain pending.

Approve applying this review exactly as shown?
```
