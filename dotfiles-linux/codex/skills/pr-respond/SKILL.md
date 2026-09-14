---
name: pr-respond
description: Gather pull-request reviewer comments, assess each one, and draft proposed code changes and replies for approval before any change or reply.
---

# Respond to Pull-Request Review Comments

Use this skill to handle reviewer feedback on a pull request. Gather the feedback, assess it against the current pull request, and propose a response. Do not edit code or post review replies until the user approves the exact proposed actions.

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

## Approval gate

Before any mutation, ask the user to approve the numbered proposal. The user can approve all items or a specified set.

Do not do any of these actions before approval:

- edit source code, tests, documentation, or configuration;
- post, resolve, or dismiss a pull-request comment or review thread;
- change the pull request in any other way.

An approval applies only to the listed actions and exact reply text. If the proposed code change or reply changes materially, show the revised proposal and get approval again.

## Apply approved actions

1. Re-fetch the pull-request head and selected comments. Stop and rebuild the proposal if the head, comment state, or relevant code changed.
2. Apply only the approved code changes. Run relevant checks and tests.
3. Show the final diff and test results before posting replies, unless the user explicitly approved both the code changes and the exact replies in one approval.
4. Post only the approved replies. Do not resolve or dismiss threads unless the user explicitly approved that action.
5. Report the applied changes, test results, posted replies, skipped items, and any failure.
