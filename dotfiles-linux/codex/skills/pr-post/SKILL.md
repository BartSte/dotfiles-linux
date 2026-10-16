---
name: pr-post
description: Curate `/review` findings and add them as a user-approved GitHub pull-request review, either submitting the review or leaving it pending. Use when the user wants to inspect, select, edit, stage, post, publish, submit, or finalize code-review findings on a specific GitHub PR. Reuse earlier `/review` output when available; otherwise run `/review` first.
---

# Post a GitHub Pull-Request Review

Turn `/review` findings into precise inline GitHub comments. Show the exact draft before any GitHub write. Combine comment selection and approval in one user response. Do not ask for a second confirmation of choices that the draft already covers.

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

Prepare numbered candidates with the complete body, path, line, side, and supplied severity or title. Show unpostable and excluded findings separately.

Continue to the complete draft before requesting selection or approval. Do not ask preliminary selection questions.

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

## 4. Combine selection and exact-draft approval

Default to all actionable candidates, `submit`, and `COMMENT`, unless the user already specifies other choices. Resolve the target before asking for approval.

Add a short summary covering only the selected points. When the user can select a subset, show one numbered summary bullet per candidate. State that the final summary contains only the selected bullets, in draft order, with any required attribution unchanged. Do not rewrite the approved summary after selection.

For `keep pending`, include the summary only when the chosen operation can store an unsubmitted review body. Otherwise show it as deferred until submission.

Show the exact final draft with:

- repository, PR, and head SHA;
- finalization mode: `submit` or `keep pending`;
- review action for `submit`;
- target: existing pending review ID, new submitted review, or new pending review;
- numbered inline candidates with every path, line, side, and complete body;
- the complete review summary or its deferred status;
- an explicit statement of whether the result will be submitted.

If the user can choose either finalization mode, show the exact target and summary behavior for each mode. Show the review action for `submit` and state that `keep pending` does not submit the review. If only one mode is available, show that mode and explain the limitation.

Ask once: `Approve all, or specify comment numbers, and choose submit or keep pending. Your selection and mode approve the displayed draft for those choices. You can also request edits or choose none.`

- Treat `all, submit`, `1,3 keep pending`, or equivalent clear selection and mode as approval. Revalidate and write without another confirmation.
- Treat `yes`, `approved`, `post it`, or `add them` as approval of the displayed defaults.
- Apply subset selections and finalization choices directly when the displayed draft covers them. These choices do not require another approval.
- For `none`, do not write a review unless the user explicitly approves a displayed summary-only review.
- If the response requests edits or introduces an undisplayed action, target, mode, or summary, show the revised exact draft for approval.
- If revalidation changes the head, anchor, target, or content, show the revised exact draft for approval.

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
Ready to apply this review with your selection and approval:

Repo: `owner/repo`
PR: `#123`
Head commit: `abc123...`
Defaults: all comments, `submit`, `COMMENT`
Submit target: new submitted review by `login`
Keep pending target: new pending review by `login`

Inline comments:
1. `[P1] src/example.py:42` RIGHT
   Body: This fails when `limit` is missing. Please handle the default first.

Review summary (include only bullets for selected comments, in this order):
1. Please handle the missing `limit` case before this call.

`submit` submits the review with action `COMMENT` and the displayed summary.
`keep pending` leaves the review unsubmitted with the displayed summary.

Approve all, or specify comment numbers, and choose submit or keep pending.
Your selection and mode approve the displayed draft for those choices.
You can also request edits or choose none.
```
