#!/bin/bash 

kernel_dir="${PWD}"
rm .version
rm build.log
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G
export SUBARCH=arm64
export ARCH=arm64
export CLANG_PATH="$HOME/toolchains/boolx-clang/bin"
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=${CLANG_PATH}/aarch64-linux-gnu-
export CROSS_COMPILE=${CLANG_PATH}/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=${CLANG_PATH}/arm-linux-gnueabi-
# export DTC_EXT=dtc # we don needed it again
export CC=$HOME/toolchains/boolx-clang/bin/clang
CLANG_DIR="$HOME/toolchains/boolx-clang"
CLANG="${CLANG_DIR}/bin:$PATH"
CLANG_BIN="${CLANG}/bin/"
TARGET_IMAGE="Image.gz-dtb"
cpus=`expr $(nproc --all)`
objdir="${kernel_dir}/out"
CONFIGS="raphael_defconfig"

VER="V2.3-Parvez-DSP"
KERNEL_DIR=`pwd`
REPACK_DIR=$HOME/AnyKernel3
ZIP_MOVE=$HOME/Boolx
BASE_AK_VER="Bool-X-Raphael-"
DATE=`date +"%Y%m%d-%H%M"`
AK_VER="$BASE_AK_VER$VER"
ZIP_NAME="$AK_VER"-"$DATE"
TOOLCHAINS=$HOME/toolchains/boolx-clang
SAVEHERE=$HOME/toolchains
CONFIG=out/.config
KERNEL=out/arch/arm64/boot/Image.gz-dtb
DTBO=out/arch/arm64/boot/dtbo.img

#functions
function makeconfig() {
                PATH=${CLANG_BIN}:${PATH} \
                make -s -j${cpus} \
                LLVM=1 \
                LLVM_IAS=1 \
                CC="ccache clang" \
                CROSS_COMPILE="aarch64-linux-gnu-" \
                CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
                O="${objdir}" ${1}
}

function build() {
		PATH=${CLANG_BIN}:${PATH} \
		make -s -j${cpus} \
		LLVM=1 \
		LLVM_IAS=1 \
		CC="ccache clang" \
		CROSS_COMPILE="aarch64-linux-gnu-" \
		CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
		O="${objdir}" ${1} \
		KBUILD_BUILD_USER="OnettBoots" \
		KBUILD_BUILD_HOST="OpenELA" \
		dtbo.img
}

function create_out {
		echo
		git clone https://github.com/onettboots/boolx_anykernel.git $REPACK_DIR && mkdir $ZIP_MOVE
}
function clean_all {
		echo
		echo -e "${red}Cleaning Kernel Projects .... ${restore}"
		cd ${kernel_dir}
		make -s clean
		make -s -j${cpus} mrproper O=${objdir}
		rm -rf out
}
function make_config {
		echo
		makeconfig ${CONFIGS}
}
function make_boot {
		cp $KERNEL $REPACK_DIR && cp $DTBO $REPACK_DIR
}
function make_zip {
		cd $REPACK_DIR
		zip -r9 `echo $ZIP_NAME`.zip *
		mv  `echo $ZIP_NAME`*.zip $ZIP_MOVE
		cd $KERNEL_DIR
}

function upload()
{
curl bashupload.com -T $ZIP_NAME*.zip
}

function upload_boolx_action()
{
                ziped=$ZIP_MOVE/`echo $ZIP_NAME`.zip
		upl=$kernel_dir/upl.sh
		cd $kernel_dir
		#wget
		chmod +x $upl
		sed -i "4i\FILE_PATH=$ziped" $upl
		BUILDDATE=`date +"%Y-%m-%d"`
		sed -i '5i\CAPTION="* Build Date: '$BUILDDATE'' $upl
		sed -i '6i\* Kernel Version: v.4.14.356' $upl
		sed -i '7i\* KSU+NEXT: v.12604' $upl
		sed -i '8i\* SUSFS: v1.5.7' $upl
		sed -i '9i\* Type: DSP, Mi Thermal' $upl
		sed -i '10i\* Changes: https://github.com/onettboots/bool-x_xiaomi_raphael/commits/14-DSPcr' $upl
                sed -i '11i\* Clang: Boolx Clang 21.0.0"' $upl
                bash $upl
}

