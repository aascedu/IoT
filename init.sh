#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <duration_in_minutes>"
    exit 1
fi

DURATION_MINUTES=$1
END_TIME=$(( $(date +%s) + DURATION_MINUTES*60 ))
echo $END_TIME
while [ $(date +%s) -lt $END_TIME ]; do
    killall ft_lock

    ft_lock >/dev/null 2>&1 &
    sleep 420   # 7 minutes
done