#!/usr/bin/env bash

base=$1
ext=$2
if [[ -e $base.$ext ]] ; then
    i=0
    while [[ -e $base.$i.$ext ]] ; do
        let i++
    done
    base=$base.$i
fi
echo "$base".$ext