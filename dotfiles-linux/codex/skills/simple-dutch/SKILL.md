---
name: simple-dutch
description: >-
  Write, rewrite, or review Dutch technical prose in clear, simple language,
  while retaining appropriate English technical terms such as source code.
  Use for Dutch documentation, procedures, explanations, reports, release
  notes, and error messages, or requests for eenvoudig Nederlands or
  technisch Nederlands. Adapt the structural principles of simple-english
  to Dutch grammar. Do not select this skill for English-only output.
---

# Simple Dutch

Write clear Dutch technical prose that a reader can understand in one reading.
Retain established English technical terms when they are more useful than Dutch translations.
Use Dutch grammar around those terms.

This skill adapts the writing principles of `simple-english` and is self-contained.
It does not define a Dutch version of ASD-STE100 or claim compliance with that English standard.
Do not transfer English dictionary restrictions or English verb rules to Dutch.

## Scope

Use this skill for requested Dutch output, including translations into Dutch and reviews of existing Dutch text.
Explicit invocation requests this Dutch writing style for the target text.
It does not change the language of unrelated conversation or authorize changes to files or external services.
For marketing copy, creative writing, or brand voice, follow the user's requested style instead of imposing these technical-writing rules.

## Writing workflow

1. Identify the audience and preserve the original facts, requirements, uncertainty, and risk level.
2. Classify passages as instructions or explanations.
3. Select consistent names for repeated concepts, including English technical terms.
4. Write natural Dutch with the rules below.
5. Complete the self-check before delivering the text.

For a review, report the offending text, the relevant rule heading, and a proposed correction.
Do not invent ASD-STE100 rule numbers for this adaptation.

## Instructions and explanations

| Rule | Instructions | Explanations |
|---|---|---|
| Sentence length | Maximum 20 words | Maximum 25 words |
| Verb form | Imperative: “Open de repository.” | Prefer simple present or past |
| Content | One instruction per sentence | One main fact per sentence |
| Structure | Ordered steps when order matters | One topic per paragraph, maximum six sentences |

Separate explanatory notes from steps.
Notes provide information and follow the 25-word limit.
Put prerequisites and warnings before the affected step.
Put a required condition before its command: “Als de build mislukt, lees de logs.”
This condition-first rule applies to instructions, not every use of “als” or “wanneer” in an explanation.

## English technical terms in Dutch prose

Prefer established English terms for software concepts, tools, and engineering artifacts.
In this user's technical prose, write **source code**, not **broncode**.
Keep terminology aligned with the project, its documentation, and its interface.

| Prefer in a software context | Avoid translating to |
|---|---|
| source code | broncode |
| repository | opslagplaats |
| branch | tak |
| commit | vastlegging |
| pull request | samenvoegverzoek |
| deployment | uitrol |
| build | bouwproces |
| endpoint | eindpunt |
| webhook | webhaak |

These preferences apply to the technical meanings of these words.
They do not require English for ordinary words such as “bestand”, “gebruiker”, “opslaan”, or “verwijderen”.
Do not turn complete sentences into English or replace clear everyday Dutch with English business jargon.
For an unfamiliar technical term, give a short Dutch explanation at first use when the audience needs it.
Keep the English term in later mentions.

Use one term per concept.
Do not alternate between “source code” and “broncode”, or between “repository” and “repo”, without a meaningful distinction.
Preserve distinct concepts such as authentication and authorization, or checking a value and validating its format.

Prefer a Dutch action verb around an English technical noun when that makes the sentence clearer:

- “Maak een commit.”
- “Voer de build uit.”
- “Voeg de branch samen.”
- “Start de deployment.”

Established loan verbs are acceptable when they sound natural to the audience.
Do not invent awkward verbs such as “sourcecoden” or “webhooken”.
Rephrase difficult mixed compounds: write “de logs van de deployment” rather than a long Dutch-English noun chain.
Preserve official product names and interface labels exactly, including English labels such as `Settings`.
Use normal Dutch spelling for the surrounding prose.

## Dutch grammar and meaning

