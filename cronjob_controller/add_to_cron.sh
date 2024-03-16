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

bash $root_path/cronjob_controller/delete_from_cron.sh

bash $root_path/logger/log.sh "add [get_data.py] to crontab" -m f

(
	crontab -l
	echo "* * * * *  $root_path/.venv/bin/python3  $root_path/data_downloader/get_data.py 1>>/dev/null 2>>/dev/null"
	echo "5 * * * *  $root_path/bin/bash  $root_path/database/backup.sh 1>>/dev/null 2>>/dev/null"
) | crontab -
