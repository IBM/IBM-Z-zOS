#!/bin/env bash

export REPO_DIR=$(dirname $0)
export BUILD_DIR=$PWD

target=
[ $# -gt 0 ] && target=${1}

gmake -f $REPO_DIR/makefile $target
