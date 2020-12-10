#!/usr/bin/zsh

setopt no_continue_on_error warn_nested_var warn_create_global no_clobber pipefail
#setopt verbose

# Files to update for each repo
TARGETS=(.github/workflows/int-image.yml .github/workflows/del-env.yml integration/terraform/outputs.tf integration/image/Dockerfile .github/workflows/sync-automation.yml)
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4
typeset -A RELEASE_BRANCHES
# Release branches for known repos, all automation will be sync'd to these branches when pushed to master by sync-automation.yml
RELEASE_BRANCHES[tyk]='release-2.9, release-3, release-3-lts, release-3.0.2, release-3.0.2-update, release-3.0.3, release-3.1, release-3.1.0, release-3.1.1, release-3.1.2'
RELEASE_BRANCHES[tyk-analytics]='release-1.9, release-1.9.3.1, release-2.9, release-3, release-3-lts, release-3.0.2, release-3.0.3, release-3.1, release-3.1.0, release-3.1.1, release-3.1.2'
RELEASE_BRANCHES[tyk-pump]='release-0.8, release-1.0'
RELEASE_BRANCHES[tyk-sink]=''

function usage {
    print ${1:-did not understand what you wanted}
    cat <<EOF
Usage: 

    $PROGNAME	-${o_repos} \\ 
       		-${o_base} \\
       		-branch <branch that will be pushed> \\
       		-title "title" \\
        	-${o_body} \\
       		[-f] [-p]

The same body is used for all PRs. There is no parameter expansion in the body.
-base is the base branch of the PR
-branch is the branch that will be pushed, same name for all repos
-f will ignore timestamps when deciding whether to (re-)generate a file
-p will only push and not create a PR
Any omitted options will use the values above
GNU style long/short options not supported
EOF
    exit 1
}

function parse_options {
    # Defaults
    local -a o_repos=(repos tyk,tyk-analytics,tyk-pump,tyk-sink)
    local -a o_base=(base master)
    local -a o_body=(body pr.md)
    local o_push_only o_help o_force="yes"
    local -a o_title o_branch

    zmodload zsh/zutil
    zparseopts -D -F -K -- f=o_force p=o_push_only repos:=o_repos branch:=o_branch base:=o_base title:=o_title body:=o_body h=o_help
    if [[ $? != 0 || -n $o_help ]]; then
	usage "could not parse options"
    fi
    typeset -g base_branch=$o_base[2]
    typeset -g force=$o_force
    typeset -g title=$o_title[2]
    typeset -g branch=$o_branch[2]
    typeset -g push_only=$o_push_only
    typeset -g -a repos=("${(@s/,/)o_repos[2]}")

    [[ -n $title && -n $branch ]] || usage "title or branch missing"
    
    if [[ -r ${o_body[2]} ]]; then
	typeset -g body=$(<${o_body[2]})
    else
	print Body text for PR not supplied. Looking for a file named $body
	exit 1
    fi

    print Will use $base_branch as the base branch and will push a branch named $branch to origin. The PR below will be pushed to $repos
    print -l $title $body
    local c
    read -q "?C-c to cancel. Any key to confirm." c
}

function process_repo {
    local r=${1?"repo undefined for process"}
    local file cmd
    
    for file in $TARGETS
    do
	local target="${r}/${file}"
	# Dir of the target, rooted from wf-gen
	local dirpath=$(dirname $target)
	# Get extension of $target
	local type=${target:t:e}
	# Use whole filename if there is no extension (eg. Dockerfile)
	[[ -z $type ]] && type=${target:t}
	
	# :t is basename
	local src="${target:t}.${SOURCE_SUFFIX}"
	# The sync worklow itself need not be sync'd, it lives on master
	local auto_files=${TARGETS:#.github/workflows/sync-automation.yml}
	# Command to generate file from template
	cmd="m4 -E -DxREPO=${r} -DxRELEASE_BRANCHES='${RELEASE_BRANCHES[$r]}' -DxAUTO_FILES='${auto_files}'"
	
	if [[ ${+force} || $target -ot $src || ! -s $target ]]; then
	    print Running: $cmd $src with output to $target
	    print $dirpath $file
	    mkdir -p $dirpath || exit 1
	    eval "$cmd $src >! $target"
	    (cd $r && git add $file)
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
	if [[ -n $push_only ]]; then 
	    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
	    #git fetch origin refs/heads/${b}:refs/remotes/origin/${b}
	    git pull origin $b
	    git checkout $b
	else
	    git checkout -b $b
	fi
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
	git diff --staged
	read -q "?End of diff for $r. C-c to cancel. Any key to confirm." c
	# commit if there are changes
	git commit -m "$title" -m "Sync by tyk-ci/wf-gen/pr.zsh. This commit was generated by code© and reviewed by humans™."
	# latest commit
	c=$(git rev-parse HEAD)
	# Create PR if the latest commit is not on the base branch
	if [[ -n $push_only ]]; then
	    git push origin $branch
	else
	    gh pr create -d --title $t --body $b  --base $base
	fi
    )
}

#
# Start here
PROGNAME=$0
typeset -g -a repos
typeset -g branch base_branch body force title push_only
parse_options $*

# Split on comma for repos
for repo in $repos
do
    print "Processing branch $base_branch for $repo\n"
    fetch_branch $repo $branch $base_branch
    print Generating files for $repo
    process_repo $repo && commit_changes $repo $title $body $base_branch
    print
done
