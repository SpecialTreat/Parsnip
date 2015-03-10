#!/bin/sh
# build.sh

GLOBAL_OUTDIR="$(dirname `pwd`)/Parsnip/Dependencies"
LOCAL_OUTDIR="./outdir"
ESCAPED_OUTDIR=$(echo $LOCAL_OUTDIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
LIBDIR="`pwd`/leptonica"

IOS_BASE_SDK="8.2"
IOS_DEPLOY_TGT="6.0"

declare -a archs=( "armv7"             "armv7s"             "arm64"              "i386"              "x86_64" )
declare -a hosts=( "arm-apple-darwin7" "arm-apple-darwin7s" "arm-apple-darwin64" "i386-apple-darwin" "x86_64-apple-darwin" )
declare -a plats=( "iPhoneOS"          "iPhoneOS"           "iPhoneOS"           "iPhoneSimulator"   "iPhoneSimulator" )
declare -a mvers=( "$IOS_DEPLOY_TGT"   "$IOS_DEPLOY_TGT"    "7.0"                "$IOS_DEPLOY_TGT"   "$IOS_DEPLOY_TGT" )

setenv_all()
{
    export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -I$GLOBAL_OUTDIR/include/libtiff -I$GLOBAL_OUTDIR/include/zlib"
    export CXX="$DEVROOT/usr/bin/clang++"
    export CC="$DEVROOT/usr/bin/clang"
    export LD=$DEVROOT/usr/bin/ld
    export AR=$DEVROOT/usr/bin/ar
    export AS=$DEVROOT/usr/bin/as
    export NM=$DEVROOT/usr/bin/nm
    export RANLIB=$DEVROOT/usr/bin/ranlib
    export LDFLAGS="-L$GLOBAL_OUTDIR/lib"
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS
}

cd $LIBDIR
rm -rf $LOCAL_OUTDIR

archCount=${#archs[@]}
for (( i=1; i<${archCount}+1; i++ ));
do
    arch=${archs[$i-1]}
    host=${hosts[$i-1]}
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

    ./configure --host=$host --enable-shared=no --disable-programs --without-libpng --without-jpeg --without-giflib --with-zlib=YES -with-libtiff=YES
    cp config.log config-$arch.log
    make -j4
    cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/$arch
done

for lib in `find src/.libs -name "lib*\.a"`; do
    cmd="xcrun -sdk iphoneos lipo "
    for arch in "${archs[@]}";
    do
        lib_arch=`echo $lib | sed "s/src\/\.libs/$ESCAPED_OUTDIR\/$arch/g"`
        cmd+="-arch $arch $lib_arch "
    done
    lib_out=`echo $lib | sed "s/src\/\.libs/$ESCAPED_OUTDIR/g"`
    cmd+="-create -output $lib_out"
    $($cmd)
done

mkdir -p $GLOBAL_OUTDIR/include/leptonica && cp -rvf src/*.h $GLOBAL_OUTDIR/include/leptonica
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib

#make clean 2> /dev/null
#make distclean 2> /dev/null
#rm -rf $LOCAL_OUTDIR
cd ..

echo "Done!"
