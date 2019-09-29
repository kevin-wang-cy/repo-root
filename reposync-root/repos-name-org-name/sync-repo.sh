#!/bin/bash

# Up Stream Info
UPSTREAM_USERNAME="${UPSTREAM_USERNAME:="--no user name--"}"
UPSTREAM_PASSWORD="${UPSTREAM_PASSWORD:="--no password--"}"
UPSTREAM_ORGNAME="${UPSTREAM_ORGNAME:="FOGDB"}"
UPSTREAM_HOSTNAME="${UPSTREAM_HOSTNAME:="git.labs.quest.com"}"
UPSTREAM_HTTPPROTOCAL="${UPSTREAM_HTTPPROTOCAL:="https"}"
UPSTREAM_HTTPPORT="${UPSTREAM_HTTPPORT:="443"}"
UPSTREAM_SSHPORT="${UPSTREAM_SSHPORT:="22"}"
UPSTREAM_REST_REPO="$UPSTREAM_HTTPPROTOCAL://$UPSTREAM_HOSTNAME:$UPSTREAM_HTTPPORT/rest/api/1.0/projects/$UPSTREAM_ORGNAME/repos?limit=1000"
UPSTREAM_SSH_GIT="ssh://git@$UPSTREAM_HOSTNAME:$UPSTREAM_SSHPORT"

# Down Stream Info
DOWNSTREAM_USERNAME="${DOWNSTREAM_USERNAME:="--no user name--"}"
DOWNSTREAM_PASSWORD="${DOWNSTREAM_PASSWORD:="--no password--"}"
DOWNSTREAM_ORGNAME="${UPSTREAM_ORGNAME,,}"
DOWNSTREAM_HOSTNAME="${DOWNSTREAM_HOSTNAME:="$(ip route|awk '/default/ { print $3 }')"}"
DOWNSTREAM_HTTPPROTOCAL="${DOWNSTREAM_HTTPPROTOCAL:="http"}"
DOWNSTREAM_HTTPPORT="${DOWNSTREAM_HTTPPORT:="53000"}"
DOWNSTREAM_SSHPORT="${DOWNSTREAM_SSHPORT:="53022"}"
DOWNSTREAM_REST_ORG_REPO_READ="$DOWNSTREAM_HTTPPROTOCAL://$DOWNSTREAM_HOSTNAME:$DOWNSTREAM_HTTPPORT/api/v1/orgs/$DOWNSTREAM_ORGNAME/repos"
DOWNSTREAM_REST_ORG_REPO_CHANGE="$DOWNSTREAM_HTTPPROTOCAL://$DOWNSTREAM_HOSTNAME:$DOWNSTREAM_HTTPPORT/api/v1/org/$DOWNSTREAM_ORGNAME/repos"
DOWNSTREAM_REST_ORG_READ="$DOWNSTREAM_HTTPPROTOCAL://$DOWNSTREAM_HOSTNAME:$DOWNSTREAM_HTTPPORT/api/v1/admin/orgs"
DOWNSTREAM_REST_ORG_CHANGE="$DOWNSTREAM_HTTPPROTOCAL://$DOWNSTREAM_HOSTNAME:$DOWNSTREAM_HTTPPORT/api/v1/orgs"
DOWNSTREAM_SSH_GIT="ssh://git@$DOWNSTREAM_HOSTNAME:$DOWNSTREAM_SSHPORT"

# Repo Exclusion
EXCLUDED_REPOS_STR="${EXCLUDED_REPOS:="--space-seperated-repo-names--"}"

IFS=' ' read -a EXCLUDED_REPOS <<< "${EXCLUDED_REPOS_STR}"

# DIRECTION : ALL | ONLY_UPSTREAM | ONLY_DOWNSTREAM
DIRECTION="ALL"

# repos/
#   - <github-org name>
#       - sync-repo.sh
#       - repo
#           - <repo Name 1>.git
#           - <repo Name 2>.git
#       - ssh
#           - id_rsa_upstream
#           - id_rsa_upstream.pub
#           - id_rsa_downstream
#           - id_rsa_downstream.pub
#   - <git-labs-quest-org name>
#       - sync-repo.sh
#       - repo
#           - <repo Name x>.git
#       - ssh
#           - id_rsa_upstream
#           - id_rsa_upstream.pub
#           - id_rsa_downstream
#           - id_rsa_downstream.pub
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DATADIR_SSH="$SCRIPT_DIR/ssh"
DATADIR_REPO="$SCRIPT_DIR/repo"

