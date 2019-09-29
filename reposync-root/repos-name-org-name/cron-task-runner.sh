#!/bin/bash

# Exit when the previous sync is processing
mypid=$(ps -ef | grep /repo/sync-repo.sh | grep -v grep)
if [[ "x${mypid}" != "x" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Previous synchroizing is still running ... "
    exit 0;
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Start syncing repo ..."
/repo/sync-repo.sh > >(tee /repo/sync-repo-error.log 2>&1) 2>&1 >/repo/sync-repo.log
echo "$(date '+%Y-%m-%d %H:%M:%S') End syncing repo."

