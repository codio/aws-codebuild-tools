#!/usr/bin/env bash

set -x

if [ ! -n "${FLOWDOCK_NOTIFY_TOKEN}" ]; then
  error 'Please specify the token property'
  exit 1
fi

if [[ CODEBUILD_BUILD_SUCCEEDING -ne 0 ]]; then
    RESULT="passed"
else
    RESULT="failed"
fi

SOURCE="CodeBuild"

BASENAME=$(basename "$CODEBUILD_SOURCE_REPO_URL")
APPLICATION=${BASENAME%.*}

SUBJECT="$APPLICATION: build of $CODEBUILD_GIT_BRANCH by $CODEBUILD_GIT_AUTHOR $RESULT."
CONTENT="<p>$SUBJECT</p><p>Commit ID: $CODEBUILD_GIT_COMMIT. Message:</p><pre>$CODEBUILD_GIT_MESSAGE</pre>"


FORMATTED_MESSAGE="{\"source\": \"$SOURCE\", \"from_address\": \"codebuildbot@codio.com\", \"subject\": \"$SUBJECT\", \"project\": \"$APPLICATION\", \"link\": \"$CODEBUILD_BUILD_URL\", \"content\": \"$CONTENT\"}"

API_URL="https://api.flowdock.com/v1/messages/team_inbox/$FLOWDOCK_NOTIFY_TOKEN"

COMMAND="curl -X POST -H \"Content-Type: application/json\" -d '$FORMATTED_MESSAGE' $API_URL"

eval "$COMMAND"