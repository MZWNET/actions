#!/bin/bash

# =============================================================================
# Xiaomi Mi Max 2 (Lineage OS 21 A14) Kernel Build Script
# Converted from GitHub Actions workflow
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# Environment Variables Configuration
# =============================================================================

# Device environment
export DEVICE_NAME="xiaomi_mimax2"
export DEVICE_CODENAME="oxygen"

export CUSTOM_CMDS="CLANG_TRIPLE=aarch64-linux-gnu-"
export EXTRA_CMDS="LD=ld.lld LLVM=1 LLVM_IAS=1"

export KERNEL_SOURCE="https://github.com/halibw/android_kernel_xiaomi_oxygen.git"
export KERNEL_BRANCH="lineage-21"

export CLANG_SOURCE="https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/LLVM-19.1.7-Linux-X64.tar.xz"
export CLANG_BRANCH=""

export GCC_GNU=false
export GCC_64_SOURCE="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.git"
export GCC_64_BRANCH="android12L-release"
export GCC_32_SOURCE="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9.git"
export GCC_32_BRANCH="android12L-release"

export DEFCONFIG_SOURCE=""
export DEFCONFIG_NAME="vendor/msm8953-perf_defconfig"
export DEFCONFIG_ORIGIN_IMAGE=""
export DEFCONFIG_FROM_BOOT=false

export KERNELSU_SOURCE="https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh"
export KERNELSU_BRANCH="d7b55bf8b1001592d06edf2dcc45de88649c6519"

export KERNELSU_AUTO_GET="false"
export KERNELSU_AUTO_FORK="sukisu"

export SUSFS_ENABLE=true
export SUSFS_FIXED=true
export SUSFS_UPDATE=true

export AK3_SOURCE="https://github.com/osm0sis/AnyKernel3.git"
export AK3_BRANCH="master"

export BOOT_SOURCE=""

export NEED_DTBO=false
export NEED_SAFE_DTBO=false

export ROM_TEXT="los21_a14_4.19"

# Other environment
export PYTHON_VERSION="3"
export PACK_METHOD="Anykernel3"
export KERNELSU_METHOD="shell"

export PATCHES_SOURCE="mzwing/NonGKI_Kernel_Patches"
export PATCHES_BRANCH="mi_kernel"

export SUSFS_FOLDER_FIXED="mimax2_msm8953"
export SUSFS_155_FIXED="susfs_155_fixed"
export SUSFS_LATEST_FIXED="susfs_157_fixed"

export REKERNEL_ENABLE="true"

export HOOK_METHOD="syscall"
export HOOK_OLDER="false"

export KPM_ENABLE="false"
export KPM_PATCH_SOURCE="https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU_patch/refs/heads/main/kpm/patch_linux"

export BASEBAND_GUARD_ENABLE="true"
export BASEBAND_GUARD_BOOT="false"

export HIDE_STUFF="true"

export GENERATE_DTB="false"
export GENERATE_CHIP="qcom"

export BUILD_DEBUGGER="false"
export SKIP_PATCH="false"

export BUILD_OTHER_CONFIG="false"
export MERGE_CONFIG_FILES="vendor/debugfs.config,vendor/lahaina_QGKI.config"

export FREE_MORE_SPACE="false"

# CCACHE environment
export CCACHE_COMPILERCHECK="%compiler% -dumpmachine; %compiler% -dumpversion"
export CCACHE_NOHASHDIR="true"
export CCACHE_HARDLINK="true"

# =============================================================================
# Utility Functions
# =============================================================================

# Function to display section headers
title() {
    echo -e "\033[1;36m"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                         $1                         ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "\033[1;36m"
}

# Function to display section footers
footer(){
    echo -e "\033[1;36m"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "\033[1;36m"
}

# Function to display context information
context() {
    echo -e "\033[0m $1: \033[1;37m$2\033[0m"
}

# Function to check system OS
check_system_os() {
    . /etc/os-release

    if [ "$ID" = "ubuntu" ]; then
        if [ "$VERSION_ID" = "20.04" ]; then
            export SYSTEM_VERSION="oldest"
        elif [ "$VERSION_ID" = "22.04" ]; then
            export SYSTEM_VERSION="older"
        elif [ "$VERSION_ID" = "24.04" ]; then
            export SYSTEM_VERSION="newer"
        else
            echo "❌ Not Supported: $VERSION_ID"
            exit 1
        fi
    elif [ "$ID" = "arch" ]; then
        export SYSTEM_VERSION="arch"
    else
        echo "❌ Not Supported: $PRETTY_NAME"
        exit 1
    fi
}

# =============================================================================
# Step 1: ⏰ Checkout repository
# =============================================================================

title "Step 1: ⏰ Checkout repository"
echo "检出仓库代码..."
# In a local environment, we assume the repository is already checked out
# If not, you would use: git clone <repository-url> -b <branch>
echo "假设代码已经检出到当前目录"
footer

# =============================================================================
# Step 2: ⌛️ Compilation environment preparation
# =============================================================================

title "Step 2: ⌛️ Compilation environment preparation"
echo "编译环境准备..."

# Output System OS
check_system_os

title "System Information"
context "OS" "$PRETTY_NAME"
context "User" "$(whoami)"
context "Current Folder" "$(pwd)"
context "Shell" "$SHELL"
footer

# Remove useless tools
if [ "$SYSTEM_VERSION" = "newer" ] || [ "$SYSTEM_VERSION" = "older" ]; then
    sudo rm -rf /opt/hostedtoolcache
    df -h
fi

# Move Patch and Tools
echo "移动补丁和工具文件..."
mv Patches /tmp/
mv Bin /tmp/
chmod 777 /tmp/Bin/curlx.sh
export CURLX=/tmp/Bin/curlx.sh
cp /tmp/Bin/found_gcc.sh ./

