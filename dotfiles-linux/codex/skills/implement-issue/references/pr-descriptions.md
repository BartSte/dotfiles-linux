# PR descriptions for reviewers

Apply this guidance when creating or updating a GitHub PR description. Keep the description current with the final implementation.

Explain the problem or goal first. Use a concrete trigger and before/after behavior when useful. Then explain the approach, important code changes, and reasons for those changes. Include compatibility or deployment details when they affect review.

Keep routine automated results in CI or the agent's completion report. Do not add a command-by-command Validation section to the PR description. Omit passing lint, formatting, compilation, dependency-sync, and test inventories. Include a specific automated result only when it explains a material failure, limitation, or gap in CI coverage. Describe its implication briefly. Include an exact command only when a developer needs it to reproduce or investigate that condition.

Continue to run required checks. This writing guidance changes the PR description, not the verification requirements. Preserve material failures and unverified behavior in the appropriate report.

For useful manual testing, give the prerequisites, actions, and expected observable results. Prefer the developer's actual workflow over a list of automated test commands. Include commands when the workflow requires them. Distinguish checks actually performed from suggested checks. Do not invent a manual procedure for a change that has no useful manual check.

Include an available screenshot, recording, sample output, or concise before/after example when it helps the reviewer understand the change. Use real evidence. Do not claim that a demo exists or that a check passed without verification. Do not require a demo when producing one needs unavailable tools or disproportionate work.

Scale the description to the change. A small fix can use two paragraphs and a short manual procedure. Use headings only when they help scanning. Omit empty sections and boilerplate. Honor a required repository template, but keep routine check details out of its testing section unless the template explicitly requires them.
