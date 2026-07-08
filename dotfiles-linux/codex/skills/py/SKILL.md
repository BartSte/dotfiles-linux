---
name: py
description: Apply Python coding conventions for this user's projects. Use when Codex writes, edits, reviews, or explains Python code, Python tests, Python package configuration, or Python docstrings, especially when style guidance is needed.
---

# Python

Follow the Google Python Style Guide when writing or modifying Python code.

Use Google-style docstrings for modules, classes, functions, methods, and fixtures when docstrings are appropriate.

Keep project-local tooling authoritative. If a repository has stricter or conflicting rules in `AGENTS.md`, formatter configuration, lint configuration, tests, or existing code patterns, follow the project-local rule and preserve consistency.

Prefer **single-responsibility, modular, self-explanatory Python code**.

- Functions, methods, and classes should each do one clear thing.
- Keep functions, classes, and source files small enough to understand quickly.
- Use descriptive names so developers can understand intent without reading all implementation details.
- Use module/package structure to clarify the repository design.
- Split code only when the extracted unit has a clear name and responsibility.

Avoid using the typehint `Any` unless it is unavoidable. Use more specific types whenever possible.
