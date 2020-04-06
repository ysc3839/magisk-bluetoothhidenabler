#!/bin/bash
set -e

APK_NAME=MagiskRRO
OVERLAY_PATH=system/vendor/overlay

[ -z "${ANDROID_HOME}" ] && {
  # shellcheck disable=SC2016
  echo '$ANDROID_HOME not found!'
  exit 1
}

export PATH="${ANDROID_HOME}/build-tools/28.0.3:${PATH}"

pushd app
aapt package -M AndroidManifest.xml -S res/ \
  -I "${ANDROID_HOME}/platforms/android-28/android.jar" \
  -F overlay.apk.u

keytool -genkey -v -keystore key.keystore -storepass android -keypass android -alias androidkey -dname "CN=Android,O=Android,C=US"
jarsigner -keystore key.keystore -storepass android -keypass android overlay.apk.u androidkey

zipalign 4 overlay.apk.u "${APK_NAME}.apk"

mv "${APK_NAME}.apk" ..
popd

pushd magisk
mkdir -p "${OVERLAY_PATH}/${APK_NAME}/"
mv "../${APK_NAME}.apk" "${OVERLAY_PATH}/${APK_NAME}/"

find . -exec touch -d @0 -h {} +
find . -type d -exec chmod 0755 {} +
find . -type f -exec chmod 0644 {} +

version=$(grep -Po "version=\K.*" module.prop)
zip -r -y -9 "../magisk-${APK_NAME,,}-${version}.zip" .
popd
