# Measures

What the framework measures, so that a project can say what building one app natively twice costs. It measures three things: what each session costs in agent work, how many review rounds each ticket took, and how each app release performs on each platform.

Human time isn't measured: humans can't log their own time reliably, least of all while agents run in parallel.

## Cost per session

Every session's handoff entry ends with a **Cost** line (`ticket-template.md`, part 3).

```
Cost: <platform> · <role> · <total|subagent> · <tokens> tokens · $<dollars> · <agent time>
```

- **Platform:** `iOS` or `Android` for a session given a platform, otherwise `shared` (drafting, landing, a ticket with no platform work).
- **Role:** product, builder or reviewer.
- **Scope:** `total` covers an orchestrating session and its subagents; `subagent` covers only the named subagent's transcript. An adapter that has no such distinction omits this field.
- **Tokens:** every token in the Cost line's scope, input, output and cached.
- **Dollars:** the harness's estimate of the Cost line's scope at the model's list price. It isn't the bill, but list prices make features comparable with each other and with published figures.
- **Agent time:** how long the Cost line's scope was working, excluding time spent waiting for a human. A harness may leave out some of that work: the Claude Code adapter reports the API time on a `total` line, which excludes tool runs such as builds and tests. Each adapter's README says what its figure covers.

The harness adapter supplies all figures as its harness reports them, through the command its README names (`framework-changes.md`, Plain core): the session runs it before recording the handoff and pastes the line it prints. A figure the harness can only bound is written as a lower bound, `≥ N`, and counts as recorded; the adapter's README says which figures those are. A session never estimates them itself: without an adapter, or for a figure the adapter can't supply, the field reads `not recorded`.

## Review rounds

The Land handoff's summary gives the reviews posted per platform on the ticket's change requests, including re-reviews (`roles/product.md`, Land). It is the one count the framework keeps per ticket; everything else a retro needs is in the ticket's entries and reviews.

## App releases

An **app release** is a tagged build of both apps, made by a ticket with no schema change and a platform part for each platform (`app-releases.md`). Each platform's builder measures these **product outcomes** on a release build, with the method in its convention reference (section 10, Release measures), and records them in its platform part's Record:

- **Cold start:** time from launch to the first frame of the first screen, on a physical device. Without one it reads "not measured". Simulator and emulator figures aren't recorded, because neither platform's vendor treats them as representative.
- **Download size:** what a user downloads from the store, on both platforms, so the two compare like with like. iOS also records its install size.
- **Release build time:** wall-clock time of a clean release build.
- **Days to adopt each yearly OS design change:** from the design change's start date to the day of the first app release whose screens use the new design. Each convention reference names each year's design change and its start date: on iOS, the OS version's public release; on Android, the first stable Jetpack library that carries the design's APIs. A design change not yet adopted reads "not yet adopted, N days so far", so a lag shows before it ends.

At Land, the release ticket's product role also adds the **roll-up** to the ticket's Record: every ticket landed since the previous app release, with each one's Cost totals for shared, iOS and Android, from its sessions' Cost lines, and its review rounds per platform. Where one orchestrating session has `subagent` lines, add those role lines and do not also add its `total` line; where it has no subagent lines, add its `total` line once.
