#!/bin/bash

set -eo pipefail

ios_match_assure=false
deploy_store=false
deploy_fad=false

usage() {
  echo "Usage: $0 [--ios_match_assure] [--deploy_store] [--deploy_fad]"
}

get_build_number() {
  echo "#️⃣  Getting next build number"
  build_number=`node build_number.js`
  echo "#️⃣  Next build number: $build_number"
  build_number_string="--build-number=$build_number"
}

clean_and_install() {
  echo "🧹  Cleaning all"
  flutter clean
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
  flutter gen-l10n
}

if [ $# -eq 0 ]
  then
    usage
fi

while [ "$1" != "" ]; do
    case $1 in
        --ios_match_assure )      ios_match_assure=true
                                  ;;
        --deploy_store)           deploy_store=true
                                  ;;
        --deploy_fad )           deploy_fad=true
                                  ;;
        -h | --help )             usage
                                  exit 0
                                  ;;
        * )                      echo Unknown param $1
                                  ;;
    esac
    shift
done

if [ $ios_match_assure = true ]; then
  echo "📜  Making sure the iOS certificates and profiles are installed"

  fastlane ios match_assure
fi

if [ $deploy_store = true ]; then
  echo "🛒  Deploy to stores"

  clean_and_install
  get_build_number

  echo "🛒🏗️  Build IPA"
  flutter build ipa --release --export-options-plist ios/export_options_appstore.plist $build_number_string

  echo "🛒🏗️🤖  Build AAB"
  flutter build appbundle $build_number_string

  echo "🛒  Deploy IPA"
  fastlane ios deploy_testflight

  echo "🛒🤖  Deploy AAB"
  fastlane android deploy_google_play_internal

  echo "🛒  Deploy to stores done, build number $build_number"
fi

if [ $deploy_fad = true ]; then
  echo "🔥  Deploy to FAD"

  clean_and_install
  get_build_number

  echo "🔥🏗️  Build IPA"
  flutter build ipa --release --export-options-plist ios/export_options_adhoc.plist $build_number_string

  echo "🔥🏗️🤖  Build APK"
  flutter build apk $build_number_string

  echo "🔥  Deploy IPA"
  fastlane ios deploy_fad

  echo "🔥🤖  Deploy APK"
  fastlane android deploy_fad

  echo "🔥  Deploy to FAD done, build number $build_number"
fi

echo "🎉 All done!"


