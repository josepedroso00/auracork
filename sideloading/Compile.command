#!/bin/sh

cd "$(dirname "$0")"

error_exit()
{
           echo "${1:-"Unknown Error"}" 1>&2
           exit 1
}

rm -rf BCSymbolMaps
rm -rf Payload
rm -rf SwiftSupport
rm -rf Symbols

unzip KClientV60.ipa || error_exit "$LINENO: Error unzipping KClientV60.ipa"

rm -rf Payload/KClientV60.app/_CodeSignature/
rm -rf Payload/KClientV60.app/Frameworks/Charts.framework/_CodeSignature/
rm -rf Payload/KClientV60.app/Frameworks/ZXingObjC.framework/_CodeSignature/
mkdir build
rm build/*.*

/Applications/Xcode.app/Contents/Developer/usr/bin/actool Assets.xcassets --compile build --app-icon AppIcon --output-partial-info-plist build/partial.plist --platform iphoneos --minimum-deployment-target 11.0 || error_exit "$LINENO: Error compiling assets. Check if XCode and iOS SDK are installed."

cp -R KApp Payload/KClientV60.app/ || error_exit "$LINENO: Error copying KClient App files"
cp build/Assets.car Payload/KClientV60.app/Assets.car || error_exit "$LINENO: Error copying assets"
cp AppIcon/*.* Payload/KClientV60.app/ || error_exit "$LINENO: Error copying icon"
cp GoogleService-Info.plist Payload/KClientV60.app/GoogleService-Info.plist || error_exit "$LINENO: Error copying GoogleService-Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleName DesMold" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating bundle name in Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName DesMold" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating bundle display name in Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier auracork.com.auracork.GNPROD" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating bundle identifier in Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.0.1" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating bundle version in Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.1" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating bundle short version string in Info.plist"

/usr/libexec/PlistBuddy -c "Set :NSCameraUsageDescription 'CAMERA USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Camera usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSLocationWhenInUseUsageDescription 'LOCATION USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Location usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSMicrophoneUsageDescription 'MICROPHONE USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Microphone usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSMotionUsageDescription 'MOTION SENSOR USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Motion Sensor usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSPhotoLibraryUsageDescription 'PHOTO LIBRARY USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Photo Library usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSBluetoothPeripheralUsageDescription 'BLUETOOTH USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Bluetooth Peripheral usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSBluetoothAlwaysUsageDescription 'BLUETOOTH USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating Bluetooth Always Usage Description usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSSpeechRecognitionUsageDescription 'SPEECH RECOGNITION USAGE DESCRIPTION'" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating NS Speech Recognition Usage Description usage description in Info.plist"
/usr/libexec/PlistBuddy -c "Set :UIFileSharingEnabled false" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error updating File Sharing flag in Info.plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" Payload/KClientV60.app/Info.plist || error_exit "$LINENO: Error removing KClient Registered Url in Info.plist"
rm provision.plist
rm entitlementsDev.plist
security cms -D -i "DesMold_sideloading.mobileprovision" > provision.plist || error_exit "$LINENO: Error configuring mobile provision profile security"
/usr/libexec/PlistBuddy -x -c 'Print :Entitlements' provision.plist > entitlementsDev.plist || error_exit "$LINENO: Error updating entitlementsDev.plist with mobile provision profile"
sed -i '' '/<string>NDEF<\/string>/d' entitlementsDev.plist 2>/dev/null || true

cp "DesMold_sideloading.mobileprovision" Payload/KClientV60.app/embedded.mobileprovision || error_exit "$LINENO: Error copying mobile provision profile"

mv Payload/KClientV60.app Payload/DesMold.app || error_exit "$LINENO: Error renaming project folder"

SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -o '"[^"]*"' | head -1 | tr -d '"')
codesign -f -s "$SIGNING_IDENTITY" Payload/DesMold.app/Frameworks/* || error_exit "$LINENO: Error signing App frameworks"
codesign --entitlements entitlementsDev.plist -f -s "$SIGNING_IDENTITY" Payload/DesMold.app || error_exit "$LINENO: Error signing App"

zip -qr DesMold.ipa Payload/ || error_exit "$LINENO: Error zipping new App package"
echo "Compilation finished with success"