# Install necessary packages
echo "安装必要的软件包..."
if [ "$SYSTEM_VERSION" = "oldest" ]; then
    # Tzdata
    TZ=America/Los_Angeles
    sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone

    sudo apt-get update
    sudo apt-get install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler wget curl cpio -y
    sudo apt-get install p7zip p7zip-full -y
    sudo apt-get install libtinfo5 -y

    # Install Coccinelle
    if [[ "$HIDE_STUFF" = "true" ]]; then
        sudo apt-get install pkg-config ocaml-nox ocaml-findlib autoconf libpcre3-dev python3-dev menhir libparmap-ocaml-dev libpcre-ocaml-dev -y
        wget https://coccinelle.gitlabpages.inria.fr/website/distrib/coccinelle-1.3.tar.gz
        tar zxf coccinelle-1.3.tar.gz
        cd coccinelle-1.3
        ./autogen
        ./configure
        make
        sudo make install
        cd ..
    fi

    if [ "$PYTHON_VERSION" = "3" ]; then
        sudo apt install python3 -y
        sudo rm -rf /usr/bin/python
        sudo ln -s /usr/bin/python3 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 3 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    elif [ "$PYTHON_VERSION" = "2" ]; then
        sudo apt install python2 -y
        sudo rm -rf /usr/bin/python
        sudo ln -s /usr/bin/python2.7 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 2 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    else
        echo ">>>>>>>>>>>>>>>>>Error<<<<<<<<<<<<<<<<<"
        echo ">                                     <"
        echo ">You need choose a vaild python version"
        echo ">                                     <"
        echo ">>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
        exit 1
    fi

    echo "Python Version"
    echo ">$(python -V)"
    echo ">>EOF"

elif [ "$SYSTEM_VERSION" = "older" ]; then
    sudo apt-get update
    sudo apt-get install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler wget curl cpio -y
    sudo apt-get install p7zip p7zip-full -y
    sudo apt-get install libtinfo5 -y

    # Install Coccinelle
    if [[ "$HIDE_STUFF" = "true" ]]; then
        sudo apt-get install pkg-config ocaml-nox ocaml-findlib autoconf libpcre3-dev python3-dev menhir libparmap-ocaml-dev libpcre-ocaml-dev -y
        wget https://coccinelle.gitlabpages.inria.fr/website/distrib/coccinelle-1.3.tar.gz
        tar zxf coccinelle-1.3.tar.gz
        cd coccinelle-1.3
        ./autogen
        ./configure
        make
        sudo make install
        cd ..
    fi

    if [ "$PYTHON_VERSION" = "3" ]; then
        sudo apt install python3 -y
        sudo rm -rf /usr/bin/python
        sudo ln -s /usr/bin/python3 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 3 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    elif [ "$PYTHON_VERSION" = "2" ]; then
        sudo apt install python2 -y
        sudo rm -rf /usr/bin/python
        sudo ln -s /usr/bin/python2.7 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 2 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    else
        echo ">>>>>>>>>>>>>>>>>Error<<<<<<<<<<<<<<<<<"
        echo ">                                     <"
        echo ">You need choose a vaild python version"
        echo ">                                     <"
        echo ">>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
        exit 1
    fi

    echo "Python Version"
    echo ">"
    echo "$(python -V)"
    echo ">"
    echo ">EOF"

elif [ "$SYSTEM_VERSION" = "newer" ]; then
    sudo apt update
    sudo apt install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler cpio coccinelle -y
    sudo apt-get install zstd libc6 binutils libc6-dev-i386 gcc g++ p7zip p7zip-full -y

    # Install Libtinfo5
    $CURLX http://launchpadlibrarian.net/580830584/libtinfo5_6.3-2_amd64.deb libtinfo5.deb
    sudo apt install ./libtinfo5.deb
    rm -f libtinfo5.deb

    if [ "$PYTHON_VERSION" = "3" ]; then
        sudo apt install python3 -y
        sudo rm -rf /usr/bin/python
        sudo ln -s /usr/bin/python3 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 3 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    elif [ "$PYTHON_VERSION" = "2" ]; then
        wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
        tar -xvf Python-2.7.18.tgz
        cd Python-2.7.18
        ./configure
        make -j$(nproc)
        sudo make install
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
        sudo python2.7 get-pip.py
        sudo update-alternatives --install /usr/bin/python python /usr/local/lib/python2.7 1
        cd ../
        rm -rf Python-2.7.18 Python-2.7.18.tgz
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 2 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    else
        echo ">>>>>>>>>>>>>>>>>Error<<<<<<<<<<<<<<<<<"
        echo ">                                     <"
        echo ">You need choose a vaild python version"
        echo ">                                     <"
        echo ">>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
        exit 1
    fi

    echo "Python Version"
    echo ">"
    echo "$(python -V)"
    echo ">"
    echo ">EOF"

elif [ "$SYSTEM_VERSION" = "arch" ]; then
    pacman -Syyu --noconfirm
    pacman -S git base-devel systemd wget rustup curl patch ccache automake flex lzop bison gperf zip curl bzip2 squashfs-tools pngcrush schedtool make optipng maven pwgen minicom bc unzip 7zip zstd binutils gcc wget which libxml2-legacy cpio coccinelle --noconfirm

    if [ "$PYTHON_VERSION" = "3" ]; then
        pacman -S python3 --noconfirm
        rm -rf /usr/bin/python
        ln -s /usr/bin/python3 /usr/bin/python
        echo ">>>>>>><<<<<<<"
        echo ">            <"
        echo "> Python - 3 <"
        echo ">            <"
        echo ">>>>>>><<<<<<<"
    elif [ "$PYTHON_VERSION" = "2" ]; then
        echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"
        echo ">                              <"
        echo "> Could not supported Python 2 <"
        echo ">                              <"
        echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"
        exit 1
    else
        echo ">>>>>>>>>>>>>>>>>Error<<<<<<<<<<<<<<<<<"
        echo ">                                     <"
        echo ">You need choose a vaild python version"
        echo ">                                     <"
        echo ">>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<"
        exit 1
    fi

    echo "Python Version"
    echo ">"
    echo "$(python -V)"
    echo ">"
    echo ">EOF"

    # Update Rust Toolchain
    rustup default stable

else
    echo "❌ Your system os cannot supported."
    exit 1
fi

