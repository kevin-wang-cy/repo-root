#!/bin/bash

# Start ssh-agent
ps -ef | grep ssh-agent | grep -v grep || eval $(ssh-agent)

# Sync Repo every 15 minutes
echo "*/15 * * * * /repo/cron-task-runner.sh 2>&1 >>/repo/cron-task-runner.log" | crontab -
