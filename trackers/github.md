# Tracker binding: GitHub issues

How to do each operation in `tracker.md` on GitHub issues and pull requests, with the `gh` command-line tool. Tested with `gh` 2.101.0, which has the sub-issue, blocked-by and attachment flags used here.

## Before you start

- `AGENTS.md` names the repository that holds the issues, in its tracker row. Every command below passes it as `-R <owner>/<repository>`, written `-R $REPO` here. It may not be the repository you are working in.
- `gh` must be logged in, with access to that repository. The account it runs as is the one that claims work (`@me`).
- `<n>` is an issue number. Write bodies and comments to a file first and pass it with `--body-file`, so Markdown arrives intact.

Create the labels once per repository. `--force` makes this safe to run again:

```sh
for label in ticket idea next platform:ios platform:android \
  status:draft status:approved-for-build status:ready-for-acceptance \
  status:accepted status:ready-to-merge \
  status:in-progress status:ready-for-review status:needs-changes status:approved \
  holder:product holder:product-owner holder:builder holder:reviewer; do
  gh label create "$label" -R $REPO --force
done
```

## How the parts map

| Part (`tracker.md`) | On GitHub |
|---|---|
| Ticket | An issue with the `ticket` label. Its body is the ticket body. |
| Platform part | A sub-issue of the ticket, with the `platform:ios` or `platform:android` label. |
| Handoff entry | A comment on the ticket or the platform part. |
| Idea | An issue with the `idea` label. |
| Status | One `status:<status>` label, the status in lowercase with hyphens for spaces, such as `status:approved-for-build`. A ticket that is done is closed as completed, and keeps its last status label. |
| Holder | One `holder:<holder>` label, such as `holder:product-owner`. |
| Assignee | The issue's assignee. |
| Blocked by | GitHub's blocked-by issue dependencies. |
| Next mark | The `next` label. |
| Change request | A pull request. The ticket's is a draft pull request from the ticket branch into `main`. A platform change request is a pull request from the platform branch into the ticket branch. |
| Review | A pull request review left as a comment, whose body starts with the outcome line. |

An issue body and a comment each hold at most 65,536 characters. History belongs in comments, never in a body. If one handoff entry would be longer, post it as numbered comments, `(1/2)` and `(2/2)` at the start of each.

## Operations

**Open a ticket.** Write the body from part 1 of `ticket-template.md`, then:

```sh
gh issue create -R $REPO --title "<title>" --body-file <body file> \
  --label ticket --label status:draft --label holder:product
```

Make the slug from the title, create the ticket branch with that name (`tracker.md`, Open a ticket), and edit the body's `Branch:` line to give the ticket name, `<n>-<slug>`, and the branch's starting commit.

To draft an idea instead, turn that issue into the ticket. Write the new body with the idea's text quoted at its top, then:

```sh
gh issue edit <n> -R $REPO --body-file <body file> --remove-label idea \
  --add-label ticket --add-label status:draft --add-label holder:product
```

**Open a platform part.** For each platform:

```sh
gh issue create -R $REPO --parent <ticket> --title "iOS: <ticket title>" \
  --body-file <body file> --label platform:ios
```

**Read a ticket.**

```sh
gh issue view <n> -R $REPO --comments
gh issue view <n> -R $REPO --json number,title,body,labels,assignees,state,blockedBy,subIssues
```

Then read each sub-issue the same way. `--comments` and `--json` don't combine: `gh` rejects the pair. For the entries as JSON, pass `--json comments` on its own.

On a long ticket that your role has held before, read the body, then only the entries since your role's last handoff on it and on your platform part:

```sh
gh issue view <n> -R $REPO --json comments --jq '.comments[] | select(.createdAt > "<time of that handoff>") | .body'
```

A retro still reads every entry (`roles/product.md`, Retro on request).

**List tickets.** Combine labels and search terms:

```sh
gh issue list -R $REPO --label ticket --label next
gh issue list -R $REPO --label ticket --label status:approved-for-build --search "-is:blocked"
gh issue list -R $REPO --label ticket --label status:ready-for-acceptance
gh issue list -R $REPO --label holder:product-owner
gh issue list -R $REPO --label platform:android --label holder:reviewer
gh issue list -R $REPO --label idea
```

`is:blocked` matches issues with at least one open blocker. Add `--state closed` to read the delivered record. Add `--json number,title,labels,assignees` when you need the fields.

**Claim.** First read the issue's assignee and holder label (Read a ticket). If it has an assignee and an agent holder, it is claimed: don't take it. Otherwise assign it to yourself, and post no comment:

```sh
gh issue edit <n> -R $REPO --add-assignee @me
```

**Record a handoff.** Post the entry, then set the status and the holder in one edit. Run the two as separate commands, not chained, so that if a harness refuses one, you can see which step is left:

```sh
gh issue comment <n> -R $REPO --body-file <handoff comment>
gh issue edit <n> -R $REPO --remove-assignee @me \
  --remove-label <old status label> --add-label <new status label> \
  --remove-label <old holder label> --add-label <new holder label>
```

