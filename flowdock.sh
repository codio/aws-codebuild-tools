#!/usr/bin/env bash

set -x

json_escape () {
    printf '%s' "$1" | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

if [ ! -n "${FLOWDOCK_NOTIFY_TOKEN}" ]; then
  error 'Please specify the token property'
  exit 1
fi

if [[ CODEBUILD_BUILD_SUCCEEDING -ne 0 ]]; then
    RESULT="passed"
else
    RESULT="failed"
fi

export CODEBUILD_GIT_BRANCH=`git symbolic-ref HEAD --short 2>/dev/null`
if [ "$CODEBUILD_GIT_BRANCH" == "" ] ; then
  CODEBUILD_GIT_BRANCH=`git branch -a --contains HEAD | sed -n 2p | awk '{ printf $1 }'`
  export CODEBUILD_GIT_BRANCH=${CODEBUILD_GIT_BRANCH#remotes/origin/}
fi

export CODEBUILD_GIT_MESSAGE=`git log -1 --pretty=%B`
export CODEBUILD_GIT_AUTHOR=`git log -1 --pretty=%an`
export CODEBUILD_GIT_AUTHOR_EMAIL=`git log -1 --pretty=%ae`
export CODEBUILD_GIT_COMMIT=`git log -1 --pretty=%H`
export CODEBUILD_GIT_TAG=`git describe --tags --abbrev=0`

export CODEBUILD_PULL_REQUEST=false
if [[ $CODEBUILD_GIT_BRANCH == pr-* ]] ; then
  export CODEBUILD_PULL_REQUEST=${CODEBUILD_GIT_BRANCH#pr-}
fi

export CODEBUILD_PROJECT=${CODEBUILD_BUILD_ID%:$CODEBUILD_LOG_PATH}
export CODEBUILD_BUILD_URL=https://$AWS_DEFAULT_REGION.console.aws.amazon.com/codebuild/home?region=$AWS_DEFAULT_REGION#/builds/$CODEBUILD_BUILD_ID/view/new

SOURCE="CodeBuild"

BASENAME=$(basename "$CODEBUILD_SOURCE_REPO_URL")
APPLICATION=${BASENAME%.*}

SUBJECT="$APPLICATION: build of $CODEBUILD_GIT_BRANCH by $CODEBUILD_GIT_AUTHOR $RESULT."
GIT_MESSAGE=`json_escape $CODEBUILD_GIT_MESSAGE`
CONTENT="<p>Commit ID: $CODEBUILD_GIT_COMMIT. Message: $GIT_MESSAGE</p><pre></pre>"


FORMATTED_MESSAGE="{\"source\": \"$SOURCE\", \"from_address\": \"codebuildbot@codio.com\", \"subject\": \"$SUBJECT\", \"project\": \"$APPLICATION\", \"link\": \"$CODEBUILD_BUILD_URL\", \"content\": \"$CONTENT\"}"

API_URL="https://api.flowdock.com/v1/messages/team_inbox/$FLOWDOCK_NOTIFY_TOKEN"

COMMAND="curl -X POST -H \"Content-Type: application/json\" -d '$FORMATTED_MESSAGE' $API_URL"

eval "$COMMAND"