#!/bin/sh
# build.sh

GLOBAL_OUTDIR="`pwd`/../Parsnip/Dependencies"
LOCAL_OUTDIR="./outdir"
LEPTON_LIB="`pwd`/leptonica"

IOS_BASE_SDK="7.0"
IOS_DEPLOY_TGT="5.0"

setenv_all()
{
	# Add internal libs
	export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -I$GLOBAL_OUTDIR/include/libtiff -L$GLOBAL_OUTDIR/lib"
	
	#export CXX="$DEVROOT/usr/bin/llvm-g++"
    export CXX="$DEVROOT/usr/bin/clang++"
    #export CC="$DEVROOT/usr/bin/llvm-gcc"
    export CC="$DEVROOT/usr/bin/clang"

	export LD=$DEVROOT/usr/bin/ld
	export AR=$DEVROOT/usr/bin/ar
	export AS=$DEVROOT/usr/bin/as
	export NM=$DEVROOT/usr/bin/nm
	export RANLIB=$DEVROOT/usr/bin/ranlib
	export LDFLAGS="-L$SDKROOT/usr/lib/ -L$GLOBAL_OUTDIR/lib"
    	
	export CPPFLAGS=$CFLAGS
	export CXXFLAGS=$CFLAGS
}

setenv_arm6()
{
	unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

	#export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
	#export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
	export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
	export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
	
	#export CFLAGS="-arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export CFLAGS="-arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -dead_strip -stdlib=libc++ -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

	setenv_all
}

setenv_arm7()
{
    unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

    #export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
    #export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_BASE_SDK.sdk

    #export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -dead_strip -stdlib=libc++ -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

    setenv_all
}

setenv_arm7s()
{
    unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

    #export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
    #export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_BASE_SDK.sdk

    #export CFLAGS="-arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export CFLAGS="-arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT -dead_strip -stdlib=libc++ -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

    setenv_all
}

setenv_arm64()
{
    unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

    #export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
    #export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
    export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_BASE_SDK.sdk

    #export CFLAGS="-arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=7.0 -I$SDKROOT/usr/include/"
    export CFLAGS="-arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT -dead_strip -stdlib=libc++ -miphoneos-version-min=7.0 -I$SDKROOT/usr/include/"

    setenv_all
}

setenv_i386()
{
	unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
	
	#export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
	#export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
	export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
	export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
	
	#export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"
    export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -dead_strip -stdlib=libc++ -miphoneos-version-min=$IOS_DEPLOY_TGT"

	setenv_all
}

create_outdir_lipo()
{
	for lib_i386 in `find $LOCAL_OUTDIR/i386 -name "lib*\.a"`; do
#		lib_arm6=`echo $lib_i386 | sed "s/i386/arm6/g"`
        lib_arm7=`echo $lib_i386 | sed "s/i386/arm7/g"`
        lib_arm7s=`echo $lib_i386 | sed "s/i386/arm7s/g"`
        lib_arm64=`echo $lib_i386 | sed "s/i386/arm64/g"`
		lib=`echo $lib_i386 | sed "s/i386\///g"`
#		lipo -arch armv6 $lib_arm6 -arch armv7 $lib_arm7 -arch i386 $lib_i386 -create -output $lib
#		lipo -arch armv7 $lib_arm7 -arch i386 $lib_i386 -create -output $lib
        xcrun -sdk iphoneos lipo -arch armv7 $lib_arm7 -arch armv7s $lib_arm7s -arch arm64 $lib_arm64 -arch i386 $lib_i386 -create -output $lib
	done
}

merge_libfiles()
{
	DIR=$1
	LIBNAME=$2
	
	cd $DIR
	for i in `find . -name "lib*.a"`; do
		$AR -x $i
	done
	$AR -r $LIBNAME *.o
	rm -rf *.o __*
	cd -
}


#######################
# LEPTONLIB
#######################
cd $LEPTON_LIB
rm -rf $LOCAL_OUTDIR
#mkdir -p $LOCAL_OUTDIR/arm6 $LOCAL_OUTDIR/arm7 $LOCAL_OUTDIR/i386
mkdir -p $LOCAL_OUTDIR/arm7 $LOCAL_OUTDIR/arm7s $LOCAL_OUTDIR/arm64 $LOCAL_OUTDIR/i386

#make clean 2> /dev/null
#make distclean 2> /dev/null
#setenv_arm6
#./configure --host=arm-apple-darwin6 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -with-libtiff=YES
##./configure --host=arm-apple-darwin6 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -without-libtiff
#make -j4
#cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/arm6

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_arm7
./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -with-libtiff=YES
#./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -without-libtiff
make -j4
cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/arm7

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_arm7s
./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -with-libtiff=YES
#./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -without-libtiff
make -j4
cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/arm7s

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_arm64
./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -with-libtiff=YES
#./configure --host=arm-apple-darwin7 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -without-libtiff
make -j4
cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/arm64

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_i386
./configure --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -with-libtiff=YES
#./configure --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib -without-libtiff
make -j4
cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/i386

create_outdir_lipo
mkdir -p $GLOBAL_OUTDIR/include/leptonica && cp -rvf src/*.h $GLOBAL_OUTDIR/include/leptonica
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib


#make clean 2> /dev/null
#make distclean 2> /dev/null
#rm -rf $LOCAL_OUTDIR
cd ..

echo "Done!"
