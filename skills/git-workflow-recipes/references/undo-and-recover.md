# Undo and recover

The most-asked git questions live here. Bookmark this file.

## The three "undo" commands — pick the right one

| Command | What it does | Destructive? |
|---------|--------------|--------------|
| `git revert <sha>` | Creates a new commit that reverses `<sha>`. History is preserved. | No |
| `git reset <sha>` | Moves HEAD to `<sha>`. Changes since then become unstaged. | Not by default |
| `git reset --hard <sha>` | Moves HEAD to `<sha>`. Discards everything after. | **Yes** |

**Rule of thumb:** if the commit is on a shared branch or already pushed, use `revert`. If it's local and you want it gone, use `reset`.

## Undo the last commit — keep the changes

```bash
git reset HEAD~1
# Files are unstaged but still present. Re-commit however you want.
```

Variants:
- `git reset --soft HEAD~1` — keeps changes staged (ready to re-commit).
- `git reset HEAD~1` (default `--mixed`) — keeps changes unstaged.
- `git reset --hard HEAD~1` — **throws away the changes**. Use with care.

## Undo the last commit — and throw the changes away

```bash
git reset --hard HEAD~1
```

Only do this if you're certain. If unsure, back up first: `git branch backup-before-reset`.

## Undo a commit that's already pushed

```bash
git revert <sha>
git push
```

`revert` creates a new commit that undoes `<sha>`. Safe because it moves forward, not backward. Anyone else tracking the branch pulls cleanly.

Don't use `reset` + force-push for shared branches. Colleagues' tooling (git, CI) will get confused.

## Undo `git reset --hard` — yes, really

You ran `git reset --hard` and lost a commit. If it's been less than ~90 days and you haven't run `git gc --prune=now`, you can get it back:

```bash
git reflog
# Output:
# abc1234 HEAD@{0}: reset: moving to HEAD~1
# def5678 HEAD@{1}: commit: the commit you want back
# ...

git reset --hard def5678
```

`reflog` is a local log of everywhere HEAD has been. Even after destructive operations, the commits themselves are garbage-collection-pending — they're still there, just unreachable from any branch.

## Recover a branch you deleted

```bash
git reflog
# find the last commit of the deleted branch
git branch recovered-branch <sha>
```

Same principle: the commits are in the reflog until GC runs.

## Discard uncommitted changes

To a single file:

```bash
git restore <file>             # new (modern) syntax
git checkout -- <file>         # old syntax, still works
```

To all unstaged changes:

```bash
git restore .
```

To unstage a file (keep the change in the working tree, just take it out of staging):

```bash
git restore --staged <file>
git reset HEAD <file>          # old syntax
```

## Amend the last commit

Change the message:

```bash
git commit --amend -m "new message"
```

Add a forgotten file:

```bash
git add <file>
git commit --amend --no-edit
```

**If the commit was already pushed**, amending rewrites it — you'll need to force-push (`--force-with-lease`), and your colleagues will see a divergence. For a shared branch, use a new commit instead.

## Drop a specific commit in the middle of history

```bash
git rebase -i <sha>^
# In the editor, change 'pick' to 'drop' on the line for the commit.
# Save and close.
```

Back up the branch first: `git branch backup-before-drop`.

## Remove a file from the last commit but keep it locally

```bash
git reset HEAD~1 -- <file>     # unstages that file
git commit --amend --no-edit   # commit without it
# <file> is now just a local uncommitted change
```

## Untrack a file that's already committed (keep locally)

Common when you committed a config or `.env` by mistake.

```bash
echo "<file>" >> .gitignore
git rm --cached <file>
git commit -m "Stop tracking <file>"
```

The file stays on your disk; git just stops watching it. **If the file contained secrets, the old commit still has them** — you also need to rewrite history (see history-surgery.md) and rotate any leaked credentials immediately.

## Revert a merge commit

```bash
git revert -m 1 <merge-sha>
```

The `-m 1` says "the mainline is parent 1" — the branch you merged into. Merging the same branch again later won't reapply the changes unless you revert the revert (yes, it's messy).

## Undo a `git commit --amend` you regret

```bash
git reflog
# find HEAD@{N} right before the amend
git reset --hard HEAD@{N}
```

Same rescue pattern — the original commit is still in reflog.
