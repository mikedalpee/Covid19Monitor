#!/bin/bash

MITMDUMP_PORT=5565

pkill -int -f "mitmdump.*${MITMDUMP_PORT}"