When the next holder is a human role, also pass `--add-assignee <handle>` with the handle `AGENTS.md` names for that role. If that handle is the account you run as, leave out `--remove-assignee @me`.

**Set status.** Find the current label, then swap it for the new one:

```sh
gh issue view <n> -R $REPO --json labels --jq '.labels[].name | select(startswith("status:"))'
gh issue edit <n> -R $REPO --remove-label <old status label> --add-label "status:<status>"
```

Every status label exists from the start (Before you start). If `--add-label` fails, the status isn't one from `ticket-template.md`: correct it, and never create the label.

On approval, the reviewer then closes its platform part with `gh issue close <n> -R $REPO --reason completed`. Sending that platform back reopens it with `gh issue reopen <n> -R $REPO`.

**Block.**

```sh
gh issue edit <n> -R $REPO --add-blocked-by <blocker>
gh issue edit <n> -R $REPO --remove-blocked-by <blocker>
```

**Close.** Post the entry naming the landing commit, then close the ticket and any open sub-issue:

```sh
gh issue comment <n> -R $REPO --body-file <closing comment>
gh issue close <n> -R $REPO --reason completed
```

A ticket landed by a pull request whose description says `Closes #<n>` is closed by GitHub when the pull request merges. Post the entry and close any open sub-issue yourself. A ticket that won't be done closes with `--reason "not planned"`.

**Mark as idea.**

```sh
gh issue create -R $REPO --title "<idea>" --body-file <idea body> --label idea
gh issue edit <n> -R $REPO --add-label idea
```

**Mark as next.**

```sh
gh issue edit <n> -R $REPO --add-label next
gh issue edit <n> -R $REPO --remove-label next
```

**Move a platform part.** Make the sub-issue a child of the follow-up ticket, and retitle it after that ticket:

```sh
gh issue edit <part> -R $REPO --parent <follow-up> --title "Android: <follow-up title>"
```

The commands below run in the code repository. Where the issues live in another repository, a pull request names the ticket as `<owner>/<repository>#<n>`.

**Open a change request.** Push the branch first. For the ticket's change request, whose description starts `Closes #<n>`, so that merging it into `main` closes the ticket:

```sh
git push -u origin <ticket name>
gh pr create --draft --base main --head <ticket name> --title "<ticket title>" --body-file <description file>
```

For a platform change request, into the ticket branch:

```sh
git push -u origin <ticket name>-ios
gh pr create --base <ticket name> --head <ticket name>-ios --title "iOS: <ticket title>" --body-file <description file>
```

Its description says `Part of #<n>`, never `Closes`, `Fixes` or `Resolves`, which would close the ticket from another repository's `main`. Record the pull request's link in the platform part's Record, or on the ticket's `Branch:` line for the ticket's.

**Edit a change request's description.** Save the current description to a file, change only the line concerned in that file, then write it back:

```sh
gh pr view <pr> --json body --jq .body > <description file>
gh pr edit <pr> --body-file <description file>
```

**Attach screenshots.** `gh pr comment` is the only `gh` command that uploads files. Post one signed comment with every screenshot, each with its criteria as alt text:

```sh
gh pr comment <pr> -R <owner>/<code repository> --body-file <screenshots comment> \
  --attach './saved-items-C1-C2.png#saved-items#C1, saved-items#C2' --attach './saved-items-C3.png#saved-items#C3'
```

Where the comment's body references a file, as `![saved-items#C1](./saved-items-C1-C2.png)`, the reference is rewritten to the uploaded image, but only when the `--attach` path is spelled exactly as the reference: run the command from the screenshots' folder, with `./<name>` paths, and name the code repository with `-R`, because that folder is outside it. Any other path leaves the reference broken and appends the upload at the end. Check the posted comment with `gh api repos/<owner>/<repository>/issues/comments/<id> --jq .body | grep -c '](\./'`, which must print 0. Then add the comment's link to the pull request's description, under Screenshots (Edit a change request's description).

**Post a review.** Post it as a comment review, never `--approve` or `--request-changes`: GitHub won't let an account approve its own pull request, and agents may run as the same account as a human. The body starts with the outcome line, which is the verdict.

```sh
gh pr review <pr> --comment --body-file <review file>
```

A re-review is a new review on the same pull request.

**Mark ready.**

```sh
gh pr ready <pr>
```

**Merge.** A reviewer merges an approved platform pull request into the ticket branch:

```sh
gh pr merge <pr> --squash --delete-branch
```

Run it after removing your worktree, as a command on its own, not chained with `&&`, `;` or a pipe. If the harness refuses it, the handoff gives the product owner this exact command (`roles/reviewer.md`, override 13).

When the pull request takes in `main`, merge it with `--merge` in place of `--squash`, so that the ticket branch keeps `main` as a parent (`process.md`, Merges into `main`).

The product owner merges the ticket's pull request into `main` the same way, or with `--merge` when it carries a git subtree join or pull. Where the repository's GitHub plan allows it, protect `main` so that it takes changes only by pull request. Branch protection isn't available for private repositories on GitHub Free, and then only the process rule stops an agent merging into `main`.
