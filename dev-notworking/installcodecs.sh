#!/bin/bash
base="$(dirname "$(readlink -f "${0}")")"

#codecs are only available for x86 cpus
if [ `uname -m` == 'x86_64' ]; then
	chromeurl="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
	gtalkurl="https://drive.google.com/file/d/0B_2_dsXrefR-UDlXSUpIdTZUUE0/edit?usp=sharing"
	netflixurl="https://drive.google.com/file/d/0B_2_dsXrefR-S2cxYVRTdEpfQUE/edit?usp=sharing"
	arurl="https://github.com/sixsixfive/chromiumos/raw/master/dev-notworking/ar-binutils-2.23.2-chromebrew/amd64/ar"
elif [ $(uname -m) != "i686" ]
	cromeurl="https://dl-ssl.google.com/linux/direct/google-chrome-unstable_current_i386.deb"
	gtalkurl=""
	netflixurl=""
	arurl="https://github.com/sixsixfive/chromiumos/raw/master/dev-notworking/ar-binutils-2.23.2-chromebrew/x86/ar"
else
	echo 'Only x86 compatible CPUs are supported'
	exit 1;
fi

#remount the root partition
echo "remounting rootfs"
sleep 3
mount -o remount, rw /

#remove that ugly string at the login screen
sed -i '/CHROMEOS_RELEASE_DESCRIPTION/d' /etc/lsb-release

#creating the pepper dir and a tmpdir
mkdir -p /opt/google/chrome/pepper
mkdir -p "$base"/.codectmp

#download ar
if [ -f "$base"/.codectmp/ar ]; then
	echo "GNU ar found"
	sleep 3
else
	echo "downloading GNU ar"
	sleep 3
	wget --progress=dot "$arurl" -O "$base"/.codectmp/ar 2>&1 | grep --line-buffered "%"
fi

if [ -f "$base"/.codectmp/ar ]; then
	echo "installing ar"
	sleep 3
	cp "$base"/.codectmp/ar /usr/bin/ar -f
	chmod +x /usr/bin/ar
	if [ -f /usr/bin/ar ]; then
		echo "ar installed"
	else
		echo "couldn't find ar - something went wrong - aborting!"
		mount -o remount, r /
		exit 1;
	fi
else
	echo "couldn't download ar - aborting! (-_-)"
	mount -o remount, r /
	exit 1;
fi

#download peppertalk
if [ -f "$base"/.codectmp/google-talk-pepper.tbz ]; then
	echo "gtalk found"
	sleep 3
else
	echo "downloading peppertalk"
	sleep 3
	wget --progress=dot "$gtalkurl" -O "$base"/.codectmp/google-talk-pepper.tbz 2>&1 | grep --line-buffered "%"
fi

if [ -f "$base"/.codectmp/google-talk-pepper.tbz ]; then
	echo "extracting peppertalk"
	sleep 3
	cd /
	tar xfvj "$base"/.codectmp/google-talk-pepper.tbz
	if [-f /opt/google/talkplugin/GoogleTalkPlugin]; then
		echo "GTalkPlugin installed"
	else
		echo "FAIL (-_-)"
	fi
else
	echo "couldn't download peppertalk (-_-)"
fi

#download netflix
if [ -f "$base"/.codectmp/netflixhelper.tbz ]; then
	echo "netflix found"
	sleep 3
else
	echo "downloading netflixplugin"
	sleep 3
	wget --progress=dot "$netflixurl" -O "$base"/.codectmp/netflixhelper.tbz 2>&1 | grep --line-buffered "%"
fi

if [ -f "$base"/.codectmp/netflixhelper.tbz ]; then
	echo "extracting netflixplugin"
	sleep 3
	cd /
	tar xfvj "$base"/.codectmp/netflixhelper.tbz
	if [-f /opt/google/chrome/pepper/libnetflixhelper.so]; then
		echo "Netflix Plugin installed"
	else
		echo "FAIL (-_-)"
	fi
else
	echo "couldn't download netflixplugin (-_-)"
fi

#adobe stuff
echo "Downloading the adobe pepper plugins"
sleep 3
wget --progress=dot "$chromeurl" -O "$base"/.codectmp/chrome-bin.deb 2>&1 | grep --line-buffered "%"
mkdir "$base"/.codectmp/chrome-unstable
cd "$base"/.codectmp
/usr/bin/ar -p "$base"/.codectmp/chrome-bin.deb data.tar.lzma >> "$base"/.codectmp/data.tar.lzma
tar -xvf "$base"/.codectmp/data.tar.lzma -C "$base"/.codectmp/chrome-unstable

if [ -f "$base"/.codectmp/data.tar.lzma ]; then
	echo "download & extraction complete"
	sleep 3
	rm "$base"/.codectmp/chrome-bin.deb
	rm "$base"/.codectmp/data.tar.lzma
else
	echo "something went wrong - aborting!"
	mount -o remount, r /
	exit 1;
fi

echo "Installing Adobe Plugins & MP3 Codec" && sleep 5
#codecs
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/libffmpegsumo.so "/opt/google/chrome" -f
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/libpdf.so "/opt/google/chrome" -f

#endless loop with an info file http://html5video.org/kaltura-player/kWidget/onPagePlugins/widevineMediaOptimizer/widevineMediaOptimizer.html
#cp "$base"/chrome-unstable/opt/google/chrome-unstable/libwidevinecdm.so "/opt/google/chrome" -f
#cp "$base"/chrome-unstable/opt/google/chrome-unstable/libwidevinecdmadapter.so "/opt/google/chrome" -f
#libs?
cp -R "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/lib /opt/google/chrome
#flash
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/libpepflashplayer.so /opt/google/chrome/pepper/ -f
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json /opt/google/chrome/pepper/ -f
flashversion=`cat "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json | grep version | sed 's/[^0-9.]*//g'`
echo -e "FILE_NAME=/opt/google/chrome/pepper/libpepflashplayer.so\nPLUGIN_NAME=\"Shockwave Flash\"\nVERSION=\"$flashversion\"\nVISIBLE_VERSION=\"$flashversion\"\nMIME_TYPES=\"application/x-shockwave-flash\"" >/opt/google/chrome/pepper/pepper-flash.info

#remove chrome-dir
rm -rf "$base"/.codectmp/chrome-unstable
#remount the rootfs
mount -o remount, r /

#installation status
if [-f /opt/google/talkplugin/GoogleTalkPlugin]; then
		echo "GTalkPlugin		OK"
else
		echo "GTalkPlugin		FAILED"
fi
if [-f /opt/google/chrome/pepper/libnetflixhelper.so]; then
		echo "NetflixPlugin		OK"
else
		echo "NetflixPlugin		FAILED"
fi
if [-f /opt/google/chrome/pepper/libpepflashplayer.so]; then
		echo "FlashPlugin		OK"
else
		echo "FlashPlugin		FAILED"
fi
if [-f /opt/google/chrome-unstable/libpdf.so]; then
		echo "PDFPlugin			OK"
else
		echo "PDFPlugin			FAILED"
fi
echo "done, rebooting in 5 seconds"
sleep 5
#reboot
