#!/bin/bash
_parent_dir () {
    path=$1
    depth=${2:-1}
    while [ $depth -ne 0 ]; do
        path=$(dirname $path)
        depth=$(($depth - 1))
    done
    echo $path
    return 0
}

root_path=$(_parent_dir $(readlink -f $0) 2)

_can_execute () {
    if [ -f "$root_path/setting/running.mode" ]; then
        if [ $(echo $(cat "$root_path/setting/running.mode") | xargs) = "p" ]; then
            echo "you are in production mode and can not execute this script\nplease first run > ../stop.sh and then run app with '-m d' flag to running app in development mode  > ../run_app.sh -m d"
            exit 1
        fi
    else
        echo "please run app with ./run_app.sh"
        exit 1
    fi
}

_can_execute

for file_name in add_info.py add_ts.py add_to_db.py; do
	for pid in $(
		ps -ax -o pid,command | 
		grep "$root_path/topics/$file_name" | 
		grep -v "grep" | 
		awk '{print $1}'
	); do
		sudo kill -9 $pid
		bash $root_path/logger/log.sh "process killed [$pid]" -t -m t
	done
done
