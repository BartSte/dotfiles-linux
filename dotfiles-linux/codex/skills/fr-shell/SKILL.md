---
name: fr-shell
description: Apply Fleet Robotics conventions to POSIX sh, Bash, Zsh, and Fish code. Use this skill for writing, editing, refactoring, reviewing, or testing shell scripts, command-line tools, shell integrations, and shell test helpers.
---

# Shell Code

## Design

Prefer **single-responsibility, modular, self-explanatory code**.

- Give each function one clear responsibility.
- Keep functions and source files small enough to understand quickly.
- Use descriptive names so developers can understand intent without reading all implementation details.
- Use the file structure to clarify the repository design.
- If an extracted unit has a clear name and responsibility, split the code.

## Shell Safety

- Read the shebang and supported-platform documentation before you change a script.
- Keep POSIX `sh`, Bash, Zsh, and Fish syntax separate.
- Quote variable expansions in POSIX-like shells.
- If arguments can contain spaces, use lists in Fish and arrays in Bash or Zsh.
- Pass command arguments as lists or arrays. Do not build a command string.
- Do not use `eval` for external input or command buffers.
- Use `printf` for predictable output.
- Handle expected nonzero statuses explicitly.

## Validation

- Run the syntax checker for the declared shell.
- If ShellCheck is available, run it for POSIX `sh` and Bash code.
- Run the project test suite.
- Test normal input, invalid input, empty input, and paths or arguments that contain spaces.
