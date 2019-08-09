#!/usr/bin/env bash
set -eo pipefail
# . ./.cicd/helpers/general.sh
# . ./.cicd/helpers/execute.sh

export FULL_TAG="eosio/producer:eos-binaries-trav-poc-contract-tests-1.8.0-e13ec7f756e78d9baf994c5d3a7bd643653d834b"
export CDT_VERSION="1.6.2"

if [[ $(uname) == Darwin ]]; then

    cd $ROOT_DIR
    ccache -s
    mkdir -p build
    cd build
    execute cmake ..
    execute make -j$JOBS
    cd ..
    
else # Linux

    # . ./.cicd/helpers/docker.sh
    
    # Generate Base Images
    # execute ./.cicd/generate-base-images.sh
    [[ -z $CDT_VERSION ]] && echo "Please specify CDT_VERSION." && exit 1
    CDT_COMMANDS="curl -LO https://github.com/EOSIO/eosio.cdt/releases/download/v$CDT_VERSION/eosio.cdt_$CDT_VERSION-1-ubuntu-18.04_amd64.deb && dpkg -i eosio.cdt_$CDT_VERSION-1-ubuntu-18.04_amd64.deb && export PATH=/usr/opt/eosio.cdt/$CDT_VERSION/bin:$PATH"
    BUILD_COMMANDS="mkdir -p /workdir/build && cd /workdir/build && cmake -DCMAKE_CXX_COMPILER='clang++' -DCMAKE_C_COMPILER='clang' -DCMAKE_FRAMEWORK_PATH='/usr/local' .. && make -j 1"
    TEST_COMMANDS="cd /workdir/build/tests && ctest -j 1 -V --output-on-failure -T Test"

    # Docker Run Arguments
    ARGS=${ARGS:-"--rm -v $(pwd):/workdir"}
    # Docker Commands
    if [[ $BUILDKITE ]]; then
        append-to-commands $CDT_COMMANDS
        [[ $ENABLE_BUILD ]] && append-to-commands $BUILD_COMMANDS
        [[ $ENABLE_TEST ]] && append-to-commands $TEST_COMMANDS
        docker-run $COMMANDS
    elif [[ $TRAVIS ]]; then
        ARGS="$ARGS -e JOBS"
        TRAV_COMMANDS="ccache -s && $CDT_COMMANDS && $BUILD_COMMANDS && $TEST_COMMANDS"
        docker run $ARGS $FULL_TAG bash -c "curl -LO https://github.com/EOSIO/eosio.cdt/releases/download/v$CDT_VERSION/eosio.cdt_$CDT_VERSION-1-ubuntu-18.04_amd64.deb && dpkg -i eosio.cdt_$CDT_VERSION-1-ubuntu-18.04_amd64.deb && export PATH=/usr/opt/eosio.cdt/$CDT_VERSION/bin:$PATH && mkdir -p /workdir/build && cd /workdir/build && cmake -DCMAKE_CXX_COMPILER='clang++' -DCMAKE_C_COMPILER='clang' -DCMAKE_FRAMEWORK_PATH='/usr/local' .. && make -j 2 && cd /workdir/build/tests && ctest -j 2 -V --output-on-failure -T Test"
    fi
    # Docker Run

fi