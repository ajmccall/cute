# App releases

An app release is a tagged build of both apps, at which each platform's product outcomes are measured (`measures.md`, App releases). The product owner decides when to make one.

- It is a ticket with a platform part for each platform. Its Schema change is "None: app release", and its acceptance criteria are each platform's outcomes and the roll-up that `measures.md` lists.
- Each platform's builder measures the outcomes on a release build of its platform branch, with section 10 of its convention reference, and records them in its platform part's Record. The builder changes code only where a measuring method needs it, such as a benchmark module or a performance test.
- At Land, the product role adds the roll-up to the ticket's Record: each ticket landed since the previous app release, with its Cost totals and its review rounds per platform (`roles/product.md`, Land).
- The product owner tags the landing merge commit in the project's own tag format. For an app that isn't in a store, that tag is the release.
