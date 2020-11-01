# autodeploy
A simple tool with minimal dependencies to simplify automated deployment.
This has been tested in Git Bash on Windows and Linux (Ubuntu).

This code uses **polling** because more elegant solutions such as setting up hooks on the repo and sending a push notification to a server are complicated to set up for simple tasks, you might not have permission to set up these hooks, you don't have permission to open up the server publicly, etc.
Similary, cron jobs are very useful for many things but are not available on all platforms.

WARNING: It can be dangerous to automate deployment using code you don't know on your own machine.
It is recommended to run this in an isolated environment such as a Docker container.

# Installation
Save `autodeploy.sh` to somewhere in your PATH:

For example (in Git Bash):
```bash
mkdir --parents $HOME/bin
curl https://raw.githubusercontent.com/juharris/autodeploy/main/autodeploy.sh --output $HOME/bin/autodeploy
chmod ugo+x $HOME/bin/autodeploy
export PATH="$HOME/bin:$PATH"
echo -e '\nexport PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

Linux:

Assuming `/usr/bin` is in your PATH.
```bash
curl https://raw.githubusercontent.com/juharris/autodeploy/main/autodeploy.sh --output /usr/bin/autodeploy
chmod ugo+x /usr/bin/autodeploy
```

Test it:
```bash
autodeploy --help
```

# Usage
```bash
autodeploy --cmd COMMAND [--workdir DIR] [--update_cmd UPDATE_COMMAND] [--up_to_date_pattern PATTERN]  [--stop_cmd STOP_COMMAND] [--sleep_time SLEEP_TIME] [--sleep_after_stop SLEEP_TIME]
```

Navigates to DIR.

Runs UPDATE_COMMAND.

Runs COMMAND.

Every SLEEP_TIME, runs UPDATE_COMMAND and if the output matches PATTERN, then COMMAND runs again.

| Parameter | Description |
| - | - |
| --cmd COMMAND | The command to execute when there are updates. |
| --workdir DIR | The directory to work from. Defaults to ".". |
| --update_cmd UPDATE_COMMAND  | The command to update the code. Defaults to Git pulling the current branch from origin. |
| --up_to_date_pattern PATTERN | The regex pattern used by `grep` to check for in the result of the UPDATE_COMMAND. If the pattern matches, then COMMAND runs. Defaults to "Already up.to.date". |
| --stop_cmd STOP_COMMAND | The command to stop the deployment. Takes the PID of COMMAND as a parameter. Defaults to `kill -9`. |
| --sleep_time SLEEP_TIME | The amount of time to wait between checks. This is passed to the `sleep` command. Defaults to "10m". |
| --sleep_after_stop SLEEP_TIME | The amount of time to wait after stopping before running COMMAND again. This is passed to the `sleep` command. Defaults to "5s". |

# Examples

## Node App in a Git Repo
Keep your Node app up-to-date with the latest changes from GitHub (the defaults are made for `git` based projects):
```bash
git clone git@github.com:username/my-node-app.git
cd my-node-app
autodeploy --cmd 'npm run start'
```

## Docker Example
Check daily for updates to your Docker image (note that you might need `sudo` for your Docker commands):
```bash
autodeploy --cmd 'docker run --rm -d -p 5000:5000 --name container-name image-name:latest' --update_cmd 'docker pull image-name:latest' --up_to_date_pattern 'Status: Image is up to date for iamge-name:latest' --stop_cmd 'docker stop container-name' --sleep_time '1d'
```

## A Meta Example
Keep autodeploy up-to-date.

Set up a place for the script in your PATH:
```bash
mkdir --parents $HOME/bin
export PATH="$HOME/bin:$PATH"
echo -e '\nexport PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

Check for updates every 30 days:
```
git clone https://github.com/juharris/autodeploy.git
cd autodeploy
./autodeploy.sh --cmd "cp autodeploy.sh $HOME/bin/autodeploy" --sleep_time '30d'
```
