#!/bin/sh

if [ -z "$TRAVIS_BUILD_NUMBER" ]
then
	TRAVIS_PULL_REQUEST="false"
fi

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
	echo "--- 🤖 CI Pipeline Started ---"
	echo "- Running Tests -"
	MODE="Debug"
	WORKSPACE=$(basename $(find . -name *.xcworkspace))
	DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.4'
	xcodebuild test -workspace "$WORKSPACE" -scheme "${WORKSPACE%%.*}Clip" -destination "$DESTINATION" -configuration "$MODE" | xcpretty
else
	echo "--- 🤖 CD Pipeline Started ---"
	echo "- 🏷 Updating GIT Tag -"
	FILE=$(find . -name *.podspec)
	NAME=$(awk '/\.name =/' $FILE | sed 's/.*"\(.*\)"/\1/g')
	VERSION=$(awk '/\.version/' $FILE | awk '/[0-9]\.[0-9]\.[0-9]/' | sed 's/.version//g' | sed 's/[^0-9/.]//g')
	TAG="${NAME}-v${VERSION}"
	git tag -a -f "${TAG}" -m "Pod version update" || true
	git push origin -v "refs/tags/${TAG}" || true

	echo "- 📦 Publishing version $VERSION -"
	pod trunk push "${FILE}" --allow-warnings
fi
