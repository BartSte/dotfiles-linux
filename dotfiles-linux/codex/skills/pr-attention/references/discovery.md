# Discovery and classification

Use search to collect candidates. Use current PR metadata and relevant feedback to determine the next action.
Apply the user's host and repository scope to every source. Resolve the authenticated login; do not assume a saved identity is current.

## Candidate sources

These GitHub search queries express the intended filters. Adapt them to the available API or CLI operation.
Replace `@me` with the authenticated login when the operation requires a literal username.

| Source | Query |
| --- | --- |
| Direct review requests | `is:pr is:open -author:@me user-review-requested:@me` |
| Authored PRs | `is:pr is:open author:@me` |
| Team requests | `is:pr is:open -author:@me team-review-requested-user:@me` |
| Previously reviewed PRs | `is:pr is:open -author:@me reviewed-by:@me` |
| Assigned PRs | `is:pr is:open -author:@me assignee:@me` |

Ordinary `review-requested:@me` can include team requests. Do not use it alone to identify direct requests.
If a search qualifier is unsupported, inspect individual and team review-request fields or explicit team queries.
If team membership is unavailable, report incomplete team coverage instead of inventing team names.

Use available notifications or saved review conversations to find replies without an outstanding review request.
Notifications are discovery signals. Fetch their target conversation before labeling a response as necessary.
Previously reviewed PRs are candidates for follow-up, not automatic review obligations.

Retrieve all accessible pages within the supported search limits. Partition searches by repository or another non-overlapping scope when limits require it.
If results remain capped or a source fails, record the gap. Never describe a partial queue as all PRs.
Do not treat a failed discovery query as an empty result or remove its saved entries.

## Evidence rules

- **Author feedback:** Assess review summaries, inline threads, and reviewer-authored PR comments. Ordinary comments can need action without `CHANGES_REQUESTED`.
- **CI:** Inspect current-head check runs and commit statuses. A search status alone can miss failures or include failures unrelated to the proposed code.
- **Conflicts:** Use current mergeability evidence. An unknown result is not a confirmed conflict.
- **Merge candidates:** Approval and successful status do not prove that all merge requirements are satisfied.
- **Waiting:** Distinguish an authored PR awaiting review from one with unaddressed feedback. Keep waiting PRs in an overview unless evidence supports action.
- **Another review:** Compare the current head with the user's last submitted review and saved assessed head. New commits alone do not prove a direct request.
- **Conversation follow-up:** Compare relevant replies with the user's last response or saved assessment. A changed PR timestamp alone does not prove new feedback.
- **Assignment:** Explain the assignment signal. Do not assume that assignment means a code review is required.
- **Reminders:** Use a user-provided waiting threshold or deadline. Without one, show the waiting age and offer reminder candidates without inventing an overdue policy.

An unchanged head does not imply unchanged feedback. A new head invalidates a prior code assessment even if the title stays the same.
Exclude closed or merged PRs from new work after confirming their state. Preserve their action history.
Drafts can need author action. For other authors' drafts, retain explicit review requests and label the draft status.

## Group assignment

Assign the earliest applicable group: direct request, authored work, team request, then follow-up or reminder.
Preserve secondary reasons on the same entry. A direct request that disappears can move to follow-up if evidence still supports action.
Treat unanswered review replies as follow-up unless there is a current direct or team request.

Within each group, use explicit urgency or request deadlines, unresolved conversations, and outstanding request age.
If request age is unavailable, report it as unknown. Do not substitute unrelated PR update time as request age.