mkdir -p $DATADIR_REPO

# Print Usage
function usage() {
    echo "  "
    echo "Description"
    echo "  "
    echo "  First, change the [Up Stream Info] and [Down Stream Info] in sync-repo.sh to right info."
    echo "  Second, generate no password protection ssh keys into [$DATADIR_SSH] folder."
    echo "      Note: "
    echo "          [1] id_rsa_upstream is for up stream repo and id_rsa_downstream for down stream repo."
    echo "          [2] make sure register them into the crosponding repo."
    echo "      Command: "
    echo "          ssh-keygen -b 2048 -t rsa -f $DATADIR_SSH/id_rsa_upstream -q -N \"\" "
    echo "          ssh-keygen -b 2048 -t rsa -f $DATADIR_SSH/id_rsa_downstream -q -N \"\" "
    echo "  Then you're settled to sync repo by executing below command as below."
    echo "  "
    echo " Options"
    echo "  "
    echo "      --up, only clones repos from up stream repo server as mirror and keep it updated."
    echo "      --down, only push downloaded mirror repos upto down stream repo server"
    echo "      --help, print out this usage help doc."
    echo "      Note: without option means do both up and down options."
    echo "  "
    echo "Command Example"
    echo "  "
    echo "  ./sync-repo.sh --down 2> >(tee sync-repo-error.log 2>&1) 2>&1 >sync-repo.log"
    echo "  ./sync-repo.sh --up 2> >(tee sync-repo-error.log 2>&1) 2>&1 >sync-repo.log"
    echo "  ./sync-repo.sh 2> >(tee sync-repo-error.log 2>&1) 2>&1 >sync-repo.log"
    echo "  "
}

# Parameters Handling
while [ "$1" != "" ]; do
    case $1 in
        --down )                shift
                                DIRECTION="ONLY_DOWNSTREAM"
                                ;;
        --up )                  shift
                                DIRECTION="ONLY_UPSTREAM"
                                ;;
        --help )                usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# (cloneMirror "$name" && echo "$?")
function cloneMirror() {
    repoName=$1

    status=0

    if [ ! -d "$DATADIR_REPO/$repoName.git" ]; then
        (ssh-add -D && ssh-add "$DATADIR_SSH/id_rsa_upstream" && cd $DATADIR_REPO && git clone --mirror "$UPSTREAM_SSH_GIT/$UPSTREAM_ORGNAME/$repoName.git") 2>&1

        status=$?
    fi

    if [ $status -eq 0 ]; then
        echo "Cloning local mirror clone ... OK"
    else
        echo "Cloning local mirror clone ... Fail" >&2
    fi

    return $status
}

# (updateLocalMirror "$name" && echo "$?")
function updateLocalMirror() {
    repoName=$1

    status=1

    if [ -d "$DATADIR_REPO/$repoName.git" ]; then

        
        (ssh-add -D && ssh-add "$DATADIR_SSH/id_rsa_upstream" && cd "$DATADIR_REPO/$repoName.git" && git remote update --prune) 2>&1

        status=$?

        if [ $status -eq 0 ]; then
           echo "Updating local mirror clone ... OK"
        else
           echo "Updating local mirror clone ... Fail" >&2
        fi
    fi

    return $status
}

# (updateDownstreamMirror "$name" && echo "$?")
function updateDownstreamMirror() {
    repoName=$1

    status=1

    if [ -d "$DATADIR_REPO/$repoName.git" ]; then        
        (ssh-add -D && ssh-add "$DATADIR_SSH/id_rsa_downstream" && cd "$DATADIR_REPO/$repoName.git" && git push --mirror "$DOWNSTREAM_SSH_GIT/$DOWNSTREAM_ORGNAME/$repoName.git") 2>&1

        status=$?

        if [ $status -eq 0 ]; then
           echo "Updating downstream mirror clone ... OK"
        else
           echo "Updating downstream mirror clone ... Fail" >&2
        fi
    fi

    return $status
}

# "$(skipRepo "$repoName")" == "true|false"
function skipRepo() {
    repoName=$1

    if [[ " ${EXCLUDED_REPOS[*]} " == *"$repoName"* ]];
    then
        echo "true"
    else
       echo "false"
    fi
}

