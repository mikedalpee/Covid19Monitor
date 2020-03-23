#!/bin/bash

pgrep -f "puma.*3000" > /dev/null 2>&1

if [ $? -eq 0 ]
then
  exit 0
fi

source ${HOME}/.bash_profile
script_dir=$(dirname "$0")
log_dir=${script_dir}/../log
bundle exec puma 2>&1 >> `${script_dir}/save_file.sh ${log_dir}/puma_3000 log`&
