#!/bin/bash
script_dir=$(dirname "$0")
${script_dir}/start_postgresql.sh
${script_dir}/start_redis.sh
${script_dir}/start_puma.sh
/bin/bash
