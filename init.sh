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

if [ -f "$root_path/.env" ]; then
	set -o allexport && source "$root_path/.env" && set +o allexport
fi


bash $root_path/logger/log.sh "create folder structures and files"

sudo mkdir -p $root_path/data/backup
sudo mkdir -p $root_path/data/archive
sudo mkdir -p $root_path/data/nc_data
sudo mkdir -p $root_path/data/db_data

mkdir -p $root_path/log
mkdir -p $root_path/setting/nocodb

touch $root_path/log/error.log
touch $root_path/log/info.log

if [ -f "$root_path/setting/init.lock" ]; then
	if [ $(echo $(cat "$root_path/setting/init.lock") | xargs) -eq "1" ]; then
		echo "project initilizer already run and you can not run again."
		exit 1
	fi
else
	touch $root_path/setting/init.lock
	echo "0" > $root_path/setting/init.lock
fi


bash $root_path/logger/log.sh "project initializer started"


bash $root_path/logger/log.sh "permitting the files to execute"

_permiter () {
	f_name=$1
	extension=$3

	if [ -f $f_name ]; then
		sudo chmod a+x $f_name
	
	elif [ -d "$root_path/$f_name" ]; then
		if [ -z "$extension" ]; then
			echo "you should pass type of extension"
			exit 1
		else
			find "$root_path/$f_name" -type f -iname "*.$extension" | xargs chmod a+x
		fi

	else
		echo "you should pass the path of a shell or python script or a folder"
	fi
}


_permiter container_controller -e sh
_permiter cronjob_controller -e sh
_permiter logger -e sh
_permiter topics_controller -e sh
_permiter health -e sh
_permiter "$root_path/data_downloader/get_data.py"
_permiter "$root_path/run_app.sh"
_permiter "$root_path/stop_app.sh"
_permiter "$root_path/restart_app.sh"
_permiter "$root_path/database/backup.sh"


bash $root_path/logger/log.sh "check dependencies"

_check_dependency() {
	bash -c "$1 --version 1>/dev/null 2>&1"
	if [ $? -ne 0 ]; then
		if [ -z "$2" ]; then
			echo -e "$1 not installed."
			exit 127
		else
			echo -e "$1 not installed.\nTo install $1, $2"
			exit 127
		fi
	fi
}


bash $root_path/logger/log.sh "check dependency [docker]"
_check_dependency docker "please visit https://docs.docker.com/engine/install/"

bash $root_path/logger/log.sh "check dependency [python]"
_check_dependency python3 "please visit https://www.python.org/"

bash $root_path/logger/log.sh "check dependency [crontab]"
apt_update=0
bash -c "crontab --version 1>/dev/null 2>&1"
if [ $? -eq 127 ]; then
	echo "crontab not installed. please wait ..."
	sudo apt-get install -y cron
	if [ $? -ne 0 ]; then
		sudo apt-get update
		apt_update=1
		sudo apt-get install -y cron
		if [ $? -ne 0 ]; then
			echo "can not install cron package !"
			exit 1
		fi
	fi
fi
sudo systemctl start cron 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	sudo service cron start
	if [ $? -ne 0 ]; then
		echo "can not statrt crontab with systemctl and service !"
		exit 1
	fi
fi

sudo apt-get install -y libpq-dev
if [ $? -ne 0 ]; then
	if [ $apt_update -ne 1 ]; then
		sudo apt-get update
	fi
	sudo apt-get install -y libpq-dev
	if [ $? -ne 0 ]; then
		echo "can not install libpq-dev package !"
		exit 1
	fi
fi


bash $root_path/logger/log.sh "creating python venv"

if [ -d "$root_path/.venv" ]; then
	source $root_path/.venv/bin/activate
	if [ $? -ne 0 ]; then
		sudo chmod a+x $root_path/.venv/bin/activate
		if [ $? -ne 0 ]; then
			bash $root_path/logger/log.sh "can not permit essential permissions to python venv activator !" -m t
			exit 1
		fi
		
		source $root_path/.venv/bin/activate
		if [ $? -ne 0 ]; then
			bash $root_path/logger/log.sh "can not activate python venv" -m t
			exit 1
		fi

		pip install poetry==1.8.2
		if [ $? -eq 0 ]; then
			poetry shell
			if [ $? -ne 0 ]; then
				echo "poetry shell can not activate"
				exit 1
			fi
			bash $root_path/logger/log.sh "install libraries in python venv with poetry"
			poetry install --no-root
			if [ $? -ne 0 ]; then
				bash $root_path/logger/log.sh "poetry install packages error" -m t
				exit 1
			fi
		else
			bash $root_path/logger/log.sh "can not install poetry with pip !" -m t
			exit 1
		fi

	else
		pip install poetry==1.8.2
		if [ $? -eq 0 ]; then
			poetry shell
			if [ $? -ne 0 ]; then
				bash $root_path/logger/log.sh "poetry shell can not activate" -m t
				exit 1
			fi
			bash $root_path/logger/log.sh "install libraries in python venv with poetry"
			poetry install --no-root
			if [ $? -ne 0 ]; then
				bash $root_path/logger/log.sh "poetry install packages error" -m t
				exit 1
			fi
		else
			bash $root_path/logger/log.sh "can not install poetry with pip !" -m t
			exit 1
		fi
	fi
