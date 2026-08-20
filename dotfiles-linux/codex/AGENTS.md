## Communication

<<<<<<< HEAD
- Direct, efficient responses. No filler or sugar-coating.
=======
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

## Codex skills

- Store user-owned general-purpose Codex skills in `/home/barts/dotfiles-linux/codex/skills/<skill-name>` as the canonical source.
- After you add or change a skill, run `/home/barts/dotfiles-linux/codex/main` to install the per-skill symlink.
- Do not create standalone copies under `~/.codex/skills`.
- Keep project-specific, plugin-managed, and Codex-managed system skills in their existing locations.
>>>>>>> 45dbebc4455c112df54a837a5fd3b66c2ca5e24b
