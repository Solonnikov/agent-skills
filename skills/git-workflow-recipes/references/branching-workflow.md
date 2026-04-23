# Branching workflow

## Create and switch to a new branch

```bash
git checkout -b <name>       # create + switch, classic syntax
git switch -c <name>         # create + switch, modern syntax
```

Use `switch` in new scripts and docs. It's less overloaded than `checkout`.

## Branch naming

Common conventions:

- `feat/<ticket-id>-short-description` — features
- `fix/<ticket-id>-bug-summary` — bug fixes
- `hotfix/<description>` — urgent production fixes
- `docs/<description>` — docs-only changes
- `chore/<description>` — tooling, deps

Avoid: slashes in names beyond the prefix, spaces, ALL-CAPS.

## Switch branches

```bash
git switch <name>
git checkout <name>          # older syntax, still works
git checkout -               # switch to previous branch (like cd -)
```

## Delete a branch

```bash
git branch -d <name>         # safe — refuses if branch isn't merged
git branch -D <name>         # force delete
```

Delete a remote branch:

```bash
git push origin --delete <name>
```

## Rename a branch

Locally:

```bash
git branch -m <old> <new>
```

Or, if you're on it:

```bash
git branch -m <new>
```

Update the remote:

```bash
git push origin -u <new>
git push origin --delete <old>
```

## List branches

```bash
git branch                   # local branches
git branch -r                # remote-tracking branches
git branch -a                # all

git branch --merged          # branches already merged into current
git branch --no-merged       # not yet merged

git branch -v                # show last commit for each
```

## Prune stale remote branches

After deleting branches on the remote, your local still has references.

```bash
git fetch --prune
```

One-time fix. Set it as default:

```bash
git config --global fetch.prune true
```

## Moved the wrong commit to the wrong branch

You committed to `main` when you meant to commit to `feat/whatever`:

```bash
git checkout feat/whatever
git cherry-pick main
git checkout main
git reset --hard HEAD~1       # only if main isn't shared / not yet pushed
```

If `main` is shared, don't reset it — revert the accidental commit instead:

```bash
git checkout main
git revert HEAD
```

## Committed on `main` with no branch — move to a new branch

```bash
git branch feat/rescue-me      # save current main state to a new branch
git reset --hard origin/main   # reset main back to where remote is
git checkout feat/rescue-me    # your work is here now
```

## Keep your feature branch up to date with `main`

```bash
git fetch origin
git rebase origin/main         # cleanest — replays your commits on top
# or
git merge origin/main          # creates merge commits — messier but safer in shared scenarios
```

Do this daily on long-lived feature branches. Conflicts stay small.

## Clean up merged branches

```bash
# Delete local branches that have been merged into main.
git branch --merged main | grep -v "main\|develop" | xargs -n 1 git branch -d
```

Add to your Makefile or a local script to run weekly.

## Check what changed between branches

```bash
git diff main..feat/whatever          # all differences
git diff main..feat/whatever -- <file> # just one file
git log main..feat/whatever            # commits on feat that aren't on main
git log feat/whatever..main            # commits on main that aren't on feat
```

## Check what you'd push

```bash
git log origin/feat/whatever..feat/whatever
# commits you have locally that aren't on the remote
```

## PR-ready checklist before opening

- [ ] `git fetch origin && git rebase origin/main` — up to date.
- [ ] `git rebase -i --autosquash main` — fixups squashed, history clean.
- [ ] Commit messages make sense as release notes (see staging-and-committing.md).
- [ ] Tests pass locally.
- [ ] `git push --force-with-lease` (if you rebased) or `git push` (if you didn't).
- [ ] Open the PR with a descriptive title.
