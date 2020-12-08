#!/usr/bin/zsh

setopt no_continue_on_error warn_nested_var warn_create_global no_clobber pipefail
#setopt verbose

# Files to update for each repo
TARGETS=(.github/workflows/int-image.yml .github/workflows/del-env.yml integration/terraform/outputs.tf integration/image/Dockerfile)
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

function usage {
    print ${1:-did not understand what you wanted}
    cat <<EOF
Usage: 

    $PROGNAME	-${o_repos} \\ 
       		-${o_base} \\
       		-branch <branch that will be pushed> \\
       		-title "title" \\
        	-${o_body} \\
       		-${o_force}

The same body is used for all PRs. There is no parameter expansion in the body.
-base is the base branch of the PR
-branch is the branch that will be pushed, same name for all repos
-force will ignore timestamps when deciding whether to (re-)generate a file
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
    local -a o_force=(force yes)
    local -a o_title o_branch

    zmodload zsh/zutil
    zparseopts -D -F -K -- force=o_force repos:=o_repos branch:=o_branch base:=o_base title:=o_title body:=o_body
    if [[ $? != 0 ]]; then
	usage "could not parse options"
    fi
    typeset -g base_branch=$o_base[2]
    typeset -g force=$o_force[2]
    typeset -g title=$o_title[2]
    typeset -g branch=$o_branch[2]
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
	print -v cmd -f ${CMDS[$type]} $r
	
	if [[ ${+force} || $target -ot $src || ! -s $target ]]; then
	    print Running: $cmd $src with output to $target
	    mkdir -p $dirpath
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
	git diff --quiet --exit-code || git commit -a -m "Sync wf-gen from tyk-ci using pr.zsh"
	# latest commit
	c=$(git rev-parse HEAD)
	# Create PR if the latest commit is not on the base branch
	[[ -z $(git branch origin/$base --contains $c) ]] && gh pr create -d --title $t --body $b  --base $base
    )
}

#
# Start here
PROGNAME=$0
typeset -g -a repos
typeset -g branch base_branch body force title
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
