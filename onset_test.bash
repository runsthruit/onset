#! /bin/bash

[ "TEST" == "${1:-}" ] || { "${BASH_SOURCE[0]}" TEST; ERR="${?}"; echo "[${ERR}]" 1>&2; exit ${ERR}; }

ONSET_ALLOW_SOURCED=1

. ./onset.bash

__onset_f_log

export TEST_NUM=0

msg ":${TEST_NUM}:" "%s\n" TEST
: $((TEST_NUM++))

printf "%s\n" TEST 1 2 3 |
	catmsg ":${TEST_NUM}:" "%s\n"
: $((TEST_NUM++))

catmsg ":${TEST_NUM}:" "%s\n" <( printf "%s\n" TEST 1 2 3 )
: $((TEST_NUM++))

sleep 3

false
