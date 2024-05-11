# Random People's Identity

![logo](https://i.imgur.com/wSNROh5.png)

This project is designed to download, process, and store random people's identities and was developed by Python, Kafka, and Postgres (also NocoDB).

We use randomuser.me API to download data and then use a series of Kafka consumers to add some information and finally, we store data in the Postgres database.

## Prerequisites

- Linux operating system (prefer Debian-based, because some commands in scripts is Debian-based os's)
- Docker
- Python >= 3.8

## Installation

update the packages list of your system:

```bash
sudo apt-get update
```

### Build the Project

1. make sure the initialize script is executable by `chmod a+x init.sh`. then run the script to install packages and set up settings.

    ```bash
    ./init.sh
    ```

### Run the Project

1. you can start the program by `run_app.sh`.
  
- make sure the script is executable!

## Project Tests

the project is tested on Github Codespace service and ran successfully.

## Repository Descriptions

### Folders

- `container_controller`:

  ---
  to up and down docker containers.

- `cronjob_controller`:

  ---
  to automating the program process. (we download data every minute from website)

- `data_downloader`:

  ---
  a python script to download data from website.

- `database`:

  ---
  an sql file to create database structure and a shell script to backup from database.

- `health`:

  ---
  to check health of servises.

- `logger`:

  ---
  logging modules.

- `nocodb`:

  ---
  python scripts to initilize NocoDB.

- `topics`:

  ---
  python scripts for each kafka consumer topics.

- `topics_controller`:

  ---
  to set up and down the kafka topics listeners.

### Files

- `init.sh`:

  ---
  to install all required apps, libraries and settings to run app successfully.

- `run_app.sh.sh` - `stop_app.sh`:

  ---
  to running and stop project.

## License

[MIT](https://choosealicense.com/licenses/mit/)
