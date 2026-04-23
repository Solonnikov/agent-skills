# Rebase and merge

## Rebase vs merge — the 30-second call

- **Use rebase** to keep a feature branch's history clean before merging. Result: linear history.
- **Use merge** for the moment the branch lands on `main`. Result: a merge commit that records the integration.
- **Never rebase** a branch someone else has based work on. You'll strand their commits.
- **Never rebase** a shared branch like `main` or `develop`. Use merge.

If your team uses squash-and-merge PRs (the common GitHub workflow), rebase isn't even necessary before merging — GitHub squashes your commits into one on merge regardless.

## Interactive rebase — clean up a branch before PR

```bash
git checkout my-feature
git rebase -i main
```

An editor opens with a list:

```
pick abc1234 First commit
pick def5678 Second commit
pick 9012345 Third commit
```

Change `pick` to:
- `reword` (or `r`) — change the commit message
- `edit` (or `e`) — stop and let you amend the commit
- `squash` (or `s`) — combine into the previous commit (merge messages)
- `fixup` (or `f`) — combine into the previous commit (discard this message)
- `drop` (or `d`) — remove the commit

Save and close. Git rewrites history. **Force-push** (to your own branch only):

```bash
git push --force-with-lease
```

`--force-with-lease` refuses if someone else has pushed to the branch since your last fetch. Safer than `--force`.

## Autosquash — the preferred workflow

Make fixup commits as you work, then let git squash them automatically.

### Make a fixup commit

```bash
git commit --fixup <sha>         # <sha> is the commit the fixup modifies
git commit --fixup HEAD~2        # "fix up the commit 2 back"
```

The new commit's message is `fixup! <original message>`.

### Rebase with autosquash

```bash
git rebase -i --autosquash main
```

Git automatically reorders fixup commits next to their targets and marks them `fixup` in the interactive rebase. You just save and close.

Configure once to make `--autosquash` default:

```bash
git config --global rebase.autosquash true
```

## Resolving conflicts during rebase

```
CONFLICT (content): Merge conflict in foo.ts
error: could not apply abc1234... My commit
```

1. `git status` — see the conflicted files.
2. Open each and resolve the `<<<<<<<` / `=======` / `>>>>>>>` markers.
3. `git add <file>` for each resolved file.
4. `git rebase --continue` — proceed to the next commit.

If it's getting hairy:

```bash
git rebase --abort         # back to the state before the rebase started
```

If the same conflict keeps coming up across commits:

```bash
git rebase --skip          # skip the current commit (discards it)
```

Use `skip` carefully — it drops the whole commit. Often you want `--continue` after resolving.

## `rerere` — make conflict resolution sticky

```bash
git config --global rerere.enabled true
```

`rerere` = "reuse recorded resolution". Git remembers how you resolved a specific conflict, and applies the same resolution automatically next time the same conflict appears. Huge quality-of-life improvement for long-lived branches.

## Rebase onto a different base

Branch off the wrong base? Move it:

```bash
git rebase --onto main old-base my-feature
```

Replays `my-feature`'s commits (from after `old-base`) onto `main`.

## Merge a branch into `main`

Fast-forward merge (when `main` hasn't moved since you branched):

```bash
git checkout main
git merge my-feature          # fast-forward, no merge commit
```

Non-fast-forward merge (common; preserves branch history):

```bash
git merge --no-ff my-feature  # always creates a merge commit
```

Squash merge (one commit on `main` representing the whole branch):

```bash
git merge --squash my-feature
git commit -m "Add feature X"
```

GitHub's "Squash and merge" button does exactly this.

## `pull --rebase` vs `pull`

Default `git pull` does a merge. On an active branch, this produces many ugly "Merge branch 'main' into main" commits.

Set this globally to rebase on pull instead:

```bash
git config --global pull.rebase true
```

Now `git pull` replays your local commits on top of the fetched ones. Cleaner history.

## Force-push with safety

**Never:**
```bash
git push --force         # overwrites remote unconditionally
```

**Always:**
```bash
git push --force-with-lease
```

`--force-with-lease` checks that the remote branch is at the commit you last fetched. If someone else pushed in the meantime, it refuses — saving you from overwriting their work.

Set it as your default:

```bash
git config --global alias.fpush 'push --force-with-lease'
# Then: git fpush
```
