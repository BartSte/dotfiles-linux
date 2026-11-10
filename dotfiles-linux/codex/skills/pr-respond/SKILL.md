---
name: pr-respond
description: Assess pull-request feedback, propose changes and replies, then use separate approvals for local changes and commits, and for pushes and posted responses.
---

# Respond to Pull-Request Review Comments

Use this skill to handle reviewer feedback on a pull request. Propose changes and replies before implementation. After the first approval, apply and commit the changes locally. Present the complete response again for final approval before you push commits or post replies.

## Gather and assess

1. Resolve the pull request from a supplied URL or `owner/repo#number`. Infer it from the current branch only when the match is unambiguous. Otherwise, ask for the pull request.
2. Get all reviewer feedback that is available on the pull request. Include inline review comments, review summaries, and reviewer-authored pull-request comments. Identify the author, location, and review state for each item.
3. Read the current pull-request diff and relevant file context. Check whether a comment is stale, already addressed, duplicated, or based on an incorrect assumption.
4. For each actionable comment, choose one outcome:
   - **Change:** The request is correct. Propose the smallest code or test change that addresses it.
   - **Clarify:** A change is not justified, but a factual response can explain the current behavior or ask a focused question.
   - **No action:** The comment is already addressed, duplicate, stale, or needs no reply. State the evidence.

Do not accept a requested change only because a reviewer requested it. Explain a rejected request clearly and respectfully.

## Show the proposal

Give every comment a number. For each one, show:

- the reviewer, location, and complete comment;
- the assessment and evidence;
- the proposed outcome;
- for **Change**, the affected files, a precise description of the code and test changes, and the proposed reply;
- for **Clarify**, the exact proposed reply;
- for **No action**, the reason no action or reply is proposed.

Separate comments that could not be retrieved or assessed. Do not guess their content or intent.

Use clear, concise, respectful language for proposed replies. Preserve code identifiers, paths, and quoted reviewer text exactly.

## First approval: changes and proposed replies

Before any mutation, ask the user to approve the numbered proposal. The user can approve all items or a specified set. Explain that this approval authorizes local changes, checks, and one or more local commits for the selected items.

Do not edit source code, tests, documentation, or configuration before this approval. Approval of proposed replies at this stage does not authorize publication.

Do not push commits, post replies, or change remote PR content until the separate final approval.

An approval applies only to the selected items. If the proposed implementation changes materially, show the revised proposal and get approval before implementation.

## Implement and commit locally

1. Re-fetch the pull-request head and selected comments. Stop and rebuild the proposal if the head, comment state, or relevant code changed.
2. Apply only the approved local changes. Run relevant checks and tests.
3. Use the `commit` skill to create one or more focused local commits for the review response. Include only changes that belong to approved items. Do not include unrelated staged or unstaged changes. This workflow authorizes staging the approved changes and committing them without another approval.
4. If the proposal includes a PR description change, prepare its exact text without updating the remote PR. Use the
   [PR description guidance](../implement-issue/references/pr-descriptions.md).

## Final approval: push and publish

Present the complete review response again after implementation, even if the user approved the exact proposed replies at the first stage. Include:

- every selected comment number, its outcome, and the exact final reply;
- the final diff and the commit hashes and subjects;
- relevant check and test results, including failures and checks not run;
- the destination repository and branch for the push;
- the exact text of any proposed PR description change;
- skipped items and any proposed thread actions.

Ask for a separate final approval to push these commits and publish these responses. Keep all commits local and all responses unpublished until that approval arrives. If the final package changes materially, present the revised package for approval again.

## Push and publish approved responses

1. Re-fetch the remote PR head and selected comments. If the remote head, comment state, or relevant code changed, stop and rebuild the final proposal.
2. Push only the approved commits to the approved PR branch. Do not force-push without explicit approval. If the push fails, stop before posting replies that claim the changes are available on the PR.
3. Publish only the approved replies and PR description changes. Do not resolve or dismiss threads unless the user explicitly approved those actions.
4. Report the pushed commits, check and test results, posted replies, skipped items, and any failure. If publication partially fails, report what succeeded and what remains. Do not duplicate successful replies during a retry.
