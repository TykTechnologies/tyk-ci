#!/usr/bin/env zsh

setopt no_continue_on_error warn_nested_var warn_create_global no_clobber pipefail
#setopt verbose

source common.zsh

# Source branches for release automation, note that the elements are space separated
typeset -A SOURCE_BRANCHES
SOURCE_BRANCHES[tyk]='master'
SOURCE_BRANCHES[tyk-analytics]='master'
SOURCE_BRANCHES[tyk-pump]='master'
SOURCE_BRANCHES[tyk-pump]='master'
SOURCE_BRANCHES[tyk-sink]='master'

# Release branches for known repos, all automation will be sync'd to these branches when pushed to the corresponding SOURCE_BRANCH by sync-automation.yml
# Needs to be a comma-separated list as it it goes into a YAML array.
typeset -A RELEASE_BRANCHES
RELEASE_BRANCHES[master,tyk]='release-4-lts, release-3.2.3, release-4'

RELEASE_BRANCHES[master,tyk-analytics]='release-4-lts, release-3.2.3, release-4'

RELEASE_BRANCHES[master,tyk-pump]='release-1.5'

RELEASE_BRANCHES[master,tyk-sink]='release-1.8 release-1.9'

function parse_options {
    # Defaults
    local -a o_repos=(repos $REPOS)
    local -a o_base=(base master)
    local -a o_body=(body pr.md)
    local o_help o_push_only o_force="yes"
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
    read -q "?Control-C to cancel. Any key to confirm." c
}

function usage {
    print ${1:-did not understand what you wanted}
    cat <<EOF
Usage: 

    $PROGNAME	-${o_repos}

Manages the automated sync of release engineering code. This means that it is no longer necessary to remember which branches to cherry pick changes to. Maintains a two maps:
SOURCE_BRANCHES which is map of repo to a list of root branches (i.e. branches onto which commits can land directly, without being cherry picked)
RELEASE_BRANCHES which is a per-repo map of root branches to branches that release engineering code should be sync'd to

Any omitted options will use the values above
GNU style long/short options not supported
EOF
    exit 1
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
	if [[ $push_only == "yes" ]]; then 
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
    local body=${3?"body undefined for commit"}
    local base=${4?"base branch undefined for commit"}

    local c
    (
	cd $r
	print Start of diff for ${r}, comments ignored
	git diff --staged -G'(^[^#])'
	read -q "?End of diff for $r. Control-C to cancel. Any key to confirm." c
	# commit if there are changes
	git commit -m $t
	git push --force-with-lease origin $branch
	if [[ -z $push_only ]]; then
	    gh pr create --draft --title $t --base $base --reviewer TykTechnologies/devops --body $body
	fi
    )
}

function process_repo_branch {
    local r=${1?"repo undefined for process"}
    local branch=${2?"src branch undefined for process"}
    local cmd
    
    local target="${r}/.github/workflows/sync-automation.yml"
    local dirpath=$(dirname $target)
    # :t is basename
    local src="${target:t}.${SOURCE_SUFFIX}"

    cmd="m4 -E -DxSRC_BRANCH='$branch' -DxRELEASE_BRANCHES='$RELEASE_BRANCHES[$branch,$r]' -DxAUTO_FILES='$SYNC_AUTO_TARGETS'"

    print Running: $cmd $src with output to $target
    mkdir -p $dirpath || exit 1
    eval "$cmd -DxM4_CMD_LINE=\"$cmd\" -DxPR_CMD_LINE='$PROGNAME $CMD_LINE' $src >! $target"
    (cd $r && git add .github/workflows/sync-automation.yml)
}

#
# Start here
PROGNAME=$0
CMD_LINE=$*
typeset -g -a repos
typeset -g branch base_branch body force title push_only
parse_options $*

# Split on comma for repos
for repo in $repos
do
    for src_branch in ${(z)SOURCE_BRANCHES[$repo]}
    do
	[[ -n $RELEASE_BRANCHES[$src_branch,$repo] ]] || continue
	fetch_branch $repo $branch $src_branch  #base branch is always src_branch.
	print Generating files for $repo/$src_branch
	process_repo_branch $repo $src_branch
	commit_changes $repo $title $body $src_branch
    done
done

