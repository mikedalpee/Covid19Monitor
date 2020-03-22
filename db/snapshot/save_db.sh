#!/bin/bash
pg_dumpall -U postgres  | gzip -9 > covid19.sql.gz
