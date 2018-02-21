#!/usr/bin/env bash

set -x

if [ ! -n "${FLOWDOCK_NOTIFY_TOKEN}" ]; then
  error 'Please specify the token property'
  exit 1
fi

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
if [[ CODEBUILD_BUILD_SUCCEEDING -ne 0 ]]; then
    RESULT="passed"
else
    RESULT="failed"
fi

git branch

COMMIT_ID=$(git rev-parse HEAD)

SOURCE="CodeBuild"

BASENAME=$(basename "$CODEBUILD_SOURCE_REPO_URL")
APPLICATION=${BASENAME%.*}

LINK="https://console.aws.amazon.com/codebuild/home?region=us-east-1#/builds/$CODEBUILD_BUILD_ID/view/new"
SUBJECT="$APPLICATION: build of $BRANCH $RESULT."
CONTENT="<p>$SUBJECT</p><p>Commit ID: $COMMIT_ID. Message:</p><pre>$STEP_MESSAGE</pre>"


FORMATTED_MESSAGE="{\"source\": \"$SOURCE\", \"from_address\": \"codebuildbot@codio.com\", \"subject\": \"$SUBJECT\", \"project\": \"$APPLICATION\", \"link\": \"$LINK\", \"content\": \"$CONTENT\"}"

API_URL="https://api.flowdock.com/v1/messages/team_inbox/$FLOWDOCK_NOTIFY_TOKEN"

COMMAND="curl -X POST -H \"Content-Type: application/json\" -d '$FORMATTED_MESSAGE' $API_URL"

eval "$COMMAND"