# Install GNU GCC
if [ "$GCC_GNU" = "true" ]; then
    echo "安装GNU GCC编译器..."
    if [ "$SYSTEM_VERSION" = "newer" ] || [ "$SYSTEM_VERSION" = "older" ] || [ "$SYSTEM_VERSION" = "oldest" ]; then
        sudo apt install binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu
        sudo apt install gcc-arm-linux-gnueabi -y
        export GCC_64="CROSS_COMPILE=aarch64-linux-gnu-"
        export GCC_32="CROSS_COMPILE_ARM32=arm-linux-gnueabi-"
    elif [ "$SYSTEM_VERSION" = "arch" ]; then
        pacman -S aarch64-linux-gnu-binutils aarch64-linux-gnu-gcc aarch64-linux-gnu-glibc aarch64-linux-gnu-linux-api-headers aarch64-linux-gnu-glibc --noconfirm
        pacman -S arm-none-eabi-binutils arm-none-eabi-gcc arm-none-eabi-newlib --noconfirm
        export GCC_64="CROSS_COMPILE=aarch64-linux-gnu-"
        export GCC_32="CROSS_COMPILE_ARM32=arm-none-eabi-"
    else
        echo "❌ Your system os cannot supported."
        exit 1
    fi
fi

# Set Compile Environment
echo "设置编译环境..."
cd .

# Set GCC
if [[ "$CLANG_SOURCE" == *"proton"* ]]; then
    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">   Detected Pronton Clang   <"
    echo ">     Needn't other GCC      <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
    export GCC_64="CROSS_COMPILE=aarch64-linux-gnu-"
    export GCC_32="CROSS_COMPILE_ARM32=arm-linux-gnueabi-"
elif [[ "$GCC_GNU" = "true" ]]; then
    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">      Detected GNU GCC      <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
elif [[ -z "$GCC_64_SOURCE" ]] && [[ -z "$GCC_32_SOURCE" ]]; then
    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">   Have not found any GCC   <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
