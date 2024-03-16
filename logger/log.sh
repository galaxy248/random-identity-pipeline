#! /bin/bash
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

_save_log () {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" >> $root_path/log/info.log
}

_save_table_log () {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S"): \n$1" >> $root_path/log/info.log
}

_print_log () {
    size=${#1}
    
    printf "*"
    printf "%.s-" $(seq 1 $size)
    printf "*"

    printf "\n"

    printf "|%s|" "$1"

    printf "\n"

    printf "*"
    printf "%.s-" $(seq 1 $size)
    printf "*"

    printf "\n"
}

_print_table_log () {
    echo -e "$1"
}


root_path=$(_parent_dir $(readlink -f $0) 2)

log_text=$1

shift

mode="b"
table=0

while [ -n "$1" ]; do
    case $1 in
    -m | --mode)
        shift
        if [ -n "$1" ]; then
            case "$1" in
                "f")
                    mode="f"
                    ;;
                "t")
                    mode="t"
                    ;;
                "b")
                    mode="b"
                    ;;
                *)
                    echo "unknown value for -m flag. expected values: f[ile] t[erminal] b[oth]"
                    exit 1
                    ;;
            esac
        else
            echo "you should pass a value for -m flag."
            exit 1
        fi
        shift
        ;;
    -t | --table)
        table=1
        shift
        ;;
    *) echo "unknown flag"
        exit 1
        ;;
    esac
done

case $mode in
    "b")
        if [ $table -eq 0 ]; then
            _save_log "$log_text"
            _print_log "$log_text"
        else
            _save_table_log "$log_text"
            _print_table_log "$log_text"
        fi
        ;;
    "t")
        if [ $table -eq 0 ]; then
            _print_log "$log_text"
        else
            _print_table_log "$log_text"
        fi
        ;;
    "f")
        if [ $table -eq 0 ]; then
            _save_log "$log_text"
        else
            _save_table_log "$log_text"
        fi
        ;;
esac
