#!/bin/bash

set -e 

CRTDIR=$(pwd)
base=$1
profile=$2
ui=$3
echo $base
if [ ! -e "$base" ]; then
	echo "Please enter base folder"
	exit 1
else
	if [ ! -d $base ]; then 
		echo "Openwrt base folder not exist"
		exit 1
	fi
fi

if [ ! -n "$profile" ]; then
	profile=target_wlan_ap-gl-ax1800
fi

if [ ! -n "$ui" ]; then
        ui=true
fi
echo "Start..."

#clone source tree 
git clone https://github.com/gl-inet/gl-infra-builder.git $base/gl-infra-builder
cp -r custom/  $base/gl-infra-builder/feeds/custom/
cp -r *.yml $base/gl-infra-builder/profiles
cd $base/gl-infra-builder


function build_firmware(){
    cd ~/openwrt
    need_gl_ui=$1
    ui_path=$2
	# fix helloword build error
    rm -rf feeds/packages/lang/golang
    svn co https://github.com/openwrt/packages/branches/openwrt-22.03/lang/golang feeds/packages/lang/golang
    #install feed 
    ./scripts/feeds update -a && ./scripts/feeds install -a && make defconfig
    #build 
    if [[ $need_gl_ui == true  ]]; then 
        make -j$(expr $(nproc) + 1) GL_PKGDIR=~/glinet/$ui_path/ V=s
    else
        make -j$(expr $(nproc) + 1)  V=s
    fi
}

function copy_file(){
	patch=$1
	mkdir ~/firmware
	mkdir ~/packages
	cd $patch
	rm -rf packages
	cp -rf ./* ~/firmware
}

case $profile in 
    target_wlan_ap-gl-ax1800|\
    target_wlan_ap-gl-axt1800|\
    target_wlan_ap-gl-ax1800-5-4|\
    target_wlan_ap-gl-axt1800-5-4)
        if [[ $profile == *5-4* ]]; then
            python3 setup.py -c configs/config-wlan-ap-5.4.yml
        else
            python3 setup.py -c configs/config-wlan-ap.yml
        fi
        ln -s $base/gl-infra-builder/wlan-ap/openwrt ~/openwrt && cd ~/openwrt
        if [[ $ui == true  ]]; then 
	        ./scripts/gen_config.py $profile glinet_depends custom
            git clone https://github.com/gl-inet/glinet4.x.git ~/glinet
        else
	        ./scripts/gen_config.py $profile openwrt_common luci custom
        fi
        build_firmware $ui ipq60xx
		copy_file ~/openwrt/bin/targets/*/*
    ;;
    target_ipq40xx_gl-a1300)
        python3 setup.py -c configs/config-21.02.2.yml
        ln -s $base/gl-infra-builder/openwrt-21.02/openwrt-21.02.2 ~/openwrt && cd ~/openwrt
        ./scripts/gen_config.py $profile openwrt_common luci custom
        build_firmware 
		copy_file ~/openwrt/bin/targets/*/*
    ;;
	target_mt7981_gl-mt2500)
		python3 setup.py -c configs/config-mt798x-7.6.6.1.yml
		ln -s $base/gl-infra-builder/mt7981 ~/openwrt && cd ~/openwrt	
		if [[ $ui == true  ]]; then
            ./scripts/gen_config.py $profile glinet_depends custom
            git clone https://github.com/gl-inet/glinet4.x.git ~/glinet
        else
            ./scripts/gen_config.py $profile custom
        fi
		build_firmware $ui mt7981
		copy_file ~/openwrt/bin/targets/*/*
	;;
	target_siflower_gl-sf1200|\
	target_siflower_gl-sft1200)
		python3 setup.py -c configs/config-siflower-18.x.yml
		ln -s $base/gl-infra-builder/openwrt-18.06/siflower/openwrt-18.06 ~/openwrt && cd ~/openwrt
		./scripts/gen_config.py $profile custom
		build_firmware
		copy_file ~/openwrt/bin/targets/*
	;;
	target_ramips_gl-mt1300)
		python3 setup.py -c configs/config-22.03.0.yml
		ln -s $base/gl-infra-builder/openwrt-22.03/openwrt-22.03.0 ~/openwrt && cd ~/openwrt
		./scripts/gen_config.py $profile luci custom
		build_firmware
		copy_file ~/openwrt/bin/targets/*/*
	;;
esac

