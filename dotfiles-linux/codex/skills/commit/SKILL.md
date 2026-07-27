---
name: commit
description: Write and review commit messages using Conventional Commits. Use when Codex creates a commit, suggests a commit message, edits commit text, summarizes staged changes for a commit, or reviews commit-message quality.
---

# Commit Messages

- Prefix commit subjects using Conventional Commits: `<type>[optional scope]: <description>`.
- Use common types such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`, `style`, and `perf`.
- Add a scope when it clarifies the affected area, for example `docs(codex): add commit guidance`.
- Write the description in imperative mood.
- Use lowercase after the prefix unless a proper noun requires capitalization.
- Omit the trailing period.
- Keep the subject concise.
- Each commit should represent a single logical change. If necessary, break up large changes into multiple commits, each with its own subject and body.

If more context is needed, add a blank line after the subject and explain the why in the body.

# Creating Commits

When asked to create a commit:

- Inspect the staged changes.
- Commit only the changes that are already staged; do not stage additional files.
- Determine the commit message from the staged changes using the rules above.
- Create the commit with the `git` executable.
- Do not push the commit.
