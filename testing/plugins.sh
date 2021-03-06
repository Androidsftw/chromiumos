#!/bin/bash
# See https://github.com/sixsixfive/chromiumos for details.
base="$(dirname "$(readlink -f "${0}")")"

#amd64 only, srsly every CPU since 2008(Atom Diamondville) supports 64Bit :P
if [ `uname -m` == 'x86_64' ]; then
	chromeurl="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
	gtalkurl="https://googledrive.com/host/0B_2_dsXrefR-cVhtM2c4c2xYS1E/google-talk-pepper-amd64.txz"
	netflixurl="https://googledrive.com/host/0B_2_dsXrefR-cVhtM2c4c2xYS1E/netflixhelper-amd64.txz"
	arurl="https://googledrive.com/host/0B_2_dsXrefR-cVhtM2c4c2xYS1E/ar-amd64.txz"
else
	echo 'Only amd64 compatible CPUs are supported'
	exit 1;
fi

#remount the root partition
echo "remounting rootfs"
sleep 3
mount -o remount, rw /

#creating the pepper dir and a tmpdir
mkdir -p /opt/google/chrome/pepper
mkdir -p /usr/lib/cromo/
mkdir -p "$base"/.codectmp

#gapikeys to get drive working
read -p "To use GDrive you need an API-Key (Press Y to set, anything else to skip)" -n 1 -r
echo -e "\nHow to get keys? http://www.chromium.org/developers/how-tos/api-keys"
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
	sed -i '/GOOGLE_API_KEY/d' /etc/chrome_dev.conf
	sed -i '/GOOGLE_DEFAULT_CLIENT_ID/d' /etc/chrome_dev.conf
	sed -i '/GOOGLE_DEFAULT_CLIENT_SECRET/d' /etc/chrome_dev.conf
	if [ -f "$base"/.codectmp/gapikey ]; then
		gapikey=`cat "$base"/.codectmp/gapikey`
	else
		read -p "Please enter your API key(for browser applications):" -r gapikey
		echo "$gapikey" > "$base"/.codectmp/gapikey
	fi
	if [ -f "$base"/.codectmp/gclientid ]; then
		gclientid=`cat "$base"/.codectmp/gclientid`
	else
		read -p "Please enter your Client ID(for native applications):" -r gclientid
		echo "$gclientid" > "$base"/.codectmp/gclientid
	fi
	if [ -f "$base"/.codectmp/gclientsecret ]; then
		gclientsecret=`cat "$base"/.codectmp/gclientsecret`
	else
		read -p "Please enter your Client secret(for native applications):" -r gclientsecret
		echo "$gclientsecret" > "$base"/.codectmp/gclientsecret
	fi
sed -i "2iGOOGLE_API_KEY=$gapikey" /etc/chrome_dev.conf
sed -i "3iGOOGLE_DEFAULT_CLIENT_ID=$gclientid" /etc/chrome_dev.conf
sed -i "4iGOOGLE_DEFAULT_CLIENT_SECRET=$gclientsecret" /etc/chrome_dev.conf
fi

#download ar
if [ -f "$base"/.codectmp/ar.txz ]; then
	echo "GNU ar found"
	sleep 3
else
	echo "downloading GNU ar"
	sleep 3
	wget --progress=dot "$arurl" -O "$base"/.codectmp/ar.txz 2>&1 | grep --line-buffered "%"
fi

if [ -f "$base"/.codectmp/ar.txz ]; then
	echo "installing GNU ar"
	sleep 3
	cd /
	tar xfJ "$base"/.codectmp/ar.txz
	chmod +x /usr/bin/ar
	if [ -f /usr/bin/ar ]; then
		echo "GNU ar installed"
	else
		echo "couldn't find ar - something went wrong - aborting!"
		mount -o remount, r /
		exit 1;
	fi
else
	echo "couldn't download ar (-_-)"
	mount -o remount, r /
	exit 1;
fi

#download peppertalk
if [ -f "$base"/.codectmp/google-talk-pepper.txz ]; then
	echo "gtalk found"
	sleep 3
else
	echo "downloading peppertalk"
	sleep 3
	wget --progress=dot "$gtalkurl" -O "$base"/.codectmp/google-talk-pepper.txz 2>&1 | grep --line-buffered "%"
fi

if [ -f "$base"/.codectmp/google-talk-pepper.txz ]; then
	echo "extracting peppertalk"
	sleep 3
	cd /
	tar xfJ "$base"/.codectmp/google-talk-pepper.txz
	if [ -f /opt/google/talkplugin/GoogleTalkPlugin ]; then
		echo "GTalkPlugin installed"
	else
		echo "FAIL (-_-)"
	fi
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
fi

if [ -f "$base"/.codectmp/netflixhelper.txz ]; then
	echo "extracting netflixplugin"
	sleep 3
	cd /
	tar xfJ "$base"/.codectmp/netflixhelper.txz
	if [ -f /opt/google/chrome/pepper/libnetflixhelper.so ]; then
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

rm -rf "$base"/.codectmp/chrome-unstable
mkdir "$base"/.codectmp/chrome-unstable
cd "$base"/.codectmp
/usr/bin/ar -p "$base"/.codectmp/chrome-bin.deb data.tar.lzma >> "$base"/.codectmp/data.tar.lzma
tar -xf "$base"/.codectmp/data.tar.lzma -C "$base"/.codectmp/chrome-unstable

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

echo "Installing Adobe Plugins & MP3 Codec"
sleep 3
#codecs
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/libffmpegsumo.so "/opt/google/chrome" -f
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/libffmpegsumo.so "/usr/lib/cromo" -f
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/libpdf.so "/opt/google/chrome" -f
#libs?
cp -R "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/lib /opt/google/chrome
#flash
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/libpepflashplayer.so /opt/google/chrome/pepper/ -f
cp "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json /opt/google/chrome/pepper/ -f
flashversion=`cat "$base"/.codectmp/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json | grep version | sed 's/[^0-9.]*//g'`
echo -e "FILE_NAME=/opt/google/chrome/pepper/libpepflashplayer.so\nPLUGIN_NAME=\"Shockwave Flash\"\nVERSION=\"$flashversion\"\nVISIBLE_VERSION=\"$flashversion\"\nMIME_TYPES=\"application/x-shockwave-flash\"" >/opt/google/chrome/pepper/pepper-flash.info

#remove chrome-dir
rm -rf "$base"/.codectmp/chrome-unstable

#installation status
if [ -f /opt/google/talkplugin/GoogleTalkPlugin ]; then
		echo "GTalkPlugin		OK"
else
		echo "GTalkPlugin		FAILED"
fi
if [ -f /opt/google/chrome/pepper/libnetflixhelper.so ]; then
		echo "NetflixPlugin		OK"
else
		echo "NetflixPlugin		FAILED"
fi
if [ -f /opt/google/chrome/pepper/libpepflashplayer.so ]; then
		echo "FlashPlugin		OK"
else
		echo "FlashPlugin		FAILED"
fi
if [ -f /opt/google/chrome/libpdf.so ]; then
		echo "PDFPlugin			OK"
		echo "enabling Chrome Print preview"
		sed -i 's/\${DEVELOPER_MODE_FLAG}/\${DEVELOPER_MODE_FLAG} \\/g' /etc/chrome_dev.conf
		#http://peter.sh/experiments/chromium-command-line-switches/
		echo -e "\t\t\t--enable-print-preview" >>/etc/chrome_dev.conf
else
		echo "PDFPlugin			FAILED"
fi
#remount the rootfs
mount -o remount, r /
echo "done, rebooting in 5 seconds"
sleep 5
reboot
