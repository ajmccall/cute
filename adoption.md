# Adopting the app schema

How an app that already ships features writes its whole app schema (`schema-template.md`) before any new feature work. It runs once, as one **adoption ticket**. An app with no shipped features skips it: its first ticket starts the schema.

The schema records what the apps actually do. Where the old docs (the brief, earlier tickets, decision records) and a shipped app disagree, the app wins, and each disagreement goes to the product owner.

## The adoption ticket

The product role opens it like any ticket (`tracker.md`, Open a ticket), with a platform part for each platform. It differs from a feature ticket in four ways:

- It has no builders, because it changes no code. Its platform parts hold each platform's reviewer's check, not a build.
- Its Schema change adds every feature file and the index. Its acceptance criteria are every criterion in them.
- The reviewers check the draft before the product owner approves it, not after a build.
- It ends by shrinking the brief to its purpose and open questions.

## Steps

1. **Feature list.** The product role reads the brief, the earlier tickets, the decision records and both apps' code, and proposes the list of features, one file each, with a one-line summary for each. The product owner confirms or corrects the list, as the ticket's first decision.
2. **Draft.** On the ticket branch, the product role writes the index and every feature file from the template, from the same sources. Where the sources disagree with each other, or the code is unclear, it writes what it believes ships and marks the item for the reviewers to check. It then hands off: status ready for review, holder reviewer, on each platform part.
3. **Check against each shipped app.** Each platform's reviewer checks the draft against that platform's shipped app, in its own worktree of the ticket branch, and records the check in its platform part's Record (`roles/reviewer.md`). There is no platform change request. For every acceptance criterion and every state-machine transition, it writes one of:
   - **matches**, with how it checked: a code location, an existing test, or a named run of the app;
   - **differs: <what ships>**, with how it checked, and a screenshot attached to the ticket's change request (`tracker.md`, Attach screenshots) or a code location that shows it.

   It also lists anything the app does that the draft doesn't describe. A reviewer only reports, and never edits the schema. It hands off: status approved when everything matches, otherwise needs changes, holder product. The reviewer whose check finishes last also hands off on the ticket: status draft, holder product.
4. **Correct and decide.** The product role corrects the schema to what ships, on the ticket branch. The reviewers don't check the corrections: each one traces to an item of a review, and the product owner's approval at step 6 covers them. It sends each difference to the product owner as a decision, in rounds (`process.md`, People and questions):
   - between the old docs and an app: keep what ships, or open a ticket to change the app;
   - between the two apps: record a deliberate platform difference, or open a ticket to align them.

   Each ticket opened here is an idea or a ticket of its own (`tracker.md`, Mark as idea), linked from the decision. The schema still describes what ships until that ticket lands.
5. **Shrink the brief.** On the ticket branch, the product role cuts the brief to its purpose and open questions, since the schema now holds the app's behaviour. Behaviour that the brief described but no app ships becomes an open question or an idea, on the product owner's word.
6. **Approve and land.** The product role hands off: status draft, holder product owner. The product owner approves the schema, naming the commit (`ticket-template.md`, Schema change). That approval also accepts the ticket: there is no build and no separate acceptance, because the reviewers' checks stand in for both. The status becomes accepted and the holder product, and the ticket goes on to Land (`process.md`, Delivery loop step 6).
