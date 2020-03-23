#!/bin/bash
pg_dumpall -U postgres --clean | gzip -9 > covid19.sql.gz
