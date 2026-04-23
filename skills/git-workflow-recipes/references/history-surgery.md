# History surgery

Moving, combining, removing commits — with as much safety as possible.

## Cherry-pick a single commit

Copy a commit from one branch to another:

```bash
git checkout target-branch
git cherry-pick <sha>
```

Pick a range:

```bash
git cherry-pick <sha1>..<sha2>     # exclusive of sha1
git cherry-pick <sha1>^..<sha2>    # inclusive of sha1
```

If there are conflicts: resolve, `git add`, then `git cherry-pick --continue`.

## Find the commit that introduced a bug — `git bisect`

You know commit `A` worked; commit `B` is broken. Somewhere between them, a bug was introduced.

```bash
git bisect start
git bisect bad                     # current (broken) commit
git bisect good <known-good-sha>

# Git checks out a commit in the middle.
# Test it manually:
npm test                           # or whatever your test is

git bisect good                    # if the test passes
git bisect bad                     # if the test fails

# Repeat. Git narrows down to the guilty commit.
git bisect reset                   # end the bisect, back to HEAD
```

Bisect is O(log N). Even on a branch with 1000 commits, you test ~10 commits.

### Automated bisect

If you have a script that returns 0 for "good" and non-zero for "bad":

```bash
git bisect start HEAD <known-good-sha>
git bisect run ./test.sh
```

Git runs the script on each midpoint automatically. Walk away, come back, have the answer.

## Squash a whole branch into one commit

```bash
git checkout feat/whatever
git reset --soft main              # keep all changes staged, but now "new"
git commit -m "Add feature whatever"
```

Alternative — don't rewrite local history, use a merge-time squash:

```bash
git checkout main
git merge --squash feat/whatever
git commit -m "Add feature whatever"
```

GitHub's "Squash and merge" button does the second one automatically.

## Reorder commits

```bash
git rebase -i <base>
# In the editor, reorder the lines (the commit order changes to match).
```

Watch for conflicts if the reordered commits touch overlapping lines.

## Move a commit to a different branch

You committed to `main` when you meant `feat/whatever`:

```bash
git checkout feat/whatever
git cherry-pick main               # copies main's HEAD commit here

git checkout main
git reset --hard HEAD~1            # if main isn't shared
# or
git revert HEAD                    # if main is shared
```

## Combine consecutive commits

```bash
git rebase -i HEAD~N
# Change 'pick' to 'squash' (or 'fixup') on the commits to combine.
```

Squash keeps both commit messages (you edit them together); fixup discards the later message.

## Drop a single commit in the middle of history

```bash
git rebase -i <sha>^              # note the ^ — go one before the commit
# In the editor, change 'pick' to 'drop' on the line.
```

Back up first: `git branch backup-before-drop`.

## Remove a large file from the entire history

If you committed a huge file (model weights, video, leaked secret) and it's bloating the repo:

```bash
# Install: https://github.com/newren/git-filter-repo
pip install git-filter-repo

git filter-repo --path path/to/huge-file --invert-paths
```

This rewrites every commit in the repo to exclude that file. **It's destructive** — back up first, coordinate with collaborators, and expect to force-push.

After filter-repo, the large file is gone from history. If the file contained secrets, **rotate the credential immediately** — anyone who cloned before the rewrite still has the old history on their laptop.

## Remove a file from all of a branch's commits

Use filter-repo with `--path` and `--invert-paths` as above.

## Find who changed a specific line

```bash
git blame <file>                   # line-by-line attribution
git blame -L 42,45 <file>          # just lines 42–45
```

For finding when a specific string appeared or disappeared:

```bash
git log -p -S"magic string" <file>    # "pickaxe" — commits that added/removed the string
```

## See every commit that touched a file

```bash
git log --follow <file>            # --follow tracks renames
```

## Find what was changed by a specific commit

```bash
git show <sha>                     # message + diff
git show <sha> --stat              # message + files changed, no diff
git show <sha>:<file>              # contents of <file> at <sha>
```

## Compare two commits

```bash
git diff <sha1> <sha2>
git diff <sha1> <sha2> -- <file>
```

## Back up before anything destructive

**Always:**

```bash
git branch backup-<date>-<reason>
```

Costs nothing. Is your insurance policy. Delete it next week when you're sure you don't need it.

## Rewriting history someone else based work on

Don't. If you already did: the people affected should `git reset --hard origin/<branch>` to match, losing any local work they had. This is why you coordinate force-pushes.