DATE_START=$(date +"%s")

echo -e "${green}"
echo "----------------------"
echo "Checking Toolchains:"
echo "----------------------"
echo -e "${restore}"

if [ -d $TOOLCHAINS ]; then
   echo -e "${green}"
   echo "Bool-x clang is ready..!!"
   echo -e "${restore}"
else
   echo -e "${red}"
   echo "Downloading toolchains.!!"
   while read -p "what your architecture (aarch64/x86)? " cchoice
do
case "$cchoice" in
	aarch64|Aarch64 )
		echo
		echo "Downloading Boolx-clang for Aarch64 host."
		wget https://github.com/onettboots/boolx-clang-build/releases/download/Boolx-21/boolx-clang21.tar.gz -P $SAVEHEREAdd commentMore actions
 		cd $SAVEHERE
		echo "Extracting Boolx Clang 21.0.0 to $HOME/toolchains/:"
 		tar -xf boolx-clang21.tar.gz
		break
		;;
	x86|X86 )
		echo
		echo "Downloading Boolx-clang for X86 host."
		git clone https://gitlab.com/onettboots/boolx-clang.git -b Clang-17.0_x86 $TOOLCHAINS
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
   echo -e "${restore}"
fi

echo -e "${green}"
echo "----------------------------------"
echo "Checking for Anykernel flashable:"
echo "----------------------------------"
echo -e "${restore}"


if [ -d $REPACK_DIR ] && [ -d $ZIP_MOVE ]; then
   echo -e "${green}"
   echo "Anykernel is ready skipping..!!"
   echo -e "${restore}"
else
   echo -e "${red}"
   echo "Adding Anykernel flashable.!!"
   create_out
   echo -e "${restore}"
fi

echo -e "${green}"
echo "------------------"
echo "CLEAN OPTIONS:"
echo "------------------"
while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
	    echo -e "${red}"
		clean_all
		echo -e "${restore}"
		echo -e "${green}"
		echo "All Cleaned now."
		echo -e "${restore}"
		break
		;;
	n|N )
		rm $KERNEL
		break
		;;
	* )
		echo -e "${red}"
		echo "Invalid try again!"
		echo -e "${restore}"
		;;
esac
done
echo -e "${restore}"

if [ -f $CONFIG ]; then
   echo -e "${green}"
   while read -p "Old config is exist do you want replace with new config ? (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		make_config
		echo
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
   echo -e "${restore}"
else
   echo -e "${green}"
   echo -e "${restore}"
fi

if [ -f $CONFIG ]; then
   echo -e "${green}"
   echo -e "${restore}"
else
   echo -e "${green}"
   echo "-------------------------------------"
   echo "Making Configs:"
   echo "-------------------------------------"
   echo -e "${restore}"
   echo -e "${red}"
   make_config
   echo -e "${restore}"
fi

echo -e "${green}"
echo "-----------------"
echo "Building Kernel:"
echo "-----------------"
echo -e "${restore}"

cd ${kernel_dir}
build ${TARGET_IMAGE}

function build_time {
   DATE_END=$(date +"%s")
   DIFF=$(($DATE_END - $DATE_START))
   echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
}

echo -e "${green}"
echo "----------------------"
echo "Checking output files"
echo "----------------------"
echo -e "${restore}"
sleep 3
    
if [ -f $KERNEL ]; then
   echo -e "${green}"
   echo "------------------------------------------"
   echo "Succesed Build, make flashable zip"
   echo "------------------------------------------"
   echo -e "${restore}"
   make_boot
   make_zip
   cd $ZIP_MOVE
   echo -e "${blink_red}"
   echo $ZIP_MOVE
   echo "------------------------------------------"
   echo $ZIP_NAME*.zip
   echo "------------------------------------------"
   echo -e "${restore}"
   build_time
   upload
   echo
else
   echo -e "${red}"
   echo "-------------------------------------"
   echo "Building failed, Fix it and rebuild...!!!"
   echo "-------------------------------------"
   echo -e "${restore}"
   build_time
fi

echo

rm -rf $upl
