# autodeploy
A simple tool with minimal dependencies to simplify automated deployment.
This has been tested in Git Bash on Windows.
It should work on Linux too.

This code uses **polling** because more elegant solutions such as setting up hooks on the repo and sending a push notification to a server are complicated to set up for simple tasks, you might not have permission to set up these hooks, you don't have permission to open up the server publicly, etc.

WARNING: It can be dangerous to automate deployment using code you don't know on your own machine.
It is recommended to run this in an isolated environment such as a Docker container.

<!-- TODO Add installation instructions. -->

# Usage
    ./autodeploy.sh --cmd COMMAND [--workdir DIR] [--update_cmd UPDATE_COMMAND] [--up_to_date_pattern PATTERN] [--sleep_time SLEEP_TIME]

Runs COMMAND.
Then repeatedly runs UPDATE_COMMAND every SLEEP_TIME and if the result of that check matches PATTERN, then COMMAND runs again.

| Parameter | Description |
| - | - |
| --cmd COMMAND | The command to execute when there are updates. |
| --workdir DIR | The directory to work from. Defaults to ".". |
| --update_cmd UPDATE_COMMAND  | The command to update the code. Defaults to Git pulling the current branch from origin. |
| --up_to_date_pattern PATTERN | The pattern to check for in the result of the UPDATE_COMMAND. If the pattern matches, then COMMAND runs. Defaults to "Already up-to-date". |
| --sleep_time SLEEP_TIME | The amount of time to wait between checks. This is passed to the "sleep" command. Defaults to "10m". |
