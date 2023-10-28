#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$(realpath $1)
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # get the number of cores then use it for building
    ncores=$(nproc)
    make -j${ncores-1} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    
    # make modules and device tree
    make -j${ncores-1} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make -j${ncores-1} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    echo "cloned busybox"
    # DONE:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
    echo "busybox is already cloned"
fi

# DONE: Make and install busybox
echo "About to install busybox"
make arch=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd ${OUTDIR}/rootfs
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

echo "Copying dependencies to filesystem root"
# DONE: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
# get a list of the itterpretter and copy it to the lib64 directory
INTERPRETTER=$(${CROSS_COMPILE}readelf -l bin/busybox | grep "program interpreter" | awk '{print $4}' | tr -d ']')
# assuming one interpretter
cp ${SYSROOT}/${INTERPRETTER} lib/
# list of the shared libraries without the []
libs=$(${CROSS_COMPILE}readelf -d bin/busybox | grep "Shared library" | awk '{print $5}' | tr -d '[]')
# fidn and copy the shared libraries to the lib64 directory
for lib in ${libs};
do find ${SYSROOT} -name ${lib} -exec cp {} lib64/ \;
done
# Done: Make device nodes
echo "making device nodes"
cd ${OUTDIR}/rootfs/dev/
sudo mknod -m 666 null c 1 3
sudo mknod -m 666 console c 5 1

# DONE: Clean and build the writer utility
echo "Cleaning and building the writer"
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "copying finder applications to rootfs"
cp finder-test.sh ${OUTDIR}/rootfs/home
cp finder.sh ${OUTDIR}/rootfs/home
mv writer ${OUTDIR}/rootfs/home
cp -r conf/ ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# DONE: Chown the root directory
echo "changing ownership of rootfs"
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# DONE: Create initramfs.cpio.gz
echo "creating initramfs.cpio.gz"
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
gzip -f ../initramfs.cpio