# "$(orgCreated "$orgName")" == "true|false"
function orgCreated() {
    orgName=$1

    FOUND="false"
    IFS=$'\n'
    for org in $(curl --user "$DOWNSTREAM_USERNAME:$DOWNSTREAM_PASSWORD" -X GET "$DOWNSTREAM_REST_ORG_READ" -H "accept: application/json" 2>/dev/null | jq -r .[].username)
    do
        if [[ "${org,,}" == "${orgName,,}" ]]; then
            FOUND="true"
            break
        fi
    done
    unset IFS
    echo "$FOUND"
}

# httpResponse="$(createOrg "$name")";  $? -eq 0; echo "$httpResponse"
function createOrg() {
    orgName=$1

    responseContent=[]
    counter=0
    IFS=$'\n'
    for line in $(curl --user "$DOWNSTREAM_USERNAME:$DOWNSTREAM_PASSWORD" -w "\n%{http_code}" -X POST "$DOWNSTREAM_REST_ORG_CHANGE" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"username\": \"$orgName\"}" 2>/dev/null)
    do 
        responseContent[$counter]=$line
        let counter=counter+1
    done
    unset IFS
    
    echo "${responseContent[1]} ${responseContent[0]}"
    if [[ "${responseContent[1]}" -eq "201" ]]; then
        return 0
    else
        return 1
    fi
}

# "$(repoCreated "$repoName")" == "true|false"
function repoCreated() {
    repoName=$1

    FOUND="false"
    IFS=$'\n'
    for repo in $(curl --user "$DOWNSTREAM_USERNAME:$DOWNSTREAM_PASSWORD" -X GET "$DOWNSTREAM_REST_ORG_REPO_READ" -H "accept: application/json" 2>/dev/null | jq -r .[].name)
    do
        if [[ "${repo,,}" == "${repoName,,}" ]]; then
            FOUND="true"
            break
        fi
    done
    unset IFS
    echo "$FOUND"
}


# httpResponse="$(createRepo "$name")";  $? -eq 0; echo "$httpResponse"
function createRepo() {
    repoName=$1

    responseContent=[]
    counter=0
    IFS=$'\n'
    for line in $(curl --user "$DOWNSTREAM_USERNAME:$DOWNSTREAM_PASSWORD" -w "\n%{http_code}" -X POST "$DOWNSTREAM_REST_ORG_REPO_CHANGE" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"name\": \"$repoName\"}" 2>/dev/null)
    do 
        responseContent[$counter]=$line
        let counter=counter+1
    done
    unset IFS
    
    echo "${responseContent[1]} ${responseContent[0]}"
    if [[ "${responseContent[1]}" -eq "201" ]]; then
        return 0
    else
        return 1
    fi
}

function processRepo() {
    repoName=$1

    if [[ "$(skipRepo "$repoName")" == "true" ]]; then
        echo "<<< SKIPPED processing $repoName"
        return 0
    fi

    if [[ "$DIRECTION" != "ONLY_UPSTREAM" ]]; then
        if [[ "$(repoCreated "$repoName")" == "false" ]]; then
            message="$(createRepo "$repoName")"

        if [ $? -eq 1 ]; then
                echo "<<< FAILED creating $repoName due to: $message" >&2
                return 
            fi
        fi
    fi

    if [[ "$DIRECTION" != "ONLY_DOWNSTREAM" ]]; then
        cloneMirror "$repoName"
        
        status=$?
    fi

    if [[ "$DIRECTION" != "ONLY_DOWNSTREAM" ]]; then
        updateLocalMirror "$repoName"

        status=$?
    fi

    if [[ "$DIRECTION" != "ONLY_UPSTREAM" ]]; then
        updateDownstreamMirror "$repoName"

        status=$?
    fi

    if [ $status -eq 0 ]; then
        echo "<<< SUCESSED processing $repoName"
    else
        echo "<<< FAILED processing $repoName" >&2
    fi

    return $status
}

# find ssh_agent's socket
function sshagent_findsockets {
    find /tmp -uid $(id -u) -type s -name agent.\* 2>/dev/null
}

