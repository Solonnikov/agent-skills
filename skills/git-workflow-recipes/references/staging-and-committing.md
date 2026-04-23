# Staging and committing

## Add only part of a file

```bash
git add -p <file>
```

`-p` is interactive "patch" mode. For each chunk, git asks `y` (stage), `n` (skip), `s` (split smaller), `e` (edit the chunk by hand), `q` (quit).

Use when a file has multiple unrelated changes and you want them in separate commits.

## Add everything tracked (but skip new files)

```bash
git add -u
```

Stages modifications and deletions to tracked files. Doesn't add new untracked files.

## Add everything including new files

```bash
git add -A            # stages everything: new, modified, deleted
git add .             # stages everything in current dir and below
```

Prefer `git add -A` for clarity — `git add .` depends on your current directory.

## Skip adding — commit directly from the working tree

```bash
git commit -am "message"
```

Combines `add -u` + `commit`. Doesn't catch new files.

## Amend the last commit

Change the message:

```bash
git commit --amend -m "new message"
```

Add more changes:

```bash
git add <more files>
git commit --amend --no-edit
```

## Split one commit into multiple

```bash
git reset HEAD~1
# All changes from the last commit are now unstaged.

git add <first batch of files>
git commit -m "First part"

git add <second batch>
git commit -m "Second part"
```

For finer control, use `git add -p` to split even within a single file.

## Combine recent commits into one (squash)

Interactive rebase:

```bash
git rebase -i HEAD~3
# Change 'pick' to 'squash' (or 'fixup') on the commits you want to combine.
```

Or with reset:

```bash
git reset --soft HEAD~3         # soft = keep changes staged
git commit -m "Combined commit"
```

## Fixup workflow — the daily pattern

During a feature branch:

1. `git commit --fixup <sha>` when you notice a tiny fix for an earlier commit.
2. Keep working and making regular commits.
3. Before opening the PR: `git rebase -i --autosquash main`.

Fixups are automatically merged into the right commits in the right order. You just save the editor.

## Commit message conventions

Follow the team's convention. Two common ones:

**Conventional Commits:**
```
feat: add user profile page
fix: avoid crash when profile is null
docs: clarify the auth flow
refactor(user): extract profile service
test: cover profile not-found case
chore: update dependencies
```

Plays nicely with `semantic-release` and changelogs.

**Imperative, descriptive:**
```
Add user profile page
Fix crash when user profile is null
Clarify the auth flow in the docs
```

Either works. Pick one and stick with it.

## What a good commit message looks like

```
Add user profile page

Show user info + recent activity. Fetches from /api/users/me;
falls back to local cache if the request fails.

Related to #456.
```

- **Subject line under 72 chars**, imperative mood, no period.
- **Blank line**, then body.
- **Body explains *why***, not what — the diff shows what.
- **Reference tickets or PRs** at the end.

Not every commit needs a body. A one-line subject is fine for small, self-explanatory changes.

## Sign your commits

```bash
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true
```

Signed commits show a verified badge on GitHub. Increasingly expected for maintained repos.

SSH signing is simpler than GPG these days:

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

## Stash — save work without committing

```bash
git stash                    # stashes tracked modifications
git stash -u                 # includes untracked files
git stash push -m "WIP on X" # with a message
git stash list               # see all stashes
git stash pop                # apply the top stash and remove it
git stash apply stash@{2}    # apply a specific one, keep it
git stash drop stash@{2}     # delete a specific stash
```

Use `-u` (include untracked) more often than you'd think. Without it, new files get left behind.

## Commit a file you previously told git to ignore

```bash
git add -f <file>           # force-add, bypasses .gitignore
```

Rare — usually you want to edit `.gitignore` instead. Useful for one-off committed artifacts like a lockfile under an otherwise-ignored directory.
