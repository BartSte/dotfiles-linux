---
name: python-version-bump
description: Complete a Python package version bump by updating pyproject.toml, syncing dependencies, committing, tagging, and pushing. Use for the full version-bump workflow.
---

# Python Version Bump

Use this workflow when the user requests a complete version bump. Respect a version or scope that the user specifies.

1. Read the version in `pyproject.toml` and inspect the working tree. Select the smallest valid increase unless the user specifies a version. For a prerelease such as `1.20.0a4`, increase its sequence number to `1.20.0a5`.
2. Change the version in `pyproject.toml`. Keep unrelated edits out of the bump.
3. Run `uv sync`. Use `wuv sync` when the project requires Windows execution from WSL. Inspect the resulting lockfile diff and resolve unexpected dependency changes before committing.
4. Stage only the version change and its lockfile update. Commit with the exact subject `chore(pyproject): version bump to <version>`.
5. Inspect the repository's version tags. Tag the new commit with the exact version, adding `v` only when the repository uses that prefix. Match the repository's lightweight or annotated tag convention. Do not replace an existing tag.
6. Push the commit and tag to the branch's remote when the user authorized the full workflow. Confirm that both remote refs point to the new commit.

Keep unrelated working-tree changes out of the commit. Stop and report a conflict if the branch, target tag, or remote prevents a safe push.
