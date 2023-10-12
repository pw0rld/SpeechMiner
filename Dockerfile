FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN apt-get update && apt-get install -yqq \
    git ocaml ocamlbuild automake python autoconf libelf1 python2 libssl-dev libtool cmake  build-essential \
    bison flex sudo kmod linux-base wget libelf-dev libssl-dev libcurl4-openssl-dev protobuf-compiler \
    libprotobuf-dev debhelper cmake reprepro unzip lsb-release\
    && rm -rf /var/lib/apt/lists/* && mkdir /etc/init

WORKDIR /app

RUN cd /app/ && wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19-rc8/linux-modules-4.19.0-041900rc8-generic_4.19.0-041900rc8.201810150631_amd64.deb -O linux-modules-5.5.0.deb &&\
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19-rc8/linux-headers-4.19.0-041900rc8_4.19.0-041900rc8.201810150631_all.deb -O linux-headers-5.5.0.deb &&\
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19-rc8/linux-headers-4.19.0-041900rc8-generic_4.19.0-041900rc8.201810150631_amd64.deb -O linux-headers-generic-5.5.0.deb &&\
    wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19-rc8/linux-image-unsigned-4.19.0-041900rc8-generic_4.19.0-041900rc8.201810150631_amd64.deb -O linux-image-5.5.0.deb &&\
    git clone https://github.com/intel/linux-sgx-driver.git && git clone https://github.com/jovanbulck/sgx-step.git && dpkg --install *.deb && ls /lib/modules/ && \
    make -C /lib/modules/4.19.0-041900rc8-generic/build M=/app/linux-sgx-driver && \
    mkdir -p "/lib/modules/4.19.0-041900rc8-generic/kernel/drivers/intel/sgx" && \
    cp /app/linux-sgx-driver/isgx.ko "/lib/modules/4.19.0-041900rc8-generic/kernel/drivers/intel/sgx" && \
    sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules" && \
    cd /app/sgx-step/sdk/intel-sdk  && ./install_SGX_SDK.sh

RUN cd /app/ && git clone https://github.com/pw0rld/SpeechMiner.git && \
    cp -r /app/linux-sgx-driver /app/SpeechMiner/kernel_sgxstep && \
    sed -i '234,236 s/^/\/\//' /app/SpeechMiner/kernel_sgxstep/sgxstep.c && \
    echo "Building kernel_sgxstep\n" &&\
    make -C /lib/modules/4.19.0-041900rc8-generic/build M=/app/SpeechMiner/kernel_sgxstep && \
    echo "Building libsgxstep\n" &&\
    cd /app/SpeechMiner/libsgxstep && make  && \
    echo "Building SpeechMiner root\n" &&\
    cd /app/SpeechMiner/ && sed -i 's/pkey_mprotect/pkey_mprotect_/g' ./libkdump/libkdump.c && \
    sed -i 's/pkey_set/pkey_set_/g' ./libkdump/libkdump.c && make  && \
    echo "Building 32-bit\n" &&\
    make  && cd /app/ && \
    echo "Building kernel_setexec\n" && sed -i "s/native_read_cr3/__native_read_cr3/g" /app/SpeechMiner/kernel_setexec/setexec.c  &&\
    make -C /lib/modules/4.19.0-041900rc8-generic/build M=/app/SpeechMiner/kernel_setexec