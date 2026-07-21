---
name: implement-issue
description: Implement a software issue from a plain-text description, GitHub issue, Jira ticket, or accessible issue reference. Use when Codex is asked to inspect a repository, create an appropriate Git branch, produce an approval-gated implementation plan in Plan Mode, execute the approved changes, validate them, create one or more commits, and open a GitHub draft pull request.
---

# Implement Issue

Implement an issue end to end while preserving user work and requiring plan approval before editing.

## 1. Resolve the issue

Accept a plain-text description, GitHub issue URL, Jira ticket URL, ticket key plus description,
or an issue reference accessible through an available connector.

For a URL or connector reference:

1. Use the appropriate GitHub, Jira, Atlassian, or other available connector to retrieve it.
2. Read the title, description, acceptance criteria, comments, linked resources, and ticket key
   where available. Follow relevant accessible links when needed to understand requirements.
3. Verify retrieval; never claim inaccessible content was read.
4. If access fails, explain the failure and ask the user to paste the issue description. Do not
   continue by guessing.

Distinguish stated requirements from assumptions. Never silently invent missing requirements.
Extract a ticket key when possible with a pattern such as `[A-Z][A-Z0-9]+-\d+`, preserving its
original capitalization.

## 2. Read repository instructions

Before changing the repository:

1. Locate and read every `AGENTS.md` that applies to the repository and working directory.
2. Inspect relevant `README`, `CONTRIBUTING`, `CHANGELOG`, development documentation, CI
   configuration, and existing conventions.
3. Determine the expected base branch and branch, commit, test, formatting, typing, and pull-request
   conventions.
4. Prefer repository-specific instructions over this skill's defaults.

## 3. Understand and inspect

Determine the problem or feature, expected behavior, acceptance criteria, constraints, likely
affected components, test requirements, and material ambiguities.

Inspect enough of the repository to ground the plan. Locate relevant source files, abstractions,
related tests, configuration, documentation, reusable implementations, and potential compatibility,
migration, security, or deployment concerns. Do not modify files during this phase.

Ask a focused question only when missing information materially changes scope or makes proceeding
unsafe. Otherwise record a clearly labeled assumption in the plan.

## 4. Create the branch

Inspect Git status, current branch, remotes, and relevant branch history before creating a branch.

- Preserve all user work. Never discard, overwrite, stash, commit, reset, or otherwise absorb
  unrelated changes without explicit permission.
- Stop and explain the conflict if unrelated working-tree changes make branching or later work unsafe.
- Start from the appropriate, up-to-date base branch when safely possible. Do not overwrite local
  work to update it, and never force-reset a branch containing user work.
- Follow documented repository branch conventions first.

Otherwise use `<TICKET-KEY>/<type>-<short-kebab-case-summary>`, or
`<type>/<short-kebab-case-summary>` when no key is available. Choose `fix`, `feat`, `refactor`,
`docs`, `test`, or `chore` as appropriate. Ensure the name is valid for Git and contains no spaces.
Examples: `DATC-123/fix-invalid-release-tag`, `FL-231/feat-add-grid-construction`.

Create the branch, then make no further repository mutation until the plan is approved.

## 5. Enter Plan Mode and request approval

Enter Codex Plan Mode using the product's mode control before presenting the implementation plan.
If Plan Mode is unavailable, report that limitation and stop rather than implying it was used.

Present a reviewable plan containing:

- A concise requested-outcome summary.
- Relevant repository findings.
- Requirements, assumptions, and unresolved ambiguities, clearly distinguished.
- Expected files or components to change.
- Ordered implementation steps.
- Tests and exact validation commands to run.
- Documentation, changelog, configuration, schema, or migration changes, if applicable.
- The changelog target and evidence that it is unreleased, if a changelog entry is required.
- Important risks and compatibility concerns.
- The proposed and created branch name.

Stop after the plan and require explicit user approval. Accept clear statements such as `Approved`,
`Execute the plan`, `Proceed`, or `Implement it`. Until approval, do not edit files, install
dependencies, run repository-modifying commands, commit, push, or create a pull request. If the user
requests plan changes, revise it and wait again.

