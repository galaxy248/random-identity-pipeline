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

root_path=$(_parent_dir $(readlink -f $0) 1)

mode=$(echo $(cat "$root_path/setting/running.mode") | xargs)
echo "d" > "$root_path/setting/running.mode"

bash $root_path/cronjob_controller/delete_from_cron.sh
bash $root_path/container_controller/stop_container.sh
bash $root_path/topics_controller/py_stop.sh

echo "$mode" > "$root_path/setting/running.mode"
