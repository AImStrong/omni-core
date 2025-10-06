# git collaboration guidelines
- General workflow: checkout `develop` -> create new feat. branch -> merge back

## Starting and working on new branch
- branch name should quickly identify its purpose.
	+ example: feature/feature-name, fix/{}, hotfix{}
- Commands:


```sh
# switch to develop branch
git checkout develop

# or pull/update changes from remote, conflicts may occur
git pull develop

# create new feature branch
# use all lowercase, hyphen-separated
git checkout -b "feature/feature-name"

# push new branch and establish tracking relation for collaboration (optional)
# assuming remote name is "origin"
# the name can be different, but don't do that
git push origin -u feature/feature-name

# make changes to your files then commit
git add [path-to-changed-file/relative-to-current-working-directory]
# or for all changed files in current directory
git add .

# commit may contain a message and optionally a description
git commit
```


![Commit message](https://i.sstatic.net/pd4eq.gifath)

- commit message "prefixes"
	+ `feat` : new feature
	+ `fix`: general fixes
	+ `doc`: documentation update
	+ `style`: formatting, no logic changes
	+ `chore`: routine tasks (deps update, build config)
	+ `refactor`: restructure, no behavior changes
	+ `test`
	+ `BREAKING CHANGE`
	+ `revert`: undo something


```sh
# commit message should contain the feature branch name and short description
"
feat(mode-switch): added single and omni chain mode to user configuration

- functions `setSingleChainMode` and `setOmniChainMode`
- new error: MODE_ALREADY_SET, code 81
- new boolean data type: `mode`
"

# commit can be fixed using amend flag
git commit --amend
```


## Updating new changes from develop branch
- scenario: you are working on your branch and some unrelated change is pulled
into origin/develop
- rebase changes from develop into your feature branch


```sh
# current branch: feature branch
# update from origin
git fetch origin

# rebase changes made on develop into your develop branch
git rebase origin/develop

# you have already pushed this branch to remote, and the changes from develop
# made before the push, rebasing may causes "history rewrite"
# in this case, push using the following flag to ensure changes made by others
# are not overwritten
git push --force-with-lease
```


## Finishing a feature
- after a feature is finalized, merge back to develop with "no fast forward"
- fast forwarding (default) will simply treat all your commits as if they were
committed directly to `develop` branch
- therefore, you should use flag `--no-ff`, or set it as default
- `--no-ff` will create a merge commit that you can set message like any other
commit, creating a sort of "checkpoint"


```sh
# checkout to develop (or pull first)
git checkout develop

# merge your feature
git merge --no-ff feature/feature-name
```


## Git branches and remotes
- remotes are where the code is hosted for collaboration, can be named
- branches can be local (exist on your computer) and remote (exist on, for
example, github.com)
- manage remote branches using tracking relation


```sh
# view remotes (double verbose)
git remotes -vv
> origin	https://github.com/TravaLendingPool/trava-protocol-v2 (fetch)
> origin	https://github.com/TravaLendingPool/trava-protocol-v2 (push)

# list all branches
git branch -a

# pull a branch from origin, a tracking relation is automatically established
git pull origin [branch-name]
```


## Dealing with conflicts

## Release, main branch, tagging
