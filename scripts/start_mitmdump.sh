#!/bin/bash

script_dir=$(dirname "$0")
mitmdump_dir=${script_dir}/../mitmdump
MITMDUMP_PORT=5565

pgrep -f "mitmdump.*${MITMDUMP_PORT}" > /dev/null 2>&1

if [ $? -eq 0 ]
then
  exit 0
fi

mitmdump --listen-port=${MITMDUMP_PORT} --anticomp --flow-detail 3 -s ${mitmdump_dir}/inject.py 2>&1 >> `${script_dir}/save_file.sh ${mitmdump_dir}/mitmdump log`&
