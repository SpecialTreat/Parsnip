#!/bin/sh
# build.sh

GLOBAL_OUTDIR="$(dirname `pwd`)/Parsnip/Dependencies"
LOCAL_OUTDIR="./outdir"
ESCAPED_OUTDIR=$(echo $LOCAL_OUTDIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
LIBDIR="`pwd`/zlib"

IOS_BASE_SDK="8.2"
IOS_DEPLOY_TGT="6.0"

declare -a archs=( "armv7"             "armv7s"             "arm64"              "i386"              "x86_64" )
declare -a is64s=( ""                  ""                   "--64"               ""                  "--64" )
declare -a plats=( "iPhoneOS"          "iPhoneOS"           "iPhoneOS"           "iPhoneSimulator"   "iPhoneSimulator" )
declare -a mvers=( "$IOS_DEPLOY_TGT"   "$IOS_DEPLOY_TGT"    "7.0"                "$IOS_DEPLOY_TGT"   "$IOS_DEPLOY_TGT" )

setenv_all()
{
    export CXX="$DEVROOT/usr/bin/clang++"
    export CC="$DEVROOT/usr/bin/clang"
    export LD=$DEVROOT/usr/bin/ld
    export AR=$DEVROOT/usr/bin/ar
    export AS=$DEVROOT/usr/bin/as
    export NM=$DEVROOT/usr/bin/nm
    export RANLIB=$DEVROOT/usr/bin/ranlib
    export LDFLAGS=""
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS
}

cd $LIBDIR
rm -rf $LOCAL_OUTDIR

archCount=${#archs[@]}
for (( i=1; i<${archCount}+1; i++ ));
do
    arch=${archs[$i-1]}
    is64=${is64s[$i-1]}
    plat=${plats[$i-1]}
    mver=${mvers[$i-1]}

    mkdir -p $LOCAL_OUTDIR/$arch

    make clean 2> /dev/null
    make distclean 2> /dev/null

    unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/$plat.platform/Developer/SDKs/$plat$IOS_BASE_SDK.sdk
    export CFLAGS="-arch $arch -pipe -no-cpp-precomp -isysroot $SDKROOT -stdlib=libc++ -miphoneos-version-min=$mver"

    setenv_all

    ./configure --static $is64 --archs="-arch $arch"
    cp configure.log config-$arch.log
    make -j4
    cp -rvf libz.a $LOCAL_OUTDIR/$arch
done

cmd="xcrun -sdk iphoneos lipo "
for arch in "${archs[@]}";
do
    cmd+="-arch $arch $LOCAL_OUTDIR/$arch/libz.a "
done
cmd+="-create -output $LOCAL_OUTDIR/libz.a"
$($cmd)

mkdir -p $GLOBAL_OUTDIR/include/zlib && cp -rvf *.h $GLOBAL_OUTDIR/include/zlib
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/libz.a $GLOBAL_OUTDIR/lib

#make clean 2> /dev/null
#make distclean 2> /dev/null
#rm -rf $LOCAL_OUTDIR
cd ..

echo "Done!"
