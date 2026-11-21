# App schema template

The **app schema** is a living, platform-neutral description of what the app does, as shipped. Both native apps are built from it, and a new engineer reads it to learn the app. It lives in the folder that `AGENTS.md` names in its **App schema** row, in two kinds of file:

1. **Index:** `README.md`, one per app. It lists the features and holds the app's top-level navigation.
2. **Feature file:** `<feature>.md`, one per feature, where `<feature>` is two to four lowercase words joined by hyphens, for example `saved-items.md`. A feature is one capability the product owner would name.

Copy each part below without its heading.

## Rules

- **Only through a ticket.** Only the product role edits the schema, on a ticket branch, while drafting a ticket or clarifying its spec (`roles/product.md`). The change lands on `main` with the ticket's code, so the schema on `main` always describes the app as shipped. A builder or reviewer never edits it: behaviour the schema doesn't cover is the builder's stopgap, one line in its platform part (`roles/builder.md`, override 6).
- **What it holds.** What the app does, never how one platform does it. The design source owns the look, and the schema names component roles only. The convention references own each platform's idioms. Codebase facts, platform notes with sources, validation and decision history belong to the ticket (`ticket-template.md`).
- **Fixed sections.** Every feature file has the nine `##` headings below, in this order, spelled exactly as here. Write "None" under a heading with nothing to record. **States** holds either a state machine or a line that starts "No lifecycle:". Keep to these exact forms, so that a check can find them.
- **One owner.** Each data type, rule and interface text key is owned by one feature, and is written only in that feature's file. Another feature that relies on it lists it under **Links to other features** and doesn't repeat it.
- **Criterion IDs.** Each acceptance criterion has an ID, `C1`, `C2` and so on, unique within its feature file. An ID is never renumbered, and never reused once its criterion is removed: give a new criterion the next number after the highest ever used, and leave a removed one's ID out. Other files cite a criterion as `<feature>#C<n>`, for example `saved-items#C3`. Screenshots are named after these IDs (each convention reference, rule 8.5).
- **Not yet on a platform.** When the product owner lets one platform land first, mark each criterion the other platform doesn't meet yet with `*(not yet on <iOS or Android>: #<follow-up ticket>)*` at its end. When the whole feature is missing on that platform, add the same marker to the feature's line in the index. The follow-up ticket removes the marker when it lands.
- **Format.** Markdown with small tables and lists. The framework release named in `AGENTS.md` sets the format, so the files carry no version line.
- **A new app** with no shipped features starts the schema in its first ticket, which creates the index. An app that already ships features adopts the schema first (`adoption.md`).

## Part 1: index

```markdown
# App schema

<One or two sentences on what the app does, for someone who has never used it. The brief keeps the purpose and the open questions.>

## Features

<One line per feature file, in the order a new engineer should read them.>

- [<Feature name>](<feature>.md): <one-line summary>

## Navigation

<The app's top-level structure: what the app opens on, and the root destinations a person can reach from anywhere, such as tabs. Each feature file's **Screens and surfaces** names the destinations it adds below these.>

| Destination | Kind | Owned by |
|---|---|---|
| <name> | <root, tab, or another kind from Screens and surfaces> | [<feature>](<feature>.md) |

## Conventions

<Optional: the app's own rules for reading its feature files, such as how each platform cases interface text, or a note form the files share. Leave the section out when there are none.>
```

## Part 2: feature file

```markdown
# <Feature name>

<One sentence: what a person can do with this feature.>

## Data

<The data this feature owns, one table per type. Types are plain words: text, number, true or false, date, duration, web address, or another type's name. Add `?` when a value may be absent, and say in Notes what is shown then. Saved: yes when it outlives the app's process, no when it lives in memory only. Data owned by another feature is listed under Links to other features, not here.>

### <Type>

| Field | Type | Saved | Notes |
|---|---|---|---|
| <field> | <type> | yes / no | <rules: allowed values, what is shown when absent, when it is written> |

## States

<Either a state machine or the line "No lifecycle: <reason>". A feature has a lifecycle when something in it changes state over time in response to events, beyond what a screen shows from saved data: loading, saving, playing, a pending action. Such a feature must have a state machine. A reviewer judges whether a "No lifecycle" reason holds.>

<Name the state machine, and list its states.>

**<Name>.** States: <state>, <state>, … Initial: <state>.

| From | Event | Guard | To | Effect |
|---|---|---|---|---|
| <state, list of states, or any> | <event: a person's action, a system event or a result> | <condition, or —> | <state> | <what changes: data written, position kept, screen opened, or —> |

## Screens and surfaces

<Destinations are places a person navigates to. Kind is platform-neutral: root, tab, push, sheet, full screen, or dialog (a modal alert or dialog over the current destination, which returns to it). Each platform presents a kind with its own conventions.>

| Destination | Kind | Opens from | Returns to |
|---|---|---|---|
| <name> | <kind> | <destination and action> | <destination, or previous> |

<Surfaces are elements that aren't destinations but stay on screen while a condition holds, such as a bar pinned above content or a system media control.>

| Surface | Shown on | Shown while | Notes |
|---|---|---|---|
| <name> | <destinations> | <condition, naming a state where one applies> | <placement or behaviour rules> |

## Component roles

<What each meaningful element on this feature's destinations and surfaces does, never how it looks. A role is a kebab-case name the app chooses. Where the design source has its own name for the component, use that name. Give a role's meaning the first time the schema uses it. Each platform picks its own native component for the role.>

| Element | Role | Meaning | Content and behaviour |
|---|---|---|---|
| <destination>.<element> | <role> | <one line, where the role first appears> | <what it shows, when it is enabled, what it does, what a screen reader announces> |

## Interface text

<Every piece of text this feature shows or announces, including accessibility labels. Placeholders in braces name data fields. Keys are unique within the feature.>

| Key | Text | Notes |
|---|---|---|
| <key> | <text> | <where it appears, or the accessibility label it is> |

## Deliberate platform differences

<Places where the two apps behave differently on purpose, each with its reason and the decision behind it. This includes a departure from a convention-reference rule that only this feature makes: give the rule, what the app does instead, and the decision. App-wide departures stay in `AGENTS.md`'s Deviations.>

- <iOS or Android, or both>: <what differs> (<reason>; <link to the decision>)
- Differs, not decided: <iOS or Android, or both>: <what differs> (behind <the unusual condition>; <ticket>)

<A "Differs, not decided" line records no decision: the difference is reachable only behind an unusual condition, and both platforms meet safe failure there.>

## Non-goals

<What this feature deliberately doesn't do, so no builder adds it and no reviewer asks for it.>

- <non-goal>

## Links to other features

<Each data type, rule or criterion owned by another feature that this one relies on, and how.>

- `<feature>#<C<n>, type or rule>`: <what this feature relies on>

## Acceptance criteria

<Observable, platform-neutral behaviour that both apps must meet. Write each in EARS style where it fits, naming the states and events from States:
- When <event>, the app shall <response>.
- While <state>, the app shall <response>.
- If <unwanted condition>, then the app shall <response>.
- Where <optional capability>, the app shall <response>.
- The app shall <response>, for something always true.>

- **C1.** <criterion>
```
