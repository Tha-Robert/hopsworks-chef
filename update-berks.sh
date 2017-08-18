#!/bin/bash

BERKSFILE=${BERKSFILE:-./Berksfile}

HOPS_ONLY=${HOPS_ONLY:-1}

set -x
set -e

function get_sha () {
	local repo="$1"
	local branch="$2"
	sh -c "curl -s $GITHUB_AUTH https://api.github.com/repos/$repo/branches/$branch | jq -r '.commit.sha'"
}


if [ "$HOPS_ONLY" == "1" ]; then
	COOKBOOKS=$(grep hopshadoop $BERKSFILE | grep "branch:" | grep -v "^[ \t]*#")
else
	COOKBOOKS=$(grep "github:" $BERKSFILE | grep "branch:" | grep -v "^[ \t]*#")
fi

IFS="
"
for book in $COOKBOOKS; 
do
	echo $book
	while IFS='"' read -r d git_repo d2 branch; do
		echo $git_repo 
		echo $branch
		GIT_REF=$(get_sha $git_repo $branch)
		if [ $GIT_REF == "null" ]; then
			echo "Something whent wrong with getting git reference, check rate limit or url to github"
			echo "You can use login with GITHUB_AUTH='--user="username:password"' for github"
			exit 1
		fi
	done <<<"$book"

	START_ROW="$(sed -E 's|(.*)branch:.*|\1|' <<<"$book")"
	
	echo "'$START_ROW'"

	if [ "$START_ROW" != "$book" ]; then
		echo sed -i "s|$book|${START_ROW}ref:\"$GIT_REF\"\n# $book|" $BERKSFILE
		sed -i "s|$book|${START_ROW}ref:\"$GIT_REF\"\n# $book|" $BERKSFILE
	fi
done
