#!/usr/bin/zsh

setopt no_continue_on_error warn_nested_var no_clobber pipefail
#setopt verbose

# Files to update for each repo
TARGETS=(.github/workflows/int-image.yml integration/terraform/outputs.tf integration/image/Dockerfile)
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4
# Generation commands for each file type, using just the extension
# because I'm lazy. If there is no extension, the whole filename is used.
# %s is substituted with the repo name.
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
	# Use whole filename if there is no extension (eg. Dockerfile)
	[[ -z $type ]] && type=${target:t}
	
	# :t is basename
	local src="${target:t}.${SOURCE_SUFFIX}"
	print -v cmd -f ${CMDS[$type]} $r
	
	if [[ ${+OPTS[-force]} || $target -ot $src || ! -s $target ]]; then
	    print Running: $cmd $src with output to $target
	    eval "$cmd $src >! $target"
	else
	    print $target newer than $src
	fi
    done
}

function fetch_branch {
    local r=${1?"repo undefined for fetch"}
    local b=${2?"branch undefined for fetch"}
    local base=${3?"base branch undefined for fetch"}

    # Since the work is done in subshell, failures are not fatal
    (
	# Clean up old stale directories
	[[ -d $r ]] && rm -rf $r
	git clone git@github.com:TykTechnologies/$r --depth 1 -b $base
	cd $r
	git checkout -b $b
    )
    return $?
}

function commit_changes {
    local r=${1?"repo undefined for commit"}
    local t=${2?"title undefined for commit"}
    local b=${3?"body undefined for commit"}
    local base=${4?"base branch undefined for commit"}

    local c
    (
	cd $r
	print Start of diff for $r
	git diff
	read -q "?End of diff for $r. C-c to cancel. Any key to confirm." c
	# commit if there are changes
	git diff --quiet --exit-code || git commit -a -m "Syncing wf-gen from tyk-ci using pr.zsh"
	# latest commit
	c=$(git rev-parse HEAD)
	# Create PR if the latest commit is not on the base branch
	[[ -z $(git branch origin/$base --contains $c) ]] && gh pr create -d --title $t --body $b  --base $base
    )
}

#
# Start here

zmodload zsh/zutil
zparseopts -D -E -F -A OPTS force repos: branch: base: title: body: || exit 1

local body c
if [[ -r $OPTS[-body] ]]; then
    body=$(<$OPTS[-body])
    print -l $OPTS[-title] $body
    read -q "?C-c to cancel. Any key to confirm." c
else
    print Body text for PR not supplied. Looking for a file named $OPTS[-body]
    exit 1
fi

# Split on comma for repos
for repo in "${(@s/,/)OPTS[-repos]}"
do
    print "Processing branch $base_branch for $repo\n"
    fetch_branch $repo $OPTS[-branch] $OPTS[-base]
    print Generating files for $repo
    process_repo $repo && commit_changes $repo $OPTS[-title] $body $OPTS[-base]
    print
done
