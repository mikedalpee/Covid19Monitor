#!/bin/bash

base=$1
ext=$2
file=$base.$ext

[ -f $file ] && mv $file `. $(dirname "$0")/next_file.sh $base $ext`

echo $file
