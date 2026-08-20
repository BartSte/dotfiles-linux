---
name: github-inline-review-gate
description: Prepare and submit inline GitHub pull request review comments with a mandatory manual approval gate. Use when Codex is asked to add review findings, reviewer-model comments, or manually supplied code-review comments to a GitHub PR at the correct diff lines, especially when the user wants to inspect the exact comments before posting or wants comments submitted as one actual PR review.
---

# GitHub Inline Review Gate

## Overview

Use this skill to turn review findings into inline GitHub PR review comments. Always draft first, ask for explicit user approval, then submit one real review only if there is no existing pending review by the authenticated user.

Prefer the GitHub plugin connector for PR metadata, patches, files, reviews, and review submission. Use `gh` only for gaps the connector cannot handle, and run networked `gh` commands with escalation when required by the environment.

## Required Behavior

- Do not post any GitHub comment before the user manually approves the exact draft.
- Submit approved comments as one actual PR review with inline comments, not as standalone PR review comments.
- Abort if the authenticated user already has a pending review on the PR. Tell the user that a pending review exists and do not add comments to it unless they explicitly give a new instruction for that case.
- Anchor comments to changed lines in the PR diff. If a requested line is not in the diff, report it in the draft as unpostable and ask how to handle it.
- Keep the original review finding meaning intact. Lightly edit only for clarity, directness, or line-specific context.
- Include severity labels only if the user supplied them or asks for them.

## Workflow

1. Resolve the PR target.
   - Extract `owner/repo` and PR number from the URL or user request.
   - Fetch PR metadata, including head SHA.
   - Confirm the PR is open unless the user explicitly asks to comment on a closed PR.

2. Inspect the diff anchors.
   - Fetch file patches for every file mentioned in the findings.
   - Confirm each target line is present on the right side of the PR diff.
   - If needed, fetch the head file around target lines to understand the exact code being commented on.

3. Check pending review state before drafting final submission.
   - Fetch PR reviews.
   - Determine the authenticated GitHub user when needed.
   - If there is a `PENDING` review by that user, stop immediately and report that submitting a new review would fail or merge with pending state. Do not post comments.

4. Build a manual-check draft.
   - Show the user the exact review action, repository, PR number, commit SHA, and each inline comment.
   - For every comment include file path, line, side, and body.
   - Mark any comment that cannot be anchored as `UNPOSTABLE` with the reason.
   - Ask for explicit approval before posting. A suitable prompt is: `Approve posting this review as shown?`

5. Submit only after approval.
   - Re-fetch PR metadata and reviews if meaningful time has passed or the user returned later.
   - Abort if the head SHA changed, unless the user approves posting against the new head after seeing an updated draft.
   - Abort if a pending review by the authenticated user now exists.
   - Use the connector `add_review_to_pr` with `action: COMMENT`, the PR head commit SHA, and all inline comments in `file_comments`.
   - Do not fall back to `gh api repos/:owner/:repo/pulls/:pull_number/comments` for standalone comments unless the user explicitly changes the requirement.

6. Report the result.
   - Summarize which comments were posted and where.
   - If aborted, state the exact abort reason and whether anything was posted. Normally, nothing should be posted before the abort.

## Draft Format

Use this structure for the manual approval gate:

```markdown
Ready to post this as one GitHub PR review:

Repo: `owner/repo`
PR: `#123`
Head commit: `abc123...`
Review action: `COMMENT`

Inline comments:
1. `path/to/file.py:42` RIGHT
   Body: ...

2. `path/to/other.py:88` RIGHT
   Body: ...

Approve posting this review as shown?
```

If any comment cannot be posted:

```markdown
Unpostable comments:
- `path/to/file.py:10`: line is not present in the PR diff.
```

Do not post until the user answers with explicit approval such as `yes`, `approved`, `post it`, or equivalent.

## Connector Calls

Typical connector sequence:

1. `get_pr_info(repository_full_name, pr_number)`
2. `fetch_pr_file_patch(repo_full_name, pr_number, path)` for each file
3. `fetch_file(repository_full_name, path, ref=head_sha, start_line=..., end_line=...)` when context is needed
4. `list_pull_request_reviews(repo_full_name, pr_number)`
5. `add_review_to_pr(repo_full_name, pr_number, commit_id=head_sha, action="COMMENT", review=..., file_comments=[...])` after user approval

Use `line` plus `side: RIGHT` when anchoring to the new side of the diff. Use `position` only if line-based anchoring is unavailable and the diff position has been computed from the patch.
