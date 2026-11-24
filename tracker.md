# Tickets in the tracker

Tickets and ideas live in the project's tracker, and their change requests in the project's code host. `AGENTS.md` names the tracker and its **tracker binding**: the one file that says how to do each operation below in that tracker and code host. The framework ships one binding, `trackers/github.md`, for GitHub issues and pull requests. A project on another tracker or code host writes its own binding in its own docs, with the same parts and operations, and names it in `AGENTS.md`.

Roles name these parts and operations, never a tracker's own commands. Read this file with the binding before any ticket work.

## A ticket's parts

- **Ticket:** one record per ticket. Its body comes from part 1 of `ticket-template.md`: the spec, then a **Record** section with the ticket's running records.
- **Platform part:** on a ticket with platform work, one child record per platform, iOS and Android. Its body comes from part 2 of the template: that platform's notes and running records.
- **Handoff entry:** an entry added to a ticket or a platform part, from part 3 of the template. Entries are the ticket's history. Nobody edits one after posting it.
- **Idea:** a record of something that may become a ticket. It has no template.

Tickets and platform parts each carry:

- **Status:** one of the statuses in the template, one at a time. A ticket's last status, done, is the ticket being closed.
- **Holder:** whose turn it is, one at a time: product, product owner, builder or reviewer. A platform part's holder is that platform's builder or reviewer.
- **Assignee:** the account responsible right now: the session that has claimed the work, or the human whose turn it is (Claim).
- **Blocked by:** links to the tickets that must close before this one can go on.

Tickets and ideas can also carry the **next** mark: the product owner wants them worked on next.

**Ticket name:** `<number>-<slug>`, where `<number>` is the ticket's number in the tracker and `<slug>` is two to five lowercase words from its title, joined by hyphens, for example `42-saved-progress`. It is set when the ticket is opened, recorded on the ticket's `Branch:` line, and never changed. The ticket branch takes this name, and its platform branches add `-ios` or `-android` to it.

## Change requests

A **change request** asks to merge one branch into another, and carries that change's evidence and its review (`process.md`, Branches). There are two kinds:

- **The ticket's change request:** from the ticket branch into `main`. The product role opens it as a draft at drafting, set to close the ticket when it merges. Its description comes from part 4 of the template.
- **A platform change request:** from a platform branch into the ticket branch. Its builder opens it at handoff, linking its platform part, and it never closes the ticket. Its description holds the builder's evidence, from part 4 of the template.

Each review is posted on the change request it reviews. The change request is where its evidence, screenshots and reviews live; the ticket and its platform parts link to it.

## Who writes what

- Only the session that holds the ticket edits its body, or the product owner. Only that platform's builder or reviewer edits a platform part's body, or the product role while drafting. Two sessions never edit one body, so parallel platform work never overwrites the other platform's records.
- Re-read a body just before editing it, and change only your own part of it.
- Any session may add handoff entries. An entry carries no role line and no marker: the handoff entry has the fixed shape of part 3 of the template, and every other comment is plain.
- A human decision counts only when it is given to a session, in its prompt or during it. The session records it word for word, with its date, under **Human decisions** in the Record it may edit (under **Decision history** while drafting). A comment on the tracker is input, never a decision (`GLOSSARY.md`, Human decision).

## Operations

1. **Open a ticket.** The product role opens it when drafting starts, from part 1 of the template, with status draft and holder product. It creates the ticket branch from `main`, named after the ticket, in the ticket worktree (`process.md`, Branches), and records the name and the starting commit on the `Branch:` line, so the schema change can be drafted on it. Once the schema change is committed, it opens the ticket's change request (Open a change request). When the product owner has chosen an idea to draft, that idea becomes the ticket: it stops being an idea, and its original text is kept, quoted, at the top of the new body. Its number, discussion, next mark and links stay.
2. **Open a platform part.** On a ticket with platform work, the product role opens one per platform while drafting, from part 2 of the template, as a child of the ticket, titled `iOS: <ticket title>` or `Android: <ticket title>`. It has no status and no holder until its builder claims it and sets in progress.
3. **Read a ticket.** Read its body, its handoff entries, its status, holder, assignee and blocked-by links, each platform part's body, entries, status and holder, and the ticket's change requests with their descriptions, reviews and comments.
4. **List tickets.** Find open tickets, platform parts or ideas by status, holder, assignee, next mark or whether they are blocked. Closed tickets, with their merged changes, are the delivered record.
5. **Claim.** Assign the work to the tracker account the session runs as; post no entry. Work is claimed when it has an assignee and an agent role holds it, and free when it has none. While a human role holds it, the assignee marks the human's turn, not a claim. Don't claim work that is claimed, unless a human says that session has stopped: then the stale claim is cleared.
6. **Record a handoff.** Add a handoff entry from part 3 of the template. Set the status and the next holder. Remove your own assignment, and when the next holder is a human role, assign the handle `AGENTS.md` names for it. A handoff releases your claim.
7. **Set status.** Replace the status with another one from the template. On a platform part, the reviewer's approval closes the part, and sending that platform back reopens it.
8. **Block.** Link a ticket to each ticket that must close first, and remove the link when the order no longer applies. Waiting for a human isn't a block: the human is the holder.
9. **Close.** When the ticket lands, add an entry naming the commit or change that landed it, then close the ticket and any platform part still open. A ticket that won't be done closes as not planned, with an entry giving the reason and the human decision behind it.
10. **Mark as idea.** Record an idea, or turn an open record that isn't a ticket into one. Any role may record an idea it finds. Only the product owner's word turns an idea into a ticket.
11. **Mark as next.** On the product owner's word, mark an open idea or ticket as next, or remove the mark. Keep two or three marked. The mark stays until the record closes. Among marked records, blocked-by links give the order, then the lower number goes first.
12. **Move a platform part.** When the product owner lets one platform land first, move the held platform's part, with its body and entries, from the ticket to its follow-up ticket (`one-platform-first.md`).
13. **Open a change request.** Push the branch, then open the change request from part 4 of the template: the ticket's as a draft that closes the ticket when it merges, a platform one into the ticket branch, linking its platform part and never closing the ticket.
14. **Edit a change request's description.** Read its current description just before editing it, change only the line concerned, such as its Screenshots or **Platform change requests** line, and write the rest back as it was. Never rewrite a description from memory.
15. **Attach screenshots.** Attach each screenshot to the change request it is evidence for: the platform change request, or the ticket's where the work has none. Name it after the criteria it shows, and list them under each criterion in its description (Edit a change request's description). Never commit them.
16. **Post a review.** Post the review on the change request, starting with its outcome line, **approved** or **needs changes**. The outcome line is the review's verdict, whatever the code host records.
17. **Mark ready.** Turn the ticket's draft change request into one ready to merge.
18. **Merge.** Merge a change request, and delete its branch. A reviewer squash-merges an approved platform change request into the ticket branch. Only the product owner merges into `main`: a squash merge, or a merge commit when the change request carries a git subtree join or pull.
