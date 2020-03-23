#!/bin/bash
zcat $(dirname "$0")/covid19.sql.gz | psql -U postgres