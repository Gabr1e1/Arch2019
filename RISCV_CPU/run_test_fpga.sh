#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ./testcase/$@.in ]; then cp ./testcase/$@.in ./test/test.in; fi
# copy test output
if [ -f ./testcase/$@.ans ]; then cp ./testcase/$@.ans ./test/test.ans; fi

./ctrl/build.sh
# ./ctrl/run.sh ./test/test.bin ./test/test.in /dev/ttyS4 -I
./ctrl/run.sh ./test/test.bin ./test/test.in /dev/ttyS4 -T > ./test/test.out
if [ -f ./test/test.ans ]; then diff ./test/test.ans ./test/test.out; fi