elif [[ -n "$GCC_64_SOURCE" ]] && [[ -n "$GCC_32_SOURCE" ]]; then
    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">         Get GCC 64         <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
    if [[ "$GCC_64_SOURCE" == *".git" ]]; then
        git clone "$GCC_64_SOURCE" -b "$GCC_64_BRANCH" gcc-64 --depth=1
    elif [[ "$GCC_64_SOURCE" == *'.tar.gz' ]]; then
        $CURLX "$GCC_64_SOURCE" gcc-64.tar.gz
        mkdir gcc-64
        tar -C gcc-64/ -zxf gcc-64.tar.gz
    elif [[ "$GCC_64_SOURCE" == *'.tar.xz' ]]; then
        $CURLX "$GCC_64_SOURCE" gcc-64.tar.xz
        mkdir gcc-64
        tar -C gcc-64/ -xf gcc-64.tar.xz --strip-components=1
    elif [[ "$GCC_64_SOURCE" == *'.xz' ]]; then
        $CURLX "$GCC_64_SOURCE" gcc-64.xz
        mkdir gcc-64
        tar -C gcc-64/ -xf gcc-64.xz --strip-components=1
    elif [[ "$GCC_64_SOURCE" == *'.zip' ]]; then
        $CURLX "$GCC_64_SOURCE" gcc-64.zip
        mkdir gcc-64
        unzip gcc-64.zip -d gcc-64/
    else
        echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
        echo ">                            <"
        echo ">Please input vaild GCC link!<"
        echo ">                            <"
        echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
        exit 1
    fi
    bash found_gcc.sh GCC_64

    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">         Get GCC 32         <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
    if [[ "$GCC_32_SOURCE" == *".git" ]]; then
        git clone "$GCC_32_SOURCE" -b "$GCC_32_BRANCH" gcc-32 --depth=1
    elif [[ "$GCC_32_SOURCE" == *'.tar.gz' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.tar.gz
        mkdir gcc-32
        tar -C gcc-32/ -zxf gcc-32.tar.gz
    elif [[ "$GCC_32_SOURCE" == *'.tar.xz' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.tar.xz
        mkdir gcc-32
        tar -C gcc-32/ -xf gcc-32.tar.xz --strip-components=1
    elif [[ "$GCC_32_SOURCE" == *'.xz' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.xz
        mkdir gcc-32
        tar -C gcc-32/ -xf gcc-32.xz --strip-components=1
    elif [[ "$GCC_32_SOURCE" == *'.zip' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.zip
        mkdir gcc-32
        unzip gcc-32.zip -d gcc-32/
    else
        echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
        echo ">                            <"
        echo ">Please input vaild GCC link!<"
        echo ">                            <"
        echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
        exit 1
    fi
    bash found_gcc.sh GCC_32

elif [[ -n "$GCC_32_SOURCE" ]]; then
    echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
    echo ">                            <"
    echo ">         Get GCC 32         <"
    echo ">                            <"
    echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
    if [[ "$GCC_32_SOURCE" == *".git" ]]; then
        git clone "$GCC_32_SOURCE" -b "$GCC_32_BRANCH" gcc-32 --depth=1
    elif [[ "$GCC_32_SOURCE" == *'.tar.gz' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.tar.gz
        mkdir gcc-32
        tar -C gcc-32/ -zxf gcc-32.tar.gz
    elif [[ "$GCC_32_SOURCE" == *'.tar.xz' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.tar.xz
        mkdir gcc-32
        tar -C gcc-32/ -xf gcc-32.tar.xz --strip-components=1
    elif [[ "$GCC_32_SOURCE" == *'.zip' ]]; then
        $CURLX "$GCC_32_SOURCE" gcc-32.zip
        mkdir gcc-32
        unzip gcc-32.zip -d gcc-32/
    else
        echo ">>>>>>>>>>GCC Status<<<<<<<<<<"
        echo ">                            <"
        echo ">Please input vaild GCC link!<"
        echo ">                            <"
        echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<"
        exit 1
    fi
    bash found_gcc.sh GCC_32_ONLY
fi

# Set Clang
if [[ -z "$CLANG_SOURCE" ]]; then
    echo ">>>>>>>>>>Clang Status<<<<<<<<<<"
    echo ">                              <"
    echo ">        Not Set Clang!        <"
    echo ">                              <"
    echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"
else
    echo ">>>>>>>>>>Clang Status<<<<<<<<<<"
    echo ">                              <"
    echo ">          Get Clang.          <"
    echo ">                              <"
    echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"

    if [[ "$CLANG_SOURCE" == *".git" ]]; then
        git clone "$CLANG_SOURCE" -b "$CLANG_BRANCH" clang-custom --depth=1
    elif [[ "$CLANG_SOURCE" == *'.tar.gz' ]]; then
        $CURLX "$CLANG_SOURCE" clang.tar.gz
        mkdir clang-custom
        tar -C clang-custom/ -zxf clang.tar.gz
    elif [[ "$CLANG_SOURCE" == *'.tar.xz' ]]; then
        $CURLX "$CLANG_SOURCE" clang.tar.xz
        mkdir clang-custom
        tar -C clang-custom/ -xf clang.tar.xz --strip-components=1
    elif [[ "$CLANG_SOURCE" == *'.zip' ]]; then
        $CURLX "$CLANG_SOURCE" clang.zip
        mkdir clang-custom
        unzip clang.zip -d clang-custom/
    elif [[ "$CLANG_SOURCE" == *"antman" ]]; then
        mkdir clang-custom
        cd clang-custom
        $CURLX "$CLANG_SOURCE" antman
        chmod +x antman
        bash antman -S
        cd ..
    else
        echo ">>>>>>>>>>Clang Status<<<<<<<<<<"
        echo ">                              <"
        echo ">Please input vaild Clang link!<"
        echo ">                              <"
        echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"
        exit 1
    fi
fi

footer

# =============================================================================
# Step 3: ⚙️ Get necessary tools
# =============================================================================

title "Step 3: ⚙️ Get necessary tools"
echo "获取必要工具..."

# Get Kernel
echo "获取内核源码..."
git clone --recursive "$KERNEL_SOURCE" -b "$KERNEL_BRANCH" device_kernel --depth=1

# Get Kernel Version and Kernel Version
KERNEL_VERSION=$(head -n 3 device_kernel/Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
export KERNEL_VERSION
export FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
export SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')

# Get Kernel Arch
cd device_kernel
if [[ -d "arch/arm64/configs" ]]; then
    export KERNEL_ARCH="arm64"
else
    export KERNEL_ARCH="arm"
fi

# Get Packing Tools
if [[ "$PACK_METHOD" = "Anykernel3" ]]; then
    if [[ -d "Anykernel3" ]]; then
        echo "Found Anykernel3 in Kernel!"
    else
        git clone "$AK3_SOURCE" -b "$AK3_BRANCH" Anykernel3 --depth=1
    fi
elif [[ "$PACK_METHOD" = "MKBOOTIMG" ]] || [ "$DEFCONFIG_FROM_BOOT" = "true" ]; then
    cd ..
    git clone https://android.googlesource.com/platform/system/tools/mkbootimg mkboottools -b main-kernel-build-2024 --depth=1
    $CURLX $BOOT_SOURCE boot_source_$DEVICE_NAME.img
    cd device_kernel
else
    echo "Need packing method! "
    exit 1
fi
export PACK_METHOD

# Get DEFCONFIG
if [[ -n "$DEFCONFIG_SOURCE" ]] || [[ "$DEFCONFIG_FROM_BOOT" = "true" ]]; then
    if [[ -n "$DEFCONFIG_SOURCE" ]]; then
        if [[ -d "arch/arm64/configs" ]]; then
            $CURLX $DEFCONFIG_SOURCE arch/arm64/configs/$DEFCONFIG_NAME
        else
            $CURLX $DEFCONFIG_SOURCE arch/arm/configs/$DEFCONFIG_NAME
        fi
    elif [[ -z "$DEFCONFIG_ORIGIN_IMAGE" ]]; then
        if [[ "$DEFCONFIG_FROM_BOOT" = "true" ]]; then
            if [[ -f "$BOOT_SOURCE" ]]; then
                $CURLX "$BOOT_SOURCE" ../boot.img
                ../mkboottools/unpack_bootimg.py --boot_img ../boot.img
                mv ../out/kernel ../Image
                if [[ -d "arch/arm64/configs" ]]; then
                    scripts/extract-ikconfig ../Image > arch/arm64/configs/$DEFCONFIG_NAME
                else
                    scripts/extract-ikconfig ../Image > arch/arm/configs/$DEFCONFIG_NAME
                fi
            fi
        else
            $CURLX "$DEFCONFIG_ORIGIN_IMAGE" ../Image
            if [[ -d "arch/arm64/configs" ]]; then
                scripts/extract-ikconfig ../Image > arch/arm64/configs/$DEFCONFIG_NAME
            else
                scripts/extract-ikconfig ../Image > arch/arm/configs/$DEFCONFIG_NAME
            fi
        fi
    fi
fi

footer

# =============================================================================
# Step 4: 🪝 Patch Kernel of SUSFS
# =============================================================================

title "Step 4: 🪝 Patch Kernel of SUSFS"
echo "应用SUSFS内核补丁..."

if [ "$SUSFS_ENABLE" = "true" ]; then
    # Get SuSFS
    SUSFS_SOURCE=https://gitlab.com/simonpunk/susfs4ksu.git
    SUSFS_BRANCH=kernel-$KERNEL_VERSION

    if [[ "$SUSFS_FIXED" = true ]]; then
        if [ -z "$PATCHES_SOURCE" ] || [ -z "$PATCHES_BRANCH" ]; then
            echo "Please input a vaild source and branch!"
            exit 1
        elif [[ "$PATCHES_SOURCE" == *".git" ]]; then
            echo "Please do not set a full URL in PATCH_SOURCE!"
            exit 1
        else
            git clone https://github.com/$PATCHES_SOURCE.git -b $PATCHES_BRANCH NonGKI_Kernel_Patches --depth=1
        fi
    fi
    git clone $SUSFS_SOURCE -b $SUSFS_BRANCH susfs4ksu --depth=1

    # Copy
    cp susfs4ksu/kernel_patches/fs/* fs/
    cp susfs4ksu/kernel_patches/include/linux/* include/linux/

    # Set KSU and SUSFS for DEFCONFIG
    echo "CONFIG_KSU_SUSFS=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "# CONFIG_KSU_SUSFS_SUS_OVERLAYFS is not set" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    echo "# CONFIG_KSU_SUSFS_SUS_SU is not set" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME

    if grep -q "CMD_SUSFS_ADD_SUS_MAP" "drivers/kernelsu/core_hook.c"; then
        echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    fi

    # Patch SuSFS
    if grep -q "CONFIG_KSU_SUSFS" "fs/namespace.c"; then
        echo ">>>>>>>>>>>>Check<<<<<<<<<<<<"
        echo ">SuSFS is already patched, skipping.<"
        echo ">>>>>>>>>>>>>> <<<<<<<<<<<<<<"
        export SUSFS_SKIP=true
    else
        cp susfs4ksu/kernel_patches/50_add_susfs_in_kernel-$KERNEL_VERSION.patch ./
        patch -p1 < 50_add_susfs_in_kernel-$KERNEL_VERSION.patch || true
    fi

    # SUSFS Patch Fixed
    if [[ "$SUSFS_ENABLE" = "true" ]] && [[ "$SUSFS_SKIP" != "true" ]]; then
        if [[ -n "$SUSFS_155_FIXED" ]]; then
            IFS=',' read -ra FIXED_LIST <<< "$SUSFS_155_FIXED"
            echo "<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>"
            for i in "${!FIXED_LIST[@]}"; do
                echo "Patching -> ${FIXED_LIST[$i]}"
                if [[ -z "$SUSFS_FOLDER_FIXED" ]]; then
                    cp NonGKI_Kernel_Patches/${FIXED_LIST[$i]}.patch ./
                else
                    cp NonGKI_Kernel_Patches/"$SUSFS_FOLDER_FIXED"/${FIXED_LIST[$i]}.patch ./
                fi
                patch -p1 < ${FIXED_LIST[$i]}.patch || true
                echo "Patching successful!"
                echo "<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>"
            done
        fi
    fi

    # Updated SUSFS Version
    if [[ "$SUSFS_ENABLE" = "true" ]] && [[ "$SUSFS_UPDATE" = "true" ]] && [[ "$SUSFS_SKIP" != "true" ]]; then
        # Upgrade 1.5.7
        cp /tmp/Patches/Patch/susfs_upgrade_to_157.patch ./
        patch -p1 < susfs_upgrade_to_157.patch || true
        echo "================="
        echo "=Upgraded  1.5.7="
        echo "================="

        # Upgrade 1.5.8
        cp /tmp/Patches/Patch/susfs_upgrade_to_158_$KERNEL_VERSION.patch ./
        patch -p1 < susfs_upgrade_to_158_$KERNEL_VERSION.patch || true
        echo "================="
        echo "=Upgraded  1.5.8="
        echo "================="

        # Upgrade 1.5.9
        cp /tmp/Patches/Patch/susfs_upgrade_to_159.patch ./
        patch -p1 < susfs_upgrade_to_159.patch || true
        echo "================="
        echo "=Upgraded  1.5.9="
        echo "================="

        # Upgrade 1.5.10
        if grep -q "CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING" "drivers/kernelsu/core_hook.c"; then
            cp /tmp/Patches/Patch/susfs_upgrade_to_1510_$KERNEL_VERSION.patch ./
            patch -p1

        < susfs_upgrade_to_1510_$KERNEL_VERSION.patch || true
            echo "================="
            echo "=Upgraded 1.5.10="
            echo "================="
        else
            echo "============================================================"
            echo "=Your KernelSU fork doesn't support SuSFS 1.5.10, skipping.="
            echo "============================================================"
        fi

        # Upgrade 1.5.11
        if grep -q "susfs_reorder_mnt_id" "drivers/kernelsu/core_hook.c"; then
            cp /tmp/Patches/Patch/susfs_upgrade_to_1511_$KERNEL_VERSION.patch ./
            patch -p1 < susfs_upgrade_to_1511_$KERNEL_VERSION.patch || true
            echo "================="
            echo "=Upgraded 1.5.11="
            echo "================="
        else
            echo "============================================================"
            echo "=Your KernelSU fork doesn't support SuSFS 1.5.11, skipping.="
            echo "============================================================"
        fi

        # Upgrade 1.5.12
        if grep -q "susfs_reorder_mnt_id" "drivers/kernelsu/core_hook.c"; then
            cp /tmp/Patches/Patch/susfs_upgrade_to_1512_$KERNEL_VERSION.patch ./
            patch -p1 < susfs_upgrade_to_1512_$KERNEL_VERSION.patch || true
            echo "================="
            echo "=Upgraded 1.5.12="
            echo "================="
        else
            echo "============================================================"
            echo "=Your KernelSU fork doesn't support SuSFS 1.5.12, skipping.="
            echo "============================================================"
        fi

        # Upgrade 1.5.13
        if grep -q "CMD_SUSFS_ADD_SUS_MAP" "drivers/kernelsu/core_hook.c"; then
            cp /tmp/Patches/Patch/susfs_upgrade_to_1513_$KERNEL_VERSION.patch ./
            patch -p1 < susfs_upgrade_to_1513_$KERNEL_VERSION.patch || true
            echo "================="
            echo "=Upgraded 1.5.13="
            echo "================="
        else
            echo "============================================================"
            echo "=Your KernelSU fork doesn't support SuSFS 1.5.13, skipping.="
            echo "============================================================"
        fi

        # Clean SUS_SU
        CLEAN_FILES=("fs/devpts/inode.c" "fs/exec.c" "fs/open.c" "fs/stat.c")

        for file in "${CLEAN_FILES[@]}"; do
            sed -i '/#ifdef CONFIG_KSU_SUSFS_SUS_SU/,/#endif/d' "${file}"
            echo "Cleaned SUS_SU for ${file}."
        done
    fi

    # Updated SUSFS Patch Fixed
    if [[ "$SUSFS_ENABLE" = "true" ]] && [[ "$SUSFS_UPDATE" = "true" ]] && [[ "$SUSFS_SKIP" != "true" ]]; then
        if [[ -n "$SUSFS_LATEST_FIXED" ]]; then
            IFS=',' read -ra FIXED_LIST <<< "$SUSFS_LATEST_FIXED"
            echo "<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>"
            for i in "${!FIXED_LIST[@]}"; do
                echo "Patching -> ${FIXED_LIST[$i]}"
                if [[ -z "$SUSFS_FOLDER_FIXED" ]]; then
                    cp NonGKI_Kernel_Patches/${FIXED_LIST[$i]}.patch ./
                else
                    cp NonGKI_Kernel_Patches/"$SUSFS_FOLDER_FIXED"/${FIXED_LIST[$i]}.patch ./
                fi
                patch -p1 < ${FIXED_LIST[$i]}.patch || true
                echo "Patch successful!"
                echo "<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>"
            done
        fi
    fi
fi

footer

# =============================================================================
# Step 5: 🔗 Patch for no-kprobe
# =============================================================================

title "Step 5: 🔗 Patch for no-kprobe"
echo "应用无kprobe补丁..."

# Check hook
if grep -q "can_umount" "fs/namespace.c" && grep -q "ksu_init" "fs/exec.c"; then
    echo "Your kernel source code appears to have been manually patched, so this step is skipped."

# Check normal hook
elif [[ $HOOK_METHOD == "normal" ]]; then
    if [[ $FIRST_VERSION -le 3 ]] && [[ $SECOND_VERSION -le 10 ]]; then
        echo "kernel $KERNEL_VERSION doesn't support normal hook."
        exit 1
    fi
    cp /tmp/Patches/normal_hook_patches.sh ./
    cp /tmp/Patches/backport_patches_early.sh ./

    bash normal_hook_patches.sh ./
    bash backport_patches_early.sh

    echo "executed normal hook and backport patch successfully."

# Check syscall hook
elif [[ $HOOK_METHOD == "syscall" ]]; then
    if [[ "$HOOK_OLDER" == "true" ]]; then
        cp /tmp/Patches/syscall_hook_patches_older.sh ./
        bash syscall_hook_patches_older.sh ./

        echo "executed syscall hook older successfully."
    else
        cp /tmp/Patches/syscall_hook_patches.sh ./
        bash syscall_hook_patches.sh ./

        echo "executed syscall hook successfully."
    fi

    if [[ $FIRST_VERSION -le 3 ]] && [[ $SECOND_VERSION -le 10 ]]; then
        cp /tmp/Patches/backport_patches_early.sh ./
        bash backport_patches_early.sh

        echo "kernel $KERNEL_VERSION doesn't kernel_write and kernel_read, so only executed backport patch older."
    elif [[ $FIRST_VERSION -le 4 ]] && [[ $SECOND_VERSION -le 9 ]]; then
        cp /tmp/Patches/backport_patches.sh ./
        cp /tmp/Patches/Patch/backport_kernel_read_and_kernel_write_to_ksu.patch ./

        bash backport_patches.sh
        if grep -q "kernel_read" "fs/read_write.c"; then
            echo ">>>>>>>>>>>>>>>Backport Patch<<<<<<<<<<<<<<<<"
            echo ">                                           <"
            echo "Your kernel is already backported, skipping"
            echo ">                                           <"
            echo ">>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<"
        else
            patch -p1 < backport_kernel_read_and_kernel_write_to_ksu.patch || true
        fi

        echo "executed backport patch (contain kernel_read and kernel_write patch) successfully."
    else
        cp /tmp/Patches/backport_patches.sh ./
        bash backport_patches.sh

        echo "executed backport patch successfully."
    fi

# Check tracepoint hook
elif [[ $HOOK_METHOD == "tracepoint" ]]; then
    if [[ "$KERNELSU_AUTO_GET" == "true" ]] && [[ "$KERNELSU_AUTO_FORK" != "sukisu" ]]; then
        echo "======================================Error======================================"
        echo "= your kernelsu branch doesn't support tracepoint, use SukiSU-Ultra please. ="
        echo "================================================================================="
        exit 1
    elif [[ "$KERNELSU_AUTO_GET" != "true" ]] && [[ "$KERNELSU_SOURCE" != *SukiSU* ]]; then
        echo "======================================Error======================================"
        echo "= your kernelsu branch doesn't support tracepoint, use SukiSU-Ultra please. ="
        echo "================================================================================="
        exit 1
    fi
    cp /tmp/Patches/tracepoint_hook_patches.sh ./
    bash tracepoint_hook_patches.sh ./

    echo "executed tracepoint hook successfully."

    if [[ $FIRST_VERSION -le 3 ]] && [[ $SECOND_VERSION -le 10 ]]; then
        cp /tmp/Patches/backport_patches_early.sh ./
        bash backport_patches_early.sh

        echo "kernel $KERNEL_VERSION doesn't patch kernel_write and kernel_read, so only executed backport patch older."
    elif [[ $FIRST_VERSION -le 4 ]] && [[ $SECOND_VERSION -le 9 ]]; then
        cp /tmp/Patches/backport_patches.sh ./
        cp /tmp/Patches/Patch/backport_kernel_read_and_kernel_write_to_ksu.patch ./

        bash backport_patches.sh
        patch -p1 < backport_kernel_read_and_kernel_write_to_ksu.patch || true

        echo "executed backport patch (contain kernel_read and kernel_write patch) successfully."
    else
        cp /tmp/Patches/backport_patches.sh ./
        bash backport_patches.sh

        echo "executed backport patch successfully."
    fi

else
    echo "please input a vaild option!"
    exit 1
fi

footer

# =============================================================================
# Step 6: 🪛 Extra Kernel Options
# =============================================================================

title "Step 6: 🪛 Extra Kernel Options"
echo "应用额外内核选项..."

# Only $DEVICE_NAME use it.
cd device_kernel

# Patch: Temporarily solution for fixing the commit of SukiSU Ultra
wget https://raw.githubusercontent.com/mzwing/NonGKI_Kernel_Patches/refs/heads/mi_kernel/mimax2_msm8953/add_ksu_uid_scanner_enabled.patch
patch -p1 < add_ksu_uid_scanner_enabled.patch

footer

# =============================================================================
# Step 7: 🧰 Patch Kernel of Re:Kernel
# =============================================================================

title "Step 7: 🧰 Patch Kernel of Re:Kernel"
echo "应用Re:Kernel内核补丁..."

if [ "$REKERNEL_ENABLE" = "true" ]; then
    cp /tmp/Patches/Rekernel/rekernel_patches.sh ./
    bash rekernel_patches.sh

    mkdir -p drivers/rekernel
    cp /tmp/Patches/Rekernel/rekernel_extra.patch ./
    patch -p1 < rekernel_extra.patch || true

    echo "Patched Re:Kernel for your kernel successfully."
fi

footer

# =============================================================================
# Step 8: 🔒 Patch Kernel of Baseband Guard
# =============================================================================

title "Step 8: 🔒 Patch Kernel of Baseband Guard"
echo "应用Baseband Guard内核补丁..."

if [ "$BASEBAND_GUARD_ENABLE" = "true" ]; then
    wget -O- https://github.com/vc-teahouse/Baseband-guard/raw/main/setup.sh | bash
    echo "CONFIG_BBG=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME

    if [[ "$BASEBAND_GUARD_BOOT" == "true" ]]; then
        echo "CONFIG_BBG_BLOCK_BOOT=y" >> ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    fi

    if grep -q "DEFINE_LSM" "include/linux/lsm_hooks.h" && ! grep -q "baseband_guard" "./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME"; then
        echo "=======Detect======="
        echo "= Found DEFINE_LSM ="
        echo "===================="
        sed -i 's/\(CONFIG_LSM="[^"]*\)"/\1,baseband_guard"/' ./arch/$KERNEL_ARCH/configs/$DEFCONFIG_NAME
    fi

    echo "Patched Baseband Guard for your kernel successfully."
fi

footer

# =============================================================================
# Step 9: 🔧 Patch Hide Stuff
# =============================================================================

title "Step 9: 🔧 Patch Hide Stuff"
echo "应用Hide Stuff补丁..."

if [ "$HIDE_STUFF" = "true" ]; then
    if grep -q "show_vma_header_prefix_fake" "fs/proc/task_mmu.c"; then
        echo "[+] Found show_vma_header_prefix_fake."
    else
        cp /tmp/Patches/HideStuff/added_show_vma_header_prefix_fake.cocci ./
        spatch --sp-file added_show_vma_header_prefix_fake.cocci --in-place fs/proc/task_mmu.c
        echo "[+] Added show_vma_header_prefix_fake."
    fi

    if grep "struct dentry \*dentry" "fs/proc/task_mmu.c"; then
        echo "[+] Found variable."
    else
        sed -i '/const char \*name = NULL;/a\    struct dentry *dentry;' fs/proc/task_mmu.c
        echo "[+] Added dentry."
    fi

    if grep -q "jit-zygote-cache" "fs/proc/task_mmu.c"; then
        echo "[+] Found hide stuff."
    else
        cp /tmp/Patches/HideStuff/function_hide_stuff.cocci ./
        spatch --sp-file function_hide_stuff.cocci --in-place fs/proc/task_mmu.c
        echo "[+] Added hide stuff."
    fi

    if grep -q "bypass:" "fs/proc/task_mmu.c"; then
        echo "[+] Found bypass."
    else
        if grep -q 'if (show_vma_header_prefix' "fs/proc/task_mmu.c"; then
            perl -i -0pe 's/(if \(show_vma_header_prefix\(m, start, end, flags, pgoff, dev, ino\)\)\s+return;)/$1\nbypass:/s' fs/proc/task_mmu.c
            echo "[+] Added bypass."
        else
            sed -i '/show_vma_header_prefix(m, start, end, flags, pgoff, dev, ino);/a\bypass:' fs/proc/task_mmu.c
            echo "[+] Added bypass."
        fi
    fi

    if grep -q "lineage" "fs/proc/base.c"; then
        echo "[+] Found hide stuff part ii."
    else
        cp /tmp/Patches/HideStuff/function_hide_stuff_partii.cocci ./
        spatch --sp-file function_hide_stuff_partii.cocci --in-place fs/proc/base.c
        echo "[+] Added hide stuff part ii."
    fi

    if grep -q "/dev/ashmem" "fs/proc/task_mmu.c"; then
        sed -i 's|"/dev/ashmem (deleted)"|"/system/framework/framework-res.apk"|' fs/proc/task_mmu.c
        sed -i 's|"/dev/ashmem (deleted)"|"/system/framework/framework-res.apk"|' fs/proc/base.c
        echo "[+] Changed ashmem to framework-res."
    fi
fi

footer

# =============================================================================
# Step 10: 🚀 Build Process
# =============================================================================

title "Step 10: 🚀 Build Process"
echo "开始构建过程..."

# Setup ccache
echo "设置ccache缓存..."
ccache -z  # Clear ccache
ccache -M 2G  # Set max cache size to 2G

# Build Kernel Function
BUILD_PROCESS() {
    if [ -n "$1" ]; then
        echo "Select: $1"
        local BUILD_CLANG="$1"
    else
        BUILD_CLANG=""
    fi

    if [ -n "$CLANG_SOURCE" ]; then
        export PATH=$(pwd)/clang-custom/bin:$PATH
    fi

    if [[ "$BUILD_CLANG" == "true" ]]; then
        echo "========================"
        echo "=Read Defconfig (Clang)="
        echo "========================"
        make CC="ccache clang" O=out ARCH="$KERNEL_ARCH" $CUSTOM_CMDS $EXTRA_CMDS $DEFCONFIG_NAME
    else
        echo "================"
        echo "=Read Defconfig="
        echo "================"
        make O=out ARCH="$KERNEL_ARCH" $DEFCONFIG_NAME
    fi

    if [[ "$BUILD_OTHER_CONFIG" == "true" ]]; then
        echo "================="
        echo "=Merge Config(s)="
        echo "================="
        IFS=',' read -ra MERGE_CONFIG_FILES <<< "$MERGE_CONFIG_FILES"
        for FILES in "${MERGE_CONFIG_FILES[@]}"; do
            ./scripts/kconfig/merge_config.sh -O out/ -m out/.config arch/"$KERNEL_ARCH"/configs/$FILES
        done
        if [[ "$BUILD_CLANG" == "true" ]]; then
            echo "==============================="
            echo "=Execuate olddefconfig (Clang)="
            echo "==============================="
            make CC="ccache clang" O=out ARCH="$KERNEL_ARCH" $CUSTOM_CMDS $EXTRA_CMDS olddefconfig
        else
            echo "======================="
            echo "=Execuate olddefconfig="
            echo "======================="
            make O=out ARCH="$KERNEL_ARCH" olddefconfig
        fi
    fi

    if [[ "$BUILD_CLANG" == "true" ]]; then
        echo "======================"
        echo "=Execuate Clang Build="
        echo "======================"
        make -j$(nproc --all) CC="ccache clang" $CUSTOM_CMDS $EXTRA_CMDS O=out ARCH="$KERNEL_ARCH" 2>&1 | tee error.log
    else
        echo "===================="
        echo "=Execuate GCC Build="
        echo "===================="
        make -j$(nproc --all) O=out ARCH="$KERNEL_ARCH" 2>&1 | tee error.log
    fi
}

# Core Build Logic
if [ -n "$CLANG_SOURCE" ]; then
    if [ -n "$GCC_64" ] && [ -n "$GCC_32" ]; then
        echo "=================================="
        echo "=Detected Clang and GCC 64 and 32="
        echo "=================================="
        export "$GCC_64"
        export "$GCC_32"
        BUILD_PROCESS true
    elif [ "$GNU_GCC" == "true" ]; then
        echo "============================"
        echo "=Detected Clang and GNU GCC="
        echo "============================"
        export "$GCC_64"
        export "$GCC_32"
        BUILD_PROCESS true
    elif [ -n "$GCC_64" ]; then
        echo "==========================="
        echo "=Detected Clang and GCC 64="
        echo "==========================="
        export "$GCC_64"
        BUILD_PROCESS true
    else
        echo "====================="
        echo "=Detected Only Clang="
        echo "====================="
        BUILD_PROCESS true
    fi

elif [ "$KERNEL_ARCH" == "arm64" ]; then
    if [ -n "$GCC_64" ] && [ -n "$GCC_32" ]; then
        echo "=================================="
        echo "=Detected ARM64 GCC 64 and GCC 32="
        echo "=================================="
        export "$GCC_64"
        export "$GCC_32"
        BUILD_PROCESS
    elif [ "$GNU_GCC" == "true" ]; then
        echo "========================"
        echo "=Detected ARM64 GNU GCC="
        echo "========================"
        export "$GCC_64"
        export "$GCC_32"
        BUILD_PROCESS
    elif [ -n "$GCC_64" ]; then
        echo "============================"
        echo "=Detected ARM64 Only GCC 64="
        echo "============================"
        export "$GCC_64"
        BUILD_PROCESS
    fi

elif [ "$KERNEL_ARCH" == "arm" ]; then
    if [ "$GNU_GCC" == "true" ]; then
        echo "======================"
        echo "=Detected ARM GNU GCC="
        echo "======================"
        export "$GCC_32"
        BUILD_PROCESS
    elif [ -n "$GCC_32" ]; then
        echo "====================="
        echo "=Detected ARM GCC 32="
        echo "====================="
        export "$GCC_32"
        BUILD_PROCESS
    fi

else
    echo "invaild kernel arch, stop."
    exit 1
fi

footer

# =============================================================================
# Step 11: 🔩 Pack Process
# =============================================================================

title "Step 11: 🔩 Pack Process"
echo "开始打包过程..."

TIME=$(date +"%Y%m%d%H%M%S")

if [[ -d "arch/arm64/configs" ]]; then
    IMAGE_DIR="$(pwd)/out/arch/arm64/boot"
else
    IMAGE_DIR="$(pwd)/out/arch/arm/boot"
fi

mkdir -p tmp

if [[ "$AK3_SOURCE" =~ "osm0sis" ]]; then
    sed -i 's/ExampleKernel by osm0sis @ xda-developers/NonGKI Kernel Build by JackAltman @ Github/g' Anykernel3/anykernel.sh
    sed -i 's/do.devicecheck=1/do.devicecheck=0/g' Anykernel3/anykernel.sh
    sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=auto;!g' Anykernel3/anykernel.sh
    sed -i 's/IS_SLOT_DEVICE=0;/is_slot_device=auto;/g' Anykernel3/anykernel.sh
    echo "Now using official Anykernel3."
else
    echo "Now using custom Anykernel3."
fi

if [[ -f "$IMAGE_DIR/Image.gz-dtb" ]]; then
    cp -fp $IMAGE_DIR/Image.gz-dtb tmp
    echo "Found Image.gz-dtb !"
elif [[ -f "$IMAGE_DIR/Image.gz" ]]; then
    cp -fp $IMAGE_DIR/Image.gz tmp
    echo "Found Image.gz !"
elif [[ -f "$IMAGE_DIR/zImage-dtb" ]]; then
    cp -fp $IMAGE_DIR/zImage-dtb tmp
    echo "Found zImage-dtb (ARMV7A) !"
elif [[ -f "$IMAGE_DIR/Image" ]]; then
    cp -fp $IMAGE_DIR/Image tmp
    echo "Found Image !"
fi

if [[ -f "$IMAGE_DIR/dtbo.img" ]]; then
    cp -fp $IMAGE_DIR/dtbo.img tmp
    echo "Found dtbo.img !"
else
    echo "Doesn't found dtbo.img! Your device maybe needn't the file."
fi

if [[ -f "$IMAGE_DIR/dtb.img" ]]; then
    cp -fp $IMAGE_DIR/dtb.img tmp
    echo "Found dtb.img !"
else
    echo "Doesn't found dtb.img! Your device maybe needn't the file."
fi

if [ -f "$IMAGE_DIR/dtb" ]; then
    echo "Found DTB!"
    cp -fp $IMAGE_DIR/dtb tmp
elif [ "$GENERATE_DTB" == "true" ]; then
    if ls $IMAGE_DIR/dts/$GENERATE_CHIP/*.dtb 1> /dev/null 2>&1; then
        DTB_PATH="dts
"
    elif ls $IMAGE_DIR/dts/vendor/$GENERATE_CHIP/*.dtb 1> /dev/null 2>&1; then
        DTB_PATH="dts/vendor"
    else
        echo "Not found dts, abort."
        exit 1
    fi

    cat $IMAGE_DIR/$DTB_PATH/$GENERATE_CHIP/*.dtb > $IMAGE_DIR/DTB
    cp -fp $IMAGE_DIR/DTB tmp
    echo "Generated $GENERATE_CHIP DTB."
else
    echo "Doesn't found DTB! Your device maybe needn't the file."
fi

cp -rp ./Anykernel3/* tmp
cd tmp
7za a -mx9 tmp.zip *
cd ..
cp -fp tmp/tmp.zip $DEVICE_CODENAME-$ROM_TEXT-$TIME-$PACK_METHOD.zip
rm -rf tmp

export PACK_NAME=$DEVICE_CODENAME-$ROM_TEXT-$TIME-$PACK_METHOD.zip

footer

# =============================================================================
# Step 12: ✏️ Upload Artifacts (注释占位符)
# =============================================================================

title "Step 12: ✏️ Upload Artifacts"
echo "上传构建产物..."

# 注意：此步骤在本地环境中不需要，因为文件已经生成在当前目录
# 在GitHub Actions中，这些文件会被自动上传为artifacts

echo "构建完成！生成的文件："
echo "- $PACK_NAME"
echo ""
echo "文件位置：$(pwd)/$PACK_NAME"
echo ""
echo "==============================================="
echo "构建成功完成！"
echo "==============================================="

footer

# =============================================================================
# Script End
# =============================================================================

echo "脚本执行完成！"
echo "请检查生成的内核文件：$PACK_NAME"