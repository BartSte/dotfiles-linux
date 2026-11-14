---
name: simple-english
description: "Use for technical writing with ASD-STE100 rules."
version: 1.2.0
author: AminBlg
license: MIT
metadata:
  writing:
    tags: [writing, documentation, simplified-technical-english, ASD-STE100]
    related_skills: []
  standard: ASD-STE100 Issue 9 (2025-01-15)
---

# Simple English: Write Like an Aerospace Manual

Write technical text with the rules of ASD-STE100 Simplified Technical English. STE is controlled language for technical documentation. It helps tired readers and non-native English speakers understand instructions on one read.

## Task

When asked to write or rewrite technical text:

1. Select pragmatic or strict mode.
2. Classify each passage as procedural or descriptive.
3. Choose vocabulary before drafting. In strict mode, use `make sure that` for the check/verify/confirm/ensure concept. In pragmatic mode, choose one term and keep it consistent. Choose one noun for config/settings/options and use it throughout.
4. Apply the rules below.
5. Run the self-check before delivery.
6. Never change code, identifiers, commands, or quoted errors.

When asked to check text, report each violation as: rule number, offending text, and compliant rewrite. Cite only rule numbers in this file.

## Modes

- **Pragmatic (default):** Apply structural rules. Keep necessary domain words such as `idempotent` and `webhook`.
- **Strict:** Apply structural and vocabulary rules. Tell the user that full compliance requires the official dictionary at `asd-ste100.org`.

## Classify the Text

| | Procedural | Descriptive |
|---|---|---|
| Purpose | Tell the reader what to do | Explain what a thing is or does |
| Verb form | Imperative: “Install the pump.” | Simple present, past, or future |
| Sentence limit | **20 words** (Rule 5.1) | **25 words** (Rule 6.3) |
| Structure | One instruction per sentence (5.2) | One topic per paragraph, maximum six sentences (6.5–6.6) |

Do not mix the modes in one passage. A “Getting started” section is procedural. An “Architecture” section is descriptive. A note inside a procedure is descriptive.

## Rule Catalog

### Words (Rules 1.1–1.14)

- Use approved words, technical nouns, or technical verbs.
- Use approved words only with their listed part of speech and meaning.
- Use only approved verb and adjective forms.
- Domain words can be technical nouns or verbs when appropriate.
- Do not use technical nouns as verbs or technical verbs as nouns.
- Use project and industry terms.
- Pick short, clear terms.
- Do not use regional, slang, or unnecessary jargon.
- Give one item one name (Rule 1.11).
- Use American English spelling.

Pragmatic mode permits necessary domain vocabulary. Common failures are technical nouns used as verbs, synonym rotation, and technical verbs used as nouns.

**Before:** You can webhook the event, then do a deploy.
**After:** Send the event to the webhook. Then deploy the service.

### Multi-word nouns (Rules 2.1–2.2)

- Write multi-word nouns with three words or fewer.
- If a noun needs more words, write it in full once, then use a short form or hyphenate the units.
- Break long noun chains with prepositions.

**Before:** the connection pool timeout configuration value
**After:** the timeout value for the connection pool

### Verbs (Rules 3.1–3.7)

- Use only dictionary-approved verb forms.
- Use infinitive, imperative, simple present, simple past, simple future, and past participle as an adjective.
- Do not use complex auxiliary constructions, present perfect, or “is to be installed”.
- Use an `-ing` form only as a technical noun or in a noun phrase.
- Use active voice. In descriptive text, use passive voice only when the agent is unknown.
- Describe actions with verbs, not nouns.

**Approved modals:** `can`, `will`, `must`. **Avoid:** `should`, `would`, `may`, `might`, `could`.

Use `can` for possibility or permission. Use `must` for requirements. Delete recommendations stated with `should`, or state the fact directly. Restructure hypotheticals with an `if` condition.

### Sentences (Rules 4.1–4.5)

- Write short, clear sentences.
- Keep complete grammar, articles, and the conjunction `that`. Do not use contractions.
- Use vertical lists for complex text.
- Use connecting words between related sentences.
- Put an article or demonstrative adjective before nouns where applicable.

**Wrong:** Ensure file exists before running.
**STE:** Make sure that the file exists before you run the command.

### Procedural writing (Rules 5.1–5.5)

- Limit each sentence to 20 words, including warnings and cautions.
- Use one instruction per sentence unless two actions happen at the same time.
- Use the imperative.
- Put a required condition before the command: “If the build fails, read the log.”
- Notes give information, not instructions, and use the 25-word descriptive limit.

### Descriptive writing (Rules 6.1–6.6)

- Give information gradually, with one new fact per sentence.
- Use key words and phrases for logical structure.
- Limit each sentence to 25 words.
- Group related information in paragraphs.
- Use one topic per paragraph.
- Limit paragraphs to six sentences.

Do not use imperatives in descriptive text.

### Safety instructions (Rules 7.1–7.3)

- Use `WARNING` for injury risk and `CAUTION` for damage risk.
- Start with a clear command or condition.
- State the risk or result after the command.

