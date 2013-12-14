#!/bin/sh


BUILD_NUMBER=$((TRAVIS_JOB_ID - 1))
BUILD_APP="CopyMate.app"
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" "CopyMate/CopyMate-Info.plist")
BUILD_ZIP="$BUILD_APP-$BUILD_VERSION.$BUILD_NUMBER.zip"
BUILD_DYSM="$BUILD_APP-$BUILD_VERSION.$BUILD_NUMBER.dSYM.zip"
BUILD_RELEASE_PATH="./build/Release"

INDEX_HTML=$(cat <<EOF
<html>
<p>Download latest build:<a href="https://dn-copymate.qbox.me/$BUILD_ZIP">$BUILD_ZIP</a></p>
</html>
EOF)
INDEX_HTML_FILE="./errno-404"

echo $INDEX_HTML > $INDEX_HTML_FILE

pushd $BUILD_RELEASE_PATH
zip -r $BUILD_ZIP "CopyMate.app"
zip -r $BUILD_DYSM "CopyMate.app.dSYM"
popd

./scripts/upload-and-notify.py $QINIU_APP_KEY $QINIU_APP_SECRET $BUILD_RELEASE_PATH/$BUILD_ZIP && ./scripts/upload-and-notify.py $QINIU_APP_KEY $QINIU_APP_SECRET $INDEX_HTML_FILE
./scripts/upload-and-notify.py $QINIU_APP_KEY $QINIU_APP_SECRET $BUILD_RELEASE_PATH/$BUILD_DYSM
