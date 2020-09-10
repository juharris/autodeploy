#!/bin/bash

# Enable job control with -m so that the deployment can be stopped.
set -em

# Default options.
deploy_cmd=""
workdir=.

update_cmd=""
# Default for Git.
up_to_date_pattern="Already up-to-date"

sleep_between_checks=10m

# Parse options.
show_help() {
    echo -e "$0 --cmd COMMAND [--workdir DIR] [--update_cmd UPDATE_COMMAND] [--up_to_date_pattern PATTERN] [--sleep_time SLEEP_TIME]

Runs COMMAND.
Then repeatedly runs UPDATE_COMMAND every SLEEP_TIME and if the result of that check matches PATTERN, then COMMAND runs again.

WARNING: It can be dangerous to automate deployment using code you don't know on your own machine. It is recommended to run this in an isolated environment such as a Docker container.

--cmd COMMAND                 The command to execute when there are updates.

--workdir DIR                 The directory to work from. Defaults to \"${workdir}\".

--update_cmd UPDATE_COMMAND   The command to update the code. Defaults to Git pulling the current branch from origin.

--up_to_date_pattern PATTERN  The pattern to check for in the result of the UPDATE_COMMAND. If the pattern matches, then COMMAND runs. Defaults to \"${up_to_date_pattern}\".

--sleep_time SLEEP_TIME       The amount of time to wait between checks. This is passed to the \"sleep\" command. Defaults to \"${sleep_between_checks}\".
"
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
        show_help
        exit 0
        ;;
    --cmd|--command)
        deploy_cmd="$2"
        shift
        shift
        ;;
    --workdir)
        workdir="$2"
        shift
        shift
        ;;
    --sleep_time)
        sleep_between_checks="$2"
        shift
        shift
        ;;
    --update_cmd|--update_command)
        update_cmd="$2"
        shift
        shift
        ;;
    ----up_to_date_pattern)
        up_to_date_pattern="$2"
        shift
        shift
        ;;
    *)
        echo "Unrecognized option \"${key}\"" >&2
        show_help
        exit 1
        ;;
esac
done

pushd ${workdir}

if [[ ${deploy_cmd} == "" ]]; then
    echo "The deployment command was not set." >&2
    show_help
    exit 1
fi

if [[ ${update_cmd} == "" ]]; then
    # Default for Git.
    update_cmd="git pull origin `git rev-parse --abbrev-ref HEAD`"
fi

run() {
    set -x
    local deployment_pid
    deploy() {
        ${deploy_cmd} & deployment_pid=$! 
        echo "deploy: deployment_pid: ${deployment_pid}"
    }    

    check() {
        if ${update_cmd} | grep -E "${up_to_date_pattern}"; then
            echo "${up_to_date_pattern}"
        else
            echo "Not up to date."
            kill -9 ${deployment_pid}
            sleep 5
            deploy
        fi
    }

    ${update_cmd}
    deploy

    while true
    do
        sleep ${sleep_between_checks}
        check
    done
}

run
