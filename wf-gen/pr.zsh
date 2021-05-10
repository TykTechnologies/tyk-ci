#!/usr/bin/env zsh

setopt no_continue_on_error warn_nested_var warn_create_global no_clobber pipefail
#setopt verbose

source common.zsh

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

function process_repo {
    local r=${1?"repo undefined for process"}
    local file cmd
    
    for file in $TARGETS
    do
	local target="${r}/${file}"
	# Dir of the target, rooted from wf-gen
	local dirpath=$(dirname $target)
	# :t is basename
	local src="${target:t}.${SOURCE_SUFFIX}"
	# Extend this for more special conditions. Associative arrays have limitations.
	case $file in
	    *)
		cmd="m4 -E -DxREPO=${r}"
		;;
	esac

	if [[ ${+force} || $target -ot $src || ! -s $target ]]; then
	    print Running: $cmd $src with output to $target
	    print $dirpath $file
	    mkdir -p $dirpath || exit 1
	    eval "$cmd -DxM4_CMD_LINE=\"$cmd\" -DxPR_CMD_LINE='$PROGNAME $CMD_LINE' $src >! $target"
	    (cd $r && git add $file)
	else
	    print $target newer than $src
	fi
    done
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
	git push origin $branch
	if [[ -z $push_only ]]; then
	    gh pr create --draft --title $t --base $base --reviewer TykTechnologies/devops --body $body
	fi
    )
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
    print "Processing branch $base_branch for $repo\n"
    fetch_branch $repo $branch $base_branch
    print Generating files for $repo
    process_repo $repo && commit_changes $repo $title $body $base_branch
done
