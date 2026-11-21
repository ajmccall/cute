# One platform first

Both platforms are built in the same ticket by default. The product owner may let one platform land first, at any time before landing, by a decision recorded under **Human decisions**. Then:

- The product role opens a follow-up ticket for the held platform, blocked by this one (`tracker.md`, Block), and moves the held platform's part to it, with its records (`tracker.md`, Move a platform part).
- On the ticket branch, the product role marks each criterion the held platform doesn't meet yet, and the feature's index line if the whole feature is missing, with `*(not yet on <platform>: <follow-up ticket>)*` (`schema-template.md`). Made after approval, this is a spec change after approval: the product owner approves it, and the ticket's **Schema change** records it.
- The held platform's unmerged work stays on its platform branch for the follow-up. The ticket goes on with the other platform alone, and the follow-up removes the markers when it lands.

The app schema stays true for both apps at all times.
