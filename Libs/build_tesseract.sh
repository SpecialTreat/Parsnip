# !/bin/sh
# build.sh

GLOBAL_OUTDIR="$(dirname `pwd`)/Parsnip/Dependencies"
LOCAL_OUTDIR="./outdir"
ESCAPED_OUTDIR=$(echo $LOCAL_OUTDIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
LIBDIR="`pwd`/tesseract"

IOS_BASE_SDK="8.2"
IOS_DEPLOY_TGT="6.0"

declare -a archs=( "armv7"             "arm64"              "i386"              "x86_64" )
declare -a hosts=( "arm-apple-darwin7" "arm-apple-darwin64" "i386-apple-darwin" "x86_64-apple-darwin" )
declare -a plats=( "iPhoneOS"          "iPhoneOS"           "iPhoneSimulator"   "iPhoneSimulator" )
declare -a mvers=( "$IOS_DEPLOY_TGT"   "7.0"                "$IOS_DEPLOY_TGT"   "$IOS_DEPLOY_TGT" )

setenv_all()
{
    export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -I$GLOBAL_OUTDIR/include/leptonica"
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
    export LIBS="-llept"
    export LIBLEPT_HEADERSDIR="$GLOBAL_OUTDIR/include/leptonica"
}

merge_libfiles()
{
    DIR=$1
    LIBNAME=$2

    cd $DIR
    for tobemerged in `find . -name "lib*.a"`; do
        $AR -x $tobemerged
    done
    $AR -r $LIBNAME *.o
    rm -rf *.o __*
    cd -
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

    echo $arch

    mkdir -p $LOCAL_OUTDIR/$arch

    make clean 2> /dev/null
    make distclean 2> /dev/null

    unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/$plat.platform/Developer/SDKs/$plat$IOS_BASE_SDK.sdk
    export CFLAGS="-arch $arch -pipe -no-cpp-precomp -isysroot $SDKROOT -stdlib=libc++ -miphoneos-version-min=$mver"

    setenv_all

    ./configure --host=$host --enable-shared=no
    cp config.log config-$arch.log
    make -j4
    for libfile in `find ./*/.libs -name "lib*.a"`;
    do
        cp -rvf $libfile $LOCAL_OUTDIR/$arch;
    done
    merge_libfiles $LOCAL_OUTDIR/$arch libtesseract_all.a
done

firstarch=${archs[0]}
ESCAPED_SRCDIR=$(echo $LOCAL_OUTDIR/$firstarch | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
for lib in `find $LOCAL_OUTDIR/$firstarch -name "lib*\.a"`;
do
    cmd="xcrun -sdk iphoneos lipo "
    for arch in "${archs[@]}";
    do
        lib_arch=`echo $lib | sed "s/$ESCAPED_SRCDIR/$ESCAPED_OUTDIR\/$arch/g"`
        cmd+="-arch $arch $lib_arch "
    done
    lib_out=`echo $lib | sed "s/$ESCAPED_SRCDIR/$ESCAPED_OUTDIR/g"`
    cmd+="-create -output $lib_out"
    $($cmd)
done

mkdir -p $GLOBAL_OUTDIR/include/tesseract
tess_inc=( api/apitypes.h api/baseapi.h ccmain/thresholder.h ccmain/pageiterator.h
           ccmain/resultiterator.h ccmain/ltrresultiterator.h ccstruct/publictypes.h ccutil/errcode.h
           ccutil/genericvector.h ccutil/helpers.h ccutil/host.h ccutil/ndminx.h ccutil/ocrclass.h
           ccutil/platform.h ccutil/tesscallback.h ccutil/memry.h ccutil/serialis.h
           ccutil/strngs.h ccutil/unichar.h ccutil/unicharmap.h ccutil/unicharset.h ccutil/fileerr.h
           ccutil/params.h )
for i in "${tess_inc[@]}"; do
   cp -rvf $i $GLOBAL_OUTDIR/include/tesseract
done
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib

#make clean 2> /dev/null
#make distclean 2> /dev/null
#rm -rf $LOCAL_OUTDIR
cd ..

echo "Done!"
