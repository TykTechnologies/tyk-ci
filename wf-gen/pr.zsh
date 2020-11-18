#!/usr/bin/zsh

setopt no_continue_on_error warn_nested_var no_clobber pipefail
#setopt verbose

# Contents of this file go into the PR body
PR_BODY=pr.md
# Repos under management, these are expected to be dirs in cwd
REPOS=(tyk tyk-analytics tyk-pump)
# Files to update for each repo
TARGETS=(.github/workflows/int-image.yml integration/terraform/outputs.tf integration/image/Dockerfile)
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4
# Generation commands for each file type, using just the extension
# because I'm lazy, the keys can be made to match as much of the
# filename as needed. %s is substituted with the repo name.
typeset -A CMDS
CMDS=( [yml]="m4 -E -DxREPO=%s -DxREPO_DIR=integration/image -DxTF_DIR=integration/terraform -DxRELEASE_BRANCHES" \
	    [tf]="m4 -E -DxREPO=%s" \
	    [Dockerfile]="m4 -E -DxREPO=%s" )
# Looks for the current branch in all repos, if not found, the branch is created
GIT_BRANCH=$(git branch --show-current)

function process_repo {
    local r=${1?"repo undefined for process"}
    local target cmd
    
    for target in $TARGETS
    do
	local target=${r}/${target}
	# Get extension of $target
	local type=${target:t:e}
	# :t is basename
	local src="${target:t}.${SOURCE_SUFFIX}"
	print -v cmd -f ${CMDS[$type]} $r
	
	if [[ $target -ot $src ]]; then
	    eval "$cmd $src >! $target"
	else
	    print $target newer than $src
	fi
    done
}

function fetch_branch {
    local r=${1?"repo undefined for fetch"}
    local b=${2?"branch undefined for fetch"}
    local base=${3:=master}

    # Since the work is done in subshell, failures are not fatal
    (
	cd $r
	git fetch --recurse-submodules=yes origin $base
	[[ $r == "tyk-analytics" ]] && git submodule update --remote --merge
	# Pull from origin if branch exists there
	git ls-remote --exit-code origin "$b" && git pull "$b"
	# Create branch if it does not exist
	git show-ref --quiet "refs/heads/$b" || git branch "$b"
	[[ "$b" == "$(git branch --show-current)" ]] || git checkout --quiet "$b"
	# Incorporate latest changes if not dirty
	git diff --quiet --exit-code && git rebase $base "$b" || print Automatic rebase of branch $b onto $base for $repo failed, fix this manually before proceeding.
    )
    return $?
}

function commit_changes {
    local r=${1?"repo undefined for commit"}
    local t=${2?"title undefined for commit"}
    local b=${3?"body undefined for commit"}
    local base=${4:=master}

    (
	cd $r
	print Start of diff for $r
	git diff
	read -q "?End of diff for $r. C-c to cancel. Any key to confirm." c
	# commit if there are changes
	git diff --quiet --exit-code || git commit -a -m "Syncing wf-gen from tyk-ci using pr.zsh"
	# latest commit
	local c=$(git rev-parse HEAD)
	# Create PR if the latest commit is not on the base branch
	[[ -z $(git branch $base --contains $c) ]] && gh pr create -d --title $t --body $b  --base $base
    )
}

#
# Start here

local title=${1?"title undefined"}
local body

if [[ -r $PR_BODY ]]; then
    body=$(<${PR_BODY})
    print -l $title $body
    read -q "?C-c to cancel. Any key to confirm." c
else
    print Body text for PR not supplied. Looking for a file named ./$PR_BODY
    exit 1
fi

for repo in $REPOS
do
    print "Processing branch $GIT_BRANCH for $repo\n"
    fetch_branch $repo $GIT_BRANCH
    print Generating files for $repo
    process_repo $repo && commit_changes $repo $title $body
    print
done
