#!/bin/sh
# build.sh

GLOBAL_OUTDIR="`pwd`/../Parsnip/Dependencies"

cd zbar/iphone

xcodebuild clean
xcodebuild -target ZBarSDK

mkdir -p $GLOBAL_OUTDIR/include/libzbar && cp -Rvf build/Distribution-iphoneos/ZBarSDK/Headers/ZBarSDK/ $GLOBAL_OUTDIR/include/libzbar
mkdir -p $GLOBAL_OUTDIR/lib && cp -Rvf build/Distribution-iphoneos/ZBarSDK/lib*.a $GLOBAL_OUTDIR/lib

cd ../..

echo "Done!"
