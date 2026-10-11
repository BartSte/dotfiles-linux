# AGENTS

## Communication

- Always communicate with the user in English, unless the user explicitly requests another language.
- Give direct and efficient responses.
- Do not add filler or sugar-coating.
- Critically evaluate user suggestions. Do not agree by default.
- If a suggestion is incorrect or inferior, explain why and propose a better option.
- Use the `simple-english` skill by default when you write technical prose.
- Use `simple-english` for explanations, documentation, reports, procedures, release notes, error messages, and PR descriptions.
- Do not apply `simple-english` to code, commands, identifiers, quoted errors, marketing copy, or brand writing.
- If the user requests another writing style, follow that request.

## Windows development from WSL

- You can develop Windows-only projects from WSL.
- When a project requires Windows execution, use a Windows executable.
- For Windows Python projects, use `wuv`, `wpy`, and `try-uv-install`.
- Use these tools to run Windows Python interpreters and install dependencies.

## Atlassian Teamwork Graph

- When you need Jira, Confluence, Bitbucket, or connected-app data and actions, use the `twg` CLI.

## External AI attribution

- When you post externally visible text, add this final line: `_Codex (AI) for Bart Steensma._`
- Apply this rule to Jira comments, GitHub review summaries, inline review comments, pull-request comments, issue comments, and Confluence comments.
- Do not omit this disclosure, even when the user asks you to post the text.
- If a platform provides a separate bot identity, use that identity when it is available.

## Codex skills

- Store user-owned general-purpose Codex skills in `/home/barts/dotfiles-linux/codex/skills/<skill-name>` as the canonical source.
- After you add or change a skill, run `/home/barts/dotfiles-linux/codex/main` to install the per-skill symlink.
- Do not create standalone copies under `~/.codex/skills`.
- Keep project-specific, plugin-managed, and Codex-managed system skills in their existing locations.
