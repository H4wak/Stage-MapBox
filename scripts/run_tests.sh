#!/usr/bin/env bash

set -e
set -o pipefail

if [ `uname -s` = 'Darwin' ]; then HOST=${HOST:-osx} ; else HOST=${HOST:-linux} ; fi

CMD=$1
shift

# allow writing core files
ulimit -c unlimited -S
echo 'ulimit -c: '`ulimit -c`
if [ -f /proc/sys/kernel/core_pattern ]; then
    echo '/proc/sys/kernel/core_pattern: '`cat /proc/sys/kernel/core_pattern`
fi

if [[ ${TRAVIS_OS_NAME} == "linux" ]]; then
    sysctl kernel.core_pattern
fi

# install test server dependencies
if [ ! -d "test/node_modules/express" ]; then
    (cd test; npm install express@4.11.1)
fi

RESULT=0
${CMD} "$@" || RESULT=$?

if [[ ${RESULT} != 0 ]]; then
    echo "The program crashed with exit code ${RESULT}. We're now trying to output the core dump."
fi

# output core dump if we got one
for DUMP in $(find ./ -maxdepth 1 -name 'core*' -print); do
    gdb ${CMD} ${DUMP} -ex "thread apply all bt" -ex "set pagination 0" -batch
    rm -rf ${DUMP}
done

# now we should present travis with the original
# error code so the run cleanly stops
if [[ ${RESULT} != 0 ]]; then
    exit $RESULT
fi
