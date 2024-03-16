#!/bin/bash
if [ "$EUID" -eq 0 ];then
	echo -e "please run script without root user \n> ./init.sh -> correct\n> sudo ./init.sh -> not correct"
  	exit 1
fi

# read flags
mode="p"

while [ -n "$1" ]; do
    case $1 in
    -m | --mode)
        shift
        if [ -n "$1" ]; then
            case "$1" in
                "d" | "develop")
                    mode="d"
                    ;;
                "p" | "production")
                    mode="p"
                    ;;
                *)
                    echo "unknown value for -m flag. expected values: d[evelop] p[roduction]"
                    exit 1
                    ;;
            esac
        else
            echo "you should pass a value for -m flag."
            exit 1
        fi
        shift
        ;;
    *) echo "unknown flag"
        exit 1
        ;;
    esac
done


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

if [ -f "$root_path/setting/init.lock" ]; then
	if [ $(echo $(cat "$root_path/setting/init.lock") | xargs) -eq "0" ]; then
		echo "please run ./init.sh to initialize project settings"
		exit 1
	fi
else
	echo "please run ./init.sh to initialize project settings"
    exit 1
fi

# development vs production mode
bash $root_path/logger/log.sh "running app mode: $(if [ "$mode" = 'p' ]; then echo 'production'; else echo 'develop'; fi)"

if ! [ -f "$root_path/setting/running.mode" ]; then
    touch "$root_path/setting/running.mode"
fi

# first we run app in develop mode
echo "d" > "$root_path/setting/running.mode"


if [ -f "$root_path/.env" ]; then
	set -o allexport && source "$root_path/.env" && set +o allexport
fi

if ! grep -q "^\w\+:[[:digit:]]\+:[[:digit:]]\+\(,\w\+:[[:digit:]]\+:[[:digit:]]\+\)*$" <<< "${KAFKA_TOPICS:-add_ts:1:1,add_info:1:1,add_to_db:1:1}"; then
    bash $root_path/logger/log.sh "env variable [KAFKA_TOPICS] doesn't have correct pattern !"
    exit 1
fi

bash $root_path/stop_app.sh

bash $root_path/cronjob_controller/add_to_cron.sh
bash $root_path/container_controller/run_container.sh


bash $root_path/logger/log.sh "check kafka is ready or not"

source $root_path/.venv/bin/activate

python3 $root_path/health/kafka_health.py 1>/dev/null 2>&1

if [ "$?" -ne "0" ]; then
    bash $root_path/logger/log.sh "can not connect to kafka !"
    bash $root_path/stop_app.sh
    exit 1
fi

bash $root_path/logger/log.sh "kafka is ready"

deactivate


bash $root_path/logger/log.sh "check nocodb is ready or not"

counter=0
flag=0
while [ $counter -lt 30 ]; do
	if [ "$(curl -X GET -L -s -o /dev/null -I -w "%{http_code}" "http://localhost:${NOCODB_HOST_PORT:-8080}" 2>/dev/null)" -eq "200" ]; then
		sleep 1
        flag=1
		break
	fi
	counter=$(($counter + 1))
	sleep 1
done

if [ $flag -eq 0 ]; then
	bash $root_path/logger/log.sh "can not connect to nocodb"
	exit 1
fi

bash $root_path/logger/log.sh "nocodb is ready"

bash $root_path/logger/log.sh "run topics scripts"

nohup bash $root_path/topics_controller/py_runner.sh 1>/dev/null 2>&1

echo "$mode" > "$root_path/setting/running.mode"
