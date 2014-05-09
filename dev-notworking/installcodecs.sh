#!/bin/bash
base="$(dirname "$(readlink -f "${0}")")"

#codecs are only available for x86 cpus
if [ `uname -m` == 'x86_64' ]; then
	chromeurl="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
	gtalkurl="https://drive.google.com/file/d/0B_2_dsXrefR-RUcxbXhhUEdSdXc/edit?usp=sharing"
	netflixurl="https://drive.google.com/file/d/0B_2_dsXrefR-UWV3czFqTWpmSEE/edit?usp=sharing"
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

#download ar
echo "downloading GNU ar"
sleep 3
wget --progress=dot "$arurl" -O /usr/bin/ar 2>&1 | grep --line-buffered "%"
clear
if [ -f /usr/bin/ar ]; then
	echo "ar found"
	sleep 3
else
	echo "couldn't find ar - something went wrong - aborting!"
	mount -o remount, r /
	exit 1;
fi

#creating the pepper dir and a tmpdir
mkdir -p /opt/google/chrome/pepper
mkdir -p "$base"/.codectmp

#download peppertalk
if [ -f "$base"/.codectmp/google-talk-pepper.txz ]; then
	echo "gtalk found"
	sleep 3
else
	echo "downloading peppertalk"
	sleep 3
	wget --progress=dot "$gtalkurl" -O "$base"/.codectmp/google-talk-pepper.txz 2>&1 | grep --line-buffered "%"
	clear
fi

if [ -f "$base"/.codectmp/google-talk-pepper.txz ]; then
	echo "extracting peppertalk"
	sleep 3
	cd /
	tar xvJf "$base"/.codectmp/google-talk-pepper.txz
	if [-f /opt/google/talkplugin/GoogleTalkPlugin]; then
		echo "GTalkPlugin installed"
	else
		echo "FAIL (-_-)"
else
	echo "couldn't download peppertalk (-_-)"
fi

#download netflix
if [ -f "$base"/.codectmp/netflixhelper.txz ]; then
	echo "netflix found"
	sleep 3
else
	echo "downloading netflixplugin"
	sleep 3
	wget --progress=dot "$netflixurl" -O "$base"/.codectmp/netflixhelper.txz 2>&1 | grep --line-buffered "%"
	clear
fi

if [ -f "$base"/.codectmp/netflixhelper.txz ]; then
	echo "extracting netflixplugin"
	sleep 3
	cd /
	tar xvJf "$base"/.codectmp/netflixhelper.txz
	if [-f /opt/google/chrome/pepper/libnetflixhelper.so]; then
		echo "Netflix Plugin installed"
	else
		echo "FAIL (-_-)"
else
	echo "couldn't download netflixplugin (-_-)"
fi

#adobe stuff
clear
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
echo "done, cross fingers and reboot"
sleep 5
echo "PS: type reboot to reboot :P"
