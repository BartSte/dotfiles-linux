---
name: commit
description: Create one or more focused commits from all staged changes, or write and review Conventional Commit messages. Use when Codex creates commits, suggests or edits commit text, summarizes staged changes for commits, splits staged work into logical commits, or reviews commit-message quality.
---

# Commit Messages

- Prefix commit subjects using Conventional Commits: `<type>[optional scope]: <description>`.
- Use common types such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`, `style`, and `perf`.
- Add a scope when it clarifies the affected area, for example `docs(codex): add commit guidance`.
- Write the description in imperative mood.
- Use lowercase after the prefix unless a proper noun requires capitalization.
- Omit the trailing period.
- Keep the subject concise.
- Each commit must represent one independently understandable, reversible logical change.

If more context is needed, add a blank line after the subject and explain the why in the body.

# Creating Commits

When asked to create a commit:

- Treat the complete staged diff at the start of the task as the commit set.
- Inspect `git status --short` and the full staged diff before committing anything.
- Decide explicitly whether the commit set contains one logical change or several. Split it into multiple commits when changes have independent purposes, different Conventional Commit types or scopes, or could reasonably be reverted separately.
- Keep implementation, its tests, and directly supporting documentation together when they form one logical change. Do not split merely because several files changed.
- Commit every change from the initial commit set. Do not stop after the first commit when more of that set remains.
- Never include content that was unstaged or untracked at the start of the task.
- When splitting, temporarily unstage and restage only content from the initial staged diff. Account for partially staged files and use patches derived from the initial staged diff when needed; never use a broad `git add` that could capture pre-existing unstaged content.
- Determine a separate Conventional Commit message for each logical change.
- Create the commit or commits with the `git` executable.
- Afterward, verify that no changes from the initial commit set remain staged and that pre-existing unstaged and untracked changes were not committed.
- Do not push the commit.