- Use active voice: “De service verwerkt het request.” Name the actor when it is known.
- Use passive voice only when the actor is unknown or irrelevant and the sentence remains clear.
- Prefer simple present or past. Use perfect tense when Dutch grammar or the intended time relationship needs it.
- Describe actions with verbs: “Configureer de client”, rather than “Voer de configuratie van de client uit”.
- Retain articles and necessary connecting words. Do not write telegram-style fragments to meet the word limit.
- Use Dutch word order and normal separable verbs, such as “Sla het bestand op”.
- Give pronouns clear referents. Prefer “deze service” over an ambiguous “dit”.
- Use “je” by default. Preserve “u” when the user or existing document requires it.
- Use “moet” for requirements, “kan” for capability or possibility, and “mag” for permission.
- Keep recommendations distinct from requirements. Do not strengthen “bij voorkeur” into “moet”.
- Preserve uncertainty. Do not change “mogelijk veroorzaakt” into “veroorzaakt” without evidence.

English rules about “-ing”, phrasal verbs, and approved parts of speech do not apply to Dutch grammar.
Technical nouns such as “logging” and “caching” can remain English.

## Structure and filler

Use complete, short sentences and concrete facts.
Split long noun chains with words such as “van”, “voor”, and “in”.
Use lists for steps or parallel items when they make the text easier to read.
Use ordinary punctuation. Replace semicolons with separate sentences.
Do not add hyphens or join words merely to meet the sentence limit.

| Avoid | Prefer |
|---|---|
| teneinde | om |
| alvorens | voordat |
| met betrekking tot | over, voor, or a direct sentence |
| indien | als |
| middels | met |
| het is belangrijk om te vermelden dat | State the fact directly |
| eenvoudigweg, moeiteloos, naadloos | Delete, unless a concrete fact supports the claim |
| robuust, krachtig, razendsnel | Give the measurable property |
| indien nodig | State the condition |
| en/of | Choose one, or write “X, Y of beide” |
| bijv., d.w.z., etc. | “bijvoorbeeld”, “dat wil zeggen”, or name the items |

## Technical content to preserve

Leave code blocks, inline code, commands, flags, paths, identifiers, URLs, API names, and configuration keys exact.
Leave quoted errors, logs, and literal interface labels exact.
Translate surrounding explanations without changing those strings.
Translate or rewrite an error message itself only when that is the requested target, rather than a quoted diagnostic string.
Preserve numbers, units, timestamps, and technical meaning.

For sentence length, count normal prose words separated by spaces.
Count an inline code span, a number with its unit, or a literal interface label as one unit.
Count English multiword terms normally: “source code” is two words.
Include parenthetical prose in the count. Split the sentence instead of hiding a long clause in parentheses.

## Document-specific patterns

- Error messages: state what happened, give the cause when known, then provide the corrective action.
- Runbooks: use imperative steps, conditions first, and warnings before the affected action.
- Incident reports: use past tense for events. Keep times, impact, and suspected causes precise.
- Release notes: state the changed behavior. For breaking changes, give the required action and its reason.
- Warnings: state the required action or condition, then the consequence. Preserve the document's existing risk labels.
- Agent instructions: use direct commands and explicit conditions. Separate requirements from optional choices.

## Example

Before:

> Als je de wijziging wilt testen, moet je eerst de broncode uit de opslagplaats ophalen en vervolgens de bouw uitvoeren.

After:

> Als je de wijziging wilt testen, haal de source code op uit de repository.
> Voer daarna de build uit.

Before:

> De applicatie werd opnieuw gestart nadat de configuratie was aangepast, waardoor de nieuwe instellingen konden worden toegepast.

After:

> De beheerder wijzigde de configuratie.
> Daarna startte de beheerder de applicatie opnieuw.
> De applicatie gebruikt nu de nieuwe configuratie.

Use the second rewrite only when the actor and current state are known.
Otherwise preserve the unknown actor and the original time relationship.

## Self-check

Before delivering the text:

1. Check the three longest sentences against the 20-word or 25-word limit.
2. Check that each procedural sentence gives one instruction and puts its required condition first.
3. Check consistent terminology, especially English terms and their Dutch alternatives.
4. Check natural Dutch grammar around English terms. Remove awkward compounds and invented loan verbs.
5. Remove filler, vague claims, ambiguous pronouns, and unnecessary passive constructions.
6. Confirm that facts, uncertainty, recommendations, permissions, and requirements retain their original meaning.
7. Confirm that protected technical strings remain exact.

Correct the text before delivering it. Do not include this checklist in the output unless the user requests an audit.
