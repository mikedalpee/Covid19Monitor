#!/bin/bash

pgrep -f "puma.*${PUMA_PORT}" > /dev/null 2>&1

if [ $? -eq 0 ]
then
  exit 0
fi

pushd ./ > /dev/null
cd ${RAILS_APP_HOME}/script > /dev/null
bundle exec rails s 2>&1 >> `$(dirname "$0")/save_file.sh /var/log/puma_${PUMA_PORT} log`&
popd > /dev/null