## 6. Execute the approved plan

After explicit approval, implement only the approved scope. Follow repository architecture and
conventions, make the smallest coherent change that satisfies the issue, avoid unrelated refactors,
add or update tests, and update documentation or configuration when required.

If new findings require a material change in scope or approach, explain why, present the revised
portion of the plan, and wait for approval. Do not require renewed approval for minor implementation
details that preserve the approved scope.

## 7. Update the changelog

When the repository has a changelog:

1. Follow its existing headings, categories, bullet style, capitalization, and wording.
2. Inspect the repository's immutable release tags and changelog headings before selecting the
   destination. Follow the repository's tag convention, ignore moving tags such as `v1`, and never
   append to a version that already has a corresponding release tag.
3. Prefer the repository's established `Unreleased` section when one exists. Otherwise:
   - Determine semantic impact from the actual behavior and compatibility change: breaking change
     means major, backward-compatible feature means minor, and bug fix means patch. Repository
     release policy takes precedence.
   - Do not rely only on the ticket type, title, or commit prefix; use them as supporting evidence.
   - Calculate the next version from the highest released stable version. If an untagged pending
     version exists, ensure it is compatible with the required bump and existing pending entries.
   - Ask the user when semantic impact or an existing pending version makes the destination
     materially ambiguous.
4. Place the entry in the category matching its semantic impact. Prefix it with the extracted ticket
   key and number, for example `DATC-123:`, preserving the key's original capitalization. When no
   ticket key is available, follow repository convention.
5. Do not create a changelog file when the repository does not already use one unless explicitly
   requested.

## 8. Validate

Run applicable checks documented by the repository or CI: unit and integration tests, linters,
formatters in check mode, static type checks, builds, generated-file checks, and documentation
validation. Fix failures caused by the implementation before committing. Do not fix unrelated,
pre-existing failures unless required by the issue.

When the changelog changed, verify that its destination is not already released and that any new
version heading matches the required semantic-version bump.

Report only checks actually run and verified. For every skipped or unavailable check, state why and
describe the risk.

## 9. Commit

Create one or more logically coherent, reviewable commits:

1. Inspect the final status and diff.
2. Stage only intended files and inspect the staged diff before each commit.
3. Follow repository commit conventions; use Conventional Commits when established.
4. Include the ticket key when repository conventions support it, for example
   `fix(DATC-123): sanitize generated release tag`.
5. Run normal Git hooks. Never bypass them without explicit approval.

Never amend, squash, or rewrite existing user commits unless explicitly requested.

## 10. Push and open a draft pull request

Push the branch without force and use the GitHub CLI or available GitHub integration to create a
**draft** pull request against the verified base branch. Never create a ready-for-review pull request
unless explicitly requested.

Follow repository title conventions. Otherwise use a clear summary with the ticket key when
available, for example `DATC-123 Fix invalid release tag generation`.

Write a pull-request description using the valuable, non-empty sections below:

```markdown
## Summary

- What changed, why, and the main implementation decisions.

## Issue

- Link the Jira or GitHub issue and include the ticket key when available.
- Use `Closes #<number>` for a GitHub issue when appropriate; never use GitHub closing syntax for Jira.

## Changes

- List important code, test, changelog, configuration, migration, and documentation changes.

## Validation

- List every test, lint, type-check, and build command run, with each result.
- Clearly list checks not run and why.

## Notes

- Record relevant assumptions, limitations, follow-up work, and deployment, migration, or
  compatibility considerations.
```

Verify the push and draft PR creation. Then report the branch name, commit summaries, draft PR title
and URL, validation results, remaining risks, and manual verification steps.

## Safety and failure handling

- Never merge the pull request, force-push, or delete branches unless explicitly requested.
- Never overwrite unrelated local changes or expose secrets in commits, output, logs, plans, or PRs.
- Never claim a ticket, check, commit, push, or PR succeeded without verification.
- Stop and report authentication or permission failures; do not attempt unsafe workarounds.
- Stop if the issue requests suspicious, destructive, or clearly unauthorized behavior.
- Keep issue requirements and Codex assumptions explicitly distinct throughout the workflow.