**Before:** Note that data loss may occur in some circumstances if the destructive flag happens to be enabled when running against production.
**After:** CAUTION: Do not use the `--force` flag against production. The flag deletes rows that do not match the source.

### Punctuation and word count (Rules 8.1–8.7)

- Standard punctuation is legal except the semicolon. Write two sentences instead.
- Use hyphens for words that act as one unit.
- Parentheses are legal for references, abbreviations, explanations, and alternatives.
- In a vertical list, the lead-in colon ends a sentence for word count.
- Text inside parentheses counts as one word.
- Numbers, units, abbreviations, identifiers, quoted text, titles, labels, and proper nouns count as one word each.
- Hyphenated words count as one word.

### Writing practices (Rules 9.1–9.4, GR-1 to GR-8)

- Restructure a sentence when a word-for-word replacement does not work.
- Use each word with its approved meaning and part of speech.
- Avoid phrasal verbs: use “decrease” instead of “go down”, and “install” or “configure” instead of “set up”.
- Keep style and terminology consistent.
- Keep `that`, give pronouns clear referents, prefer `this + noun`, avoid false friends and Latin abbreviations, use inclusive language, and avoid possessive apostrophes when unsure.
- Write “for example” instead of “e.g.”, “that is” instead of “i.e.”, and name items instead of writing “etc.”.

## Vocabulary Discipline

The official dictionary is not reproduced here. Apply its core principle: **one word, one meaning, one part of speech.**

| Word | Ruling |
|---|---|
| `test`, `check`, `work` | Nouns only. Use “do a test”. Replace “check that X” with “make sure that X”. |
| `oil` | Technical noun only. Use “lubricate” as the verb. |
| `help` | Verb only. Use “aid” for the noun. |
| `fall` | Use “decrease” for a reduction in value. Use `fall` only for physical downward movement. |
| `follow` | Means “to come after”, not “obey”. Write “obey the instructions”. |
| `above`, `below` | Use for physical positions only. For limits, write “more than” or “less than”. |

### Modal ladder

| You wrote | STE writes |
|---|---|
| should (requirement) | must |
| should (recommendation) | Delete it or state the fact. |
| may / might / could (possibility) | can |
| may (permission) | can |
| would (hypothetical) | Restructure with an `if` condition. |

### Slop-to-simple substitutions

Delete words that add no fact.

| Slop | Write instead |
|---|---|
| leverage, utilize | use |
| in order to | to |
| prior to | before |
| ensure | make sure that |
| it is worth noting that | delete |
| simply, just, easily, seamlessly, effortlessly | delete |
| robust, powerful, comprehensive, performant | delete or state the measurable property |
| functionality | function, feature |
| enables you to, allows you to | you can |
| facilitate | help, make possible |
| dive into, delve into | read, examine |
| when it comes to | for |
| in the event that | if |
| due to the fact that | because |
| as needed, as necessary | state the condition |
| and/or | Pick one, or write “X, or Y, or both”. |
| e.g. / i.e. / etc. | for example / that is / name the items |
| gracefully handles | State what it does, such as “retries three times, then stops”. |
| out of the box | by default |
| under the hood | internally |
| blazingly fast, state-of-the-art | state a number or delete |
| streamline | make simpler, make faster |
| plethora, myriad | many |
| addresses the issue, tackles | corrects the fault, removes the error |

### Consistency pass

Pick one term for each technical noun and use it consistently. For example, choose one of `config`, `configuration`, `settings`, or `options`.

In strict mode, use `make sure that` for check, verify, confirm, and ensure. In pragmatic mode, choose one term and use it consistently.

## Untouchables

Leave these exact, even when they break vocabulary rules:

- Code blocks, inline code, identifiers, CLI commands, flags, and file paths
- Quoted error messages and log lines
- Product names, API endpoint names, and config keys
- Numbers with units

## Beyond Documentation

Apply the same rules to error messages, runbooks, incident reports, release notes, agent instructions, and translation preparation. State facts clearly, use imperatives for fixes, put conditions first, and keep one meaning per word.

## Self-Check

Before delivery:

1. Count words in the three longest sentences. Split sentences over the 20-word procedural or 25-word descriptive limit.
2. Search for contractions, `has been`, `have been`, `should`, `-ing` verbs after a comma, and semicolons.
3. Search for every `if` and `when`. Put each condition at the start of its sentence, before the command.
4. Search for inconsistent variants of the chosen check verb and config noun.
5. Confirm that code, identifiers, commands, and quoted errors remain unchanged.

Fix every violation before delivery. When checking text, cite the rule number, offending text, and compliant rewrite.

## Limits and Disclaimer

STE is for technical facts and instructions. Do not apply it to marketing copy, blog voice, or brand writing. When asked for STE on marketing text, say so and offer it for the docs instead.

This skill is an unofficial aid. It is not affiliated with or endorsed by ASD or STEMG, and no tool can guarantee STE compliance. ASD-STE100 is a registered trademark of ASD. The official standard is a free download at `asd-ste100.org`.

## References

- `references/checklist.md` — full verification pass with searchable patterns.
- `references/use-cases.md` — adaptations for error messages, runbooks, incident reports, commits, UI copy, and internationalization.