else
	python3 -m venv $root_path/.venv
	if [ $? -eq 0 ]; then
		sudo chmod a+x $root_path/.venv/bin/activate
		if [ $? -ne 0 ]; then
			exit 1
		fi
		
		source $root_path/.venv/bin/activate
		if [ $? -ne 0 ]; then
			exit 1
		fi

		pip install poetry==1.8.2
		if [ $? -eq 0 ]; then
			poetry shell
			if [ $? -ne 0 ]; then
				bash $root_path/logger/log.sh "poetry shell can not activate" -m t
				exit 1
			fi
			bash $root_path/logger/log.sh "install libraries in python venv with poetry"
			poetry install --no-root
			if [ $? -ne 0 ]; then
				echo "poetry install packages error"
				exit 1
			fi
		else
			echo "can not install poetry with pip !"
			exit 1
		fi
	else
		echo "can not create python virtual environment ! please wait..."
		sudo rm -rf $root_path/.venv
		sudo apt-get install -y python3-venv
		
		if [ $? -eq 0 ]; then
			sudo chmod a+x $root_path/.venv/bin/activate
			if [ $? -ne 0 ]; then
				exit 1
			fi
			
			source $root_path/.venv/bin/activate
			if [ $? -ne 0 ]; then
				exit 1
			fi

			pip install poetry==1.8.2
			if [ $? -eq 0 ]; then
				poetry shell
				if [ $? -ne 0 ]; then
					echo "poetry shell can not activate"
					exit 1
				fi
				bash $root_path/logger/log.sh "install libraries in python venv with poetry"
				poetry install --no-root
				if [ $? -ne 0 ]; then
					echo "poetry install packages error"
					exit 1
				fi
			else
				echo "can not install poetry with pip !"
				exit 1
			fi
		else
			echo "can not create python virtual environment !"
			exit 1
		fi
	fi
fi

bash $root_path/logger/log.sh "install libraries finished"


bash $root_path/logger/log.sh "nocodb loading ..."

docker compose -f $root_path/docker-compose.yml --profile=nocodb down
docker compose -f $root_path/docker-compose.yml --profile=nocodb up -d

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

bash $root_path/logger/log.sh "nocodb connect successfully"

python3 "$root_path/nocodb/create_base.py" 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "can not create base for nocodb service"
	docker compose -f $root_path/docker-compose.yml --profile=nocodb down
	exit 1
fi

python3 "$root_path/nocodb/create_table.py" 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "can not cretae table in nocodb service"
	docker compose -f $root_path/docker-compose.yml --profile=nocodb down
	exit 1
fi

docker compose -f $root_path/docker-compose.yml --profile=nocodb down

deactivate


# init database structure
docker compose -f $root_path/docker-compose.yml --profile=db down
docker compose -f $root_path/docker-compose.yml --profile=db up -d

bash $root_path/logger/log.sh "check database is ready or not"

counter=0
flag=0
while [ $counter -lt 30 ]; do
	bash -c "docker exec postgres_anvari pg_isready -U ${POSTGRES_USER:-random_user} -d ${POSTGRES_DB:-postgres} -h ${POSTGRES_HOST:-localhost} -q" 1>/dev/null 2>&1
	if [ $? -eq 0 ]; then
		bash $root_path/logger/log.sh 'Postgres database is ready'
		flag=1
		break
	else
		bash $root_path/logger/log.sh 'Postgres database is not ready' -m f
		sleep 1
	fi
	counter=$(($counter + 1))
done

if [ $flag -eq 0 ]; then
	bash $root_path/logger/log.sh "can not connect to database !"
	exit 1
fi

bash $root_path/logger/log.sh "database is ready"


bash $root_path/logger/log.sh "check schmea of database is correct or not"

counter=0
flag=0
while [ $counter -lt 30 ]; do	
	if [ $(docker exec postgres_anvari bash -c "psql -U random_user -d postgres -h localhost -c \"
		SELECT 1 AS flag
		FROM information_schema.TABLES AS t
		WHERE t.table_name = 'users' AND
      	t.table_schema = 'random_user';\" | grep -c '(1 row)'") -lt 1 ]; then
		docker exec postgres_anvari bash -c "psql -U ${POSTGRES_USER:-random_user} -d ${POSTGRES_DB:-postgres} -h ${POSTGRES_HOST:-localhost} < /code/init.sql >/dev/null 2>&1"
		sleep 1
	else
		flag=1
		break
	fi
	counter=$(($counter + 1))
done

if [ $flag -eq 0 ]; then
	bash $root_path/logger/log.sh "can not create [${POSTGRES_SCHEMA:-random_user}] schema and [users] table !"
	exit 1
fi

bash $root_path/logger/log.sh "schmea of database is correct"

bash $root_path/logger/log.sh "create backup..."

bash $root_path/database/backup.sh
if [ $? -ne 0 ]; then
	bash $root_path/logger/log.sh "backup enabling failed !"
	exit 1
fi

bash $root_path/logger/log.sh "create backup, successfully"


bash $root_path/logger/log.sh "add archive settings to database"
if ! [ $(
	docker exec postgres_anvari bash -c "cat /var/lib/postgresql/data/postgresql.conf" | 
	grep -c "^archive_mode = on$") -ge 1 ]; then

	docker exec postgres_anvari bash -c " echo -e \"
	wal_level = replica
	archive_mode = on
	archive_command = 'test ! -f /archive/%f && cp %p /archive/%f'\" >> /var/lib/postgresql/data/postgresql.conf"

	if [ $? -ne 0 ]; then
		bash $root_path/logger/log.sh "archive enabling failed !"
		exit 1
	fi
else
	bash $root_path/logger/log.sh "archive settings already added to database"
fi


docker compose -f $root_path/docker-compose.yml --profile=db down

# delete init file
# rm -- "$0"

echo "1" > $root_path/setting/init.lock
