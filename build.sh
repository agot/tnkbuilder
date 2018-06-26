#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [-b branch] XOR [-t tag]" 1>&2
      exit 1
}

while getopts b:t:h OPT
do
  case $OPT in
    b)  BRANCH=$OPTARG
      ;;
    t)  TAG=$OPTARG
      ;;
    h)  usage
      ;;
  esac
done

# check
if [ -z "${BRANCH}" ] && [ -z "${TAG}" ]; then
  BRANCH=master
elif [ -n "${BRANCH}" ] && [ -n "${TAG}" ]; then
  usage
fi

DIR=$(dirname $(realpath $0))
SRC_DIR=src/

if [ ! -d "$SRC_DIR" ]; then
  git clone https://github.com/agot/tnkserv.git $SRC_DIR
fi

git -C $SRC_DIR fetch --tags
if [ -n "$BRANCH" ]; then
  git -C $SRC_DIR checkout $BRANCH
  git -C $SRC_DIR reset --hard origin/$BRANCH
  LABEL=branch-$BRANCH
elif [ -n "$TAG" ]; then
  git -C $SRC_DIR checkout $TAG
  git -C $SRC_DIR reset --hard $TAG
  LABEL=tag-$TAG
else
  exit 1
fi

docker build --tag tnkbuilder --label tnkbuilder=$LABEL --target build-env --build-arg SRC_DIR=$SRC_DIR --rm .
docker build --tag tnkserv-$LABEL --label tnkserv=$LABEL --target execute-env --build-arg SRC_DIR=$SRC_DIR --rm .

UNNECESSARY_IMAGES=$(docker images --quiet --filter "label=tnkbuilder" --filter "before=tnkbuilder:latest")
if [ -n "$UNNECESSARY_IMAGES" ]; then
  docker rmi $UNNECESSARY_IMAGES
fi
UNNECESSARY_IMAGES=$(docker images --quiet --filter "label=tnkserv=$LABEL" --filter "before=tnkserv-$LABEL:latest")
if [ -n "$UNNECESSARY_IMAGES" ]; then
  docker rmi $UNNECESSARY_IMAGES
fi
