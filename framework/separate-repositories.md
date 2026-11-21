# Separate platform repositories

By default one repository holds both apps, the app schema and `framework/`. A project may instead keep the iOS app and the Android app in repositories of their own. Then:

- A small **product repository** holds the app schema, the brief, the design source, the decision records, the glossary and the tracker. It alone takes `framework/`, and its `AGENTS.md` is the project's, mapping each platform folder to its repository. Each app repository keeps a short `AGENTS.md` that points to it. A builder or reviewer session works in its app repository with the product repository checked out beside it, and reads `framework/`, the schema and `AGENTS.md` there.
- The ticket branch and the ticket's change request are in the product repository and hold the schema change, opened as a draft at drafting as usual. Here the ticket's change request is called the **schema change request**.
- In each app repository, the builder works on a branch named after the ticket, created from `main`, and opens its platform change request into `main`, linking the ticket. It must not close the ticket. The reviewer reviews it as usual, but doesn't merge it.
- At acceptance the product owner tries the apps built from those branches. At landing the product owner merges both platform change requests, each in its own repository, and then the schema change request, which closes the ticket. The schema merges last. When one platform lands first (`one-platform-first.md`), the schema change request merges after that platform's, with the "not yet on" markers.
- Land runs in the product repository.
