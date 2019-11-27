#!/usr/bin/env bash

# Sciprt for cronjob, will open an issue on cdnjs/cdnjs if build failed.

StartTimestamp="$(date +%s)"

pth="$(dirname "$(readlink -f "$0")")"

cat "$pth/banner"

. "$pth/config.sh"

export PATH="$path:$PATH"

if [ "$(uname)" = "FreeBSD" ] || [ "$(uname)" = "Darwin" ]; then
  sed="gsed"
else
  sed="sed"
fi

apiUrl='https://api.github.com/repos/cdnjs/cdnjs/issues'

IssueTitle="[Build failed] Got error while building meta data/artifact"
IssueAssignee="robocdnjs"
IssueLabels='["Bug - High Priority"]'
IssueContent="$($sed ':a;N;$!ba;s/\n/\\n/g' "$pth/issueTemplate")"

Issue="{ \"title\": \"$IssueTitle\", \"body\": \"$IssueContent\", \"assignee\": \"$IssueAssignee\", \"labels\": $IssueLabels }"

flock -E 87 -n build.lock -c "$pth/update-website.sh build"

error=$?

if [ $error -eq 87 ]; then
  echo -e "\\nPrevious build locked!\\n"
elif [ $error -ne 0 ]; then
  curl --silent -H "Authorization: token $githubToken" -d "$Issue" "$apiUrl" > /dev/null
fi

EndTimestamp="$(date +%s)"

echo -e "\\nTotal time spent for this build is _$((EndTimestamp - StartTimestamp))_ second(s)\\n"
exit $error