# test ssh_agent socket: 
#   sshagent_testsocket # check if current session has valid ssh_agent, return 2 if there is not.
#   sshagent_testsocket "socket-file" # check the specified ssh_agent socket status.
# 1 : no ssh-add
# 2 : no ssh-agent
# 3 : not specific an existing ssh_agent socket file
# 4 : ssh_agent is dead and delete obseleted socket file
# 0 : ssh_agent is running and context has put into current session
function sshagent_testsocket {
    if [ ! -x "$(which ssh-add)" ] ; then
        echo "ssh-add is not available; agent testing aborted"
        return 1
    fi

    if [ X"$1" != X ] ; then
        export SSH_AUTH_SOCK=$1
    fi

    if [ X"$SSH_AUTH_SOCK" = X ] ; then
        return 2
    fi

    if [ -S $SSH_AUTH_SOCK ] ; then
        ssh-add -l > /dev/null
        if [ $? = 2 ] ; then
            echo "Socket $SSH_AUTH_SOCK is dead!  Deleting!"
            rm -f $SSH_AUTH_SOCK
            return 4
        else
            echo "Found ssh-agent $SSH_AUTH_SOCK"
            return 0
        fi
    else
        echo "$SSH_AUTH_SOCK is not a socket!"
        return 3
    fi
}

# init ssh_agent in current session
function sshagent_init {
    # ssh agent sockets can be attached to a ssh daemon process or an
    # ssh-agent process.

    AGENTFOUND=0

    # Attempt to find and use the ssh-agent in the current environment
    if sshagent_testsocket ; then AGENTFOUND=1 ; fi

    # If there is no agent in the environment, search /tmp for
    # possible agents to reuse before starting a fresh ssh-agent
    # process.
    if [ $AGENTFOUND = 0 ] ; then
        for agentsocket in $(sshagent_findsockets) ; do
            if [ $AGENTFOUND != 0 ] ; then break ; fi
            if sshagent_testsocket $agentsocket ; then AGENTFOUND=1 ; fi
        done
    fi

    # If at this point we still haven't located an agent, it's time to
    # start a new one
    if [ $AGENTFOUND = 0 ] ; then
        eval `ssh-agent`
    fi

    # Clean up
    unset AGENTFOUND
    unset agentsocket

    # Finally, show what keys are currently in the agent
    ssh-add -l
}

function main () {
    sshagent_init

    ssh-keygen -F $UPSTREAM_HOSTNAME || ssh-keyscan -t rsa -p $UPSTREAM_SSHPORT $UPSTREAM_HOSTNAME >>~/.ssh/known_hosts
    ssh-keygen -F $DOWNSTREAM_HOSTNAME || ssh-keyscan -t rsa -p $DOWNSTREAM_SSHPORT $DOWNSTREAM_HOSTNAME >>~/.ssh/known_hosts

    if [[ "$DIRECTION" != "ONLY_UPSTREAM" ]]; then
        if [[ "$(orgCreated "$DOWNSTREAM_ORGNAME")" == "false" ]]; then
            
            message="$(createOrg "$DOWNSTREAM_ORGNAME")"

            if [ $? -eq 1 ]; then
                echo "Failed creating orgnizaton $DOWNSTREAM_ORGNAME due to: $message" >&2
                exit 1
            fi
        fi
    fi
    
    ERROR_COUNTER=0

    if [[ "$DIRECTION" == "ONLY_DOWNSTREAM" ]]; then
        repos=$(ls -l $DATADIR_REPO | awk '/^d/ {print $NF}' | sed 's/.git//')
    else
        repos=$(curl --user "$UPSTREAM_USERNAME:$UPSTREAM_PASSWORD" -X GET -H "Content-Type: application/json" $UPSTREAM_REST_REPO 2>/dev/null | jq -r '.values[] | {name: .name, clone: .links.clone[]|select(.name == "http")} | .name + " " + .clone.href')
    fi

    IFS=$'\n'
    for repo in $repos
    do
        echo ">>> processing $repo"
        
        eval processRepo $repo
        status=$?

        if [ ! $status -eq 0 ]; then
            ERROR_COUNTER=$((ERROR_COUNTER+1))
        fi
    done
    unset IFS

    echo "Total Failed: $ERROR_COUNTER"
    exit $ERROR_COUNTER
}

main

# Ref:
#   https://help.github.com/en/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
#   https://gist.github.com/jexchan/2351996
#   https://avacariu.me/articles/2015/mirroring-a-git-repository
#   http://blog.plataformatec.com.br/2013/05/how-to-properly-mirror-a-git-repository/
#   https://www.opentechguides.com/how-to/article/git/177/git-sync-repos.html
