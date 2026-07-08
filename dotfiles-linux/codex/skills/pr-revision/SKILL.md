---
name: pr-revision
description: Plan and apply revisions for unresolved GitHub pull request review comments. Use when the user invokes `/pr-revision PR` or asks to review unresolved PR comments, where PR is a pull request number or URL. Requires a specific PR identifier before starting.
---

# PR Revision

Use the GitHub plugin to inspect a specific pull request, analyze unresolved review comments, propose responses and code changes, wait for explicit user approval, then execute only the approved actions.

## Required Input

Require the user request to include `/pr-revision <pr>`, where `<pr>` is one of:

- A pull request number, resolved against the current repository.
- A GitHub pull request URL.

If the PR number cannot be resolved to a repository from the local checkout, ask for the repository or full PR URL before fetching comments.

## Workflow

1. Resolve the PR.
   - Parse the PR number or URL from `/pr-revision <pr>`.
   - Use the local Git remote when only a number is provided.
   - Confirm the repository, PR number, source branch, target branch, and current local branch before analysis.

2. Fetch unresolved review context.
   - Use the GitHub plugin for PR metadata, changed files, review comments, and PR discussion context.
   - Fetch thread-aware review data, including resolution state, outdated state, file path, line/range anchors, author, and full thread text.
   - Prefer GraphQL through the available GitHub tooling when unresolved thread state matters, because flat comment lists can omit whether a thread is resolved or outdated.
   - Ignore resolved threads unless they provide necessary context for an unresolved thread.
   - Call out outdated unresolved threads separately; do not treat them as requiring code changes without checking whether the current diff already addresses them.

3. Analyze before editing.
   - Group comments by file, behavior, or review theme.
   - For each unresolved thread, determine whether it asks for:
     - a code change,
     - a test change,
     - a documentation change,
     - an explanatory response,
     - clarification from the reviewer,
     - or no action because the comment is stale, incorrect, duplicate, or already addressed.
   - Inspect the referenced code and relevant surrounding implementation before proposing a response.

4. Present an approval plan.
   - Do not edit files, push commits, post GitHub replies, or resolve threads before this step is approved.
   - Present a numbered list with one item per unresolved thread or tightly coupled thread group.
   - For each item include:
     - thread identifier or stable reference,
     - file and line/range when available,
     - reviewer concern,
     - recommended response text,
     - proposed code/test/doc change, if any,
     - why a code change is necessary or why it is not necessary,
     - risk or ambiguity, if present.
   - Ask the user which numbered items to execute. The user may approve all, a subset, responses only, code only, or ask for revisions to the plan.

5. Execute only approved actions.
   - Apply only the approved code/test/doc changes.
   - Post only approved GitHub responses.
   - Resolve review threads only when the user explicitly approved resolving them.
   - Keep changes traceable to the approved item numbers.
   - If implementation reveals that an approved action is unsafe, stale, or materially different from the plan, stop and ask for renewed approval.

6. Validate and summarize.
   - Run the most relevant local checks for the changed files when feasible.
   - Summarize:
     - approved items completed,
     - responses posted,
     - files changed,
     - checks run and results,
     - items intentionally left untouched,
     - any remaining reviewer follow-up needed.

## Output Format For The Approval Plan

Use this structure:

```md
## PR Revision Plan

1. `<file:line>` - short thread summary
   - Reviewer concern: ...
   - Suggested response: ...
   - Proposed change: ...
   - Why change is needed: ...
   - Risk/ambiguity: ...

## Approval Needed

Reply with the item numbers to execute, for example `1, 3 responses only, 4 code and response`.
```

Keep explanations concise but complete enough that the user can decide without rereading the full PR.

## Safety Rules

- Never proceed without a specific PR number or URL.
- Never modify code, post replies, resolve threads, commit, or push before the user approves the numbered plan.
- Never silently broaden approval from one thread to nearby unrelated comments.
- Never mark a thread resolved merely because code was changed; resolution is a separate GitHub write action that requires explicit approval.
- If comments conflict, explain the conflict and recommend a path instead of guessing.
- If a reviewer asks a question and the code is already correct, prefer a clear response over unnecessary code churn.
