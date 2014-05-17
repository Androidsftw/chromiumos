#!/bin/bash
base="$(dirname "$(readlink -f "${0}")")"

#only x86, arm might come later
if [ `uname -m` == 'x86_64' ]; then
	chromeurl="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
	arurl="https://googledrive.com/host/0B_2_dsXrefR-cVhtM2c4c2xYS1E/ar-amd64.txz"
elif [ `uname -m` == 'i686' ]; then
	chromeurl="https://dl.google.com/linux/direct/google-chrome-unstable_current_i386.deb"
	arurl="https://googledrive.com/host/0B_2_dsXrefR-cVhtM2c4c2xYS1E/ar-x86.txz"
else
	echo 'Only x86 compatible CPUs are supported'
	exit 1;
fi

#remount the root partition
echo "remounting rootfs"
sleep 3
mount -o remount, rw /

#creating the pepper dir and a tmpdir
mkdir -p /opt/google/chrome/pepper
mkdir -p "$base"/.codectmp

#gapikeys to get drive working
read -p "To use GDrive you need an API-Key (Press Y to set, anything else to skip)" -n 1 -r
echo -e "\nHow to get keys? http://www.chromium.org/developers/how-tos/api-keys"
echo -e "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
	sed -i '/GOOGLE_API_KEY/d' /sbin/session_manager_setup.sh
	sed -i '/GOOGLE_DEFAULT_CLIENT_ID/d' /sbin/session_manager_setup.sh
	sed -i '/GOOGLE_DEFAULT_CLIENT_SECRET/d' /sbin/session_manager_setup.sh
	if [ -f "$base"/.codectmp/gapikey ]; then
		gapikey=`cat "$base"/.codectmp/gapikey`
	else
		read -p "Please enter your API key(for browser applications):" -r gapikey
		echo "$gapikey" > "$base"/.codectmp/gapikey
	fi
	if [ -f "$base"/.codectmp/gclientid ]; then
		gclienid=`cat "$base"/.codectmp/gclientid`
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
sed -i "2iexport GOOGLE_API_KEY=$gapikey" /sbin/session_manager_setup.sh
sed -i "3iexport GOOGLE_DEFAULT_CLIENT_ID=$gclientid" /sbin/session_manager_setup.sh
sed -i "4iexport GOOGLE_DEFAULT_CLIENT_SECRET=$gclientsecret" /sbin/session_manager_setup.sh
fi

#updates
sed -i 's/http:\/\/chromebld01.test.private/http:\/\/chromebld.arnoldthebat.co.uk/g' /etc/lsb-release

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
if [ -f /opt/google/chrome/pepper/libpepflashplayer.so ]; then
		echo "FlashPlugin		OK"
else
		echo "FlashPlugin		FAILED"
fi
if [ -f /opt/google/chrome/libpdf.so ]; then
		echo "PDFPlugin			OK"
		echo "enabling Chrome Print preview"
		sed -i 's/\${DEVELOPER_MODE_FLAG}/\${DEVELOPER_MODE_FLAG} \\/g' /sbin/session_manager_setup.sh
		#http://peter.sh/experiments/chromium-command-line-switches/
		echo -e "\t\t\t--enable-print-preview" >>/sbin/session_manager_setup.sh
else
		echo "PDFPlugin			FAILED"
fi
#remount the rootfs
mount -o remount, r /
echo "done, rebooting in 5 seconds"
sleep 5
reboot
