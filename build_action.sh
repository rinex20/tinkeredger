#!/usr/bin/env bash

# add deb-src to sources.list Ubuntu系统只需要把系统 apt 配置中的源码仓库注释取消掉即可
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
sudo apt update
sudo apt install -y wget
sudo apt build-dep -y linux

mkdir /usr/local/ARM-toolchain

# download linaro gcc
cd /usr/local/ARM-toolchain
wget http://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
xz -d gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
tar xvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar

export PATH=/usr/local/ARM-toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:${PATH}
echo $PATH

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

rm -f *.xz
rm -R gcc*
git clone https://github.com/rinex20/debian-kernel.git
cd debian-kernel

#cd /home/runner/work/debian-kernel

CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))

make ARCH=arm64 tinker_edge_r_defconfig CROSS_COMPILE=/usr/local/ARM-toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- -j"$CPU_CORES"
make ARCH=arm64 rk3399pro-tinker_edge_r.img CROSS_COMPILE=/usr/local/ARM-toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- -j"$CPU_CORES"

# build deb packages
# 获取系统的 CPU 核心数，将核心数X2设置为编译时开启的进程数，以加快编译速度
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
make deb-pkg -j"$CPU_CORES"

# move deb packages to artifact dir
cd ..
mkdir "artifact"
# 删除无用且巨大的调试包
rm ./*dbg*.deb
mv ./*.deb artifact/
