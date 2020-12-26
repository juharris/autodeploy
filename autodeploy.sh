#!/bin/bash

# Enable job control with -m so that the deployment can be stopped.
set -em

# Default options.
workdir=.

update_cmd=""
# Default for Git.
up_to_date_pattern="Already up.to.date"

deploy_cmd=""
stop_cmd="kill -9"
pass_pid_to_stop_cmd="true"

sleep_between_checks=10m
sleep_after_stop=5s

# Parse options.
show_help() {
    echo -e "$0 --cmd COMMAND [--workdir DIR] [--update_cmd UPDATE_COMMAND] [--up_to_date_pattern PATTERN]  [--stop_cmd STOP_COMMAND] [--no_pass_pid] [--sleep_time SLEEP_TIME] [--sleep_after_stop SLEEP_TIME]

Navigates to DIR.
Runs UPDATE_COMMAND.
Runs COMMAND.
Every SLEEP_TIME, runs UPDATE_COMMAND and if the output matches PATTERN, then COMMAND runs again.

WARNING: It can be dangerous to automate deployment using code you don't know on your own machine. It is recommended to run this in an isolated environment such as a Docker container.

--cmd COMMAND                 The command to execute when there are updates.

--workdir DIR                 The directory to work from. Defaults to \"${workdir}\".

--update_cmd UPDATE_COMMAND   The command to update the code. Defaults to Git pulling the current branch from origin.

--up_to_date_pattern PATTERN  The regex pattern used by grep to check for in the result of the UPDATE_COMMAND. If the pattern matches, then COMMAND runs. Defaults to \"${up_to_date_pattern}\".

--stop_cmd STOP_COMMAND       The command to stop the deployment. Takes the PID of COMMAND as a parameter. Defaults to \"${stop_cmd}\".

--no_pass_pid                 The PID of the COMMAND will not get passed to the STOP_COMMAND. Defaults to passing the PID to the STOP_COMMAND.

--sleep_time SLEEP_TIME       The amount of time to wait between checks. This is passed to the \"sleep\" command. Defaults to \"${sleep_between_checks}\".

--sleep_after_stop SLEEP_TIME       The amount of time to wait after stopping before running COMMAND again. This is passed to the \"sleep\" command. Defaults to \"${sleep_after_stop}\".
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
    --stop_cmd)
        stop_cmd="$2"
        shift
        shift
        ;;
    --no_pass_pid)
        pass_pid_to_stop_cmd="false"
        shift
        ;;
    --sleep_time)
        sleep_between_checks="$2"
        shift
        shift
        ;;
    --sleep_after_stop)
        sleep_after_stop="$2"
        shift
        shift
        ;;
    --update_cmd|--update_command)
        update_cmd="$2"
        shift
        shift
        ;;
    --up_to_date_pattern)
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
        if ${update_cmd} | grep -q -E "${up_to_date_pattern}"; then
            echo "Up to date."
        else
            echo "Not up to date."
            if [[ ${pass_pid_to_stop_cmd} == "true" ]]; then
                ${stop_cmd} ${deployment_pid}
            else
                ${stop_cmd}
            fi
            sleep ${sleep_after_stop}
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
