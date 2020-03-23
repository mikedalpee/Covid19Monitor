#!/bin/bash
`$(dirname "$0")`/start_postgresql.sh
`$(dirname "$0")`/start_redis.sh
`$(dirname "$0")`/start_puma.sh
/bin/bash
