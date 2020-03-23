#!/bin/bash
sudo service postgresql start
${APP}/db/snapshot/restore_db.sh
