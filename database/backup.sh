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

if [ -f "$root_path/.env" ]; then
	set -o allexport && source "$root_path/.env" && set +o allexport
fi

docker exec postgres_anvari bash -c "pg_basebackup -U ${POSTGRES_USER:-random_user} -w -D /backup/standalone-"$(date +%Y-%m-%d_%T%H-%M)" -c fast -P -R"
