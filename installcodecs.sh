#!/bin/bash
#based on https://wiki.archlinux.org/index.php/Chromium
#based on https://gist.github.com/dz0ny/3065781
base="$(dirname "$(readlink -f "${0}")")"
chromebrewbinutils="https://raw.githubusercontent.com/skycocker/chromebrew/master/packages/binutils.rb"

#codecs are only available for x86 cpus
if [ $(uname -m) != "i686" ] && [ $(uname -m) != "x86_64" ]; then
  echo 'Only Intel x86 compatible CPUs are supported'
  exit 1;
fi

#chrome links
if [ `uname -m` == 'x86_64' ]; then
  # 64-bit
  export CHROME="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
else
  # 32-bit
  export CHROME="https://dl-ssl.google.com/linux/direct/google-chrome-unstable_current_i386.deb"
fi

##checkforoldcrap
cd "$base"
if [ -f "$base"/chrome-bin.deb ]; then
	echo "deleting crap"
	rm "$base"/chrome-bin.deb
else
	echo "..."
fi

if [ -f "$base"/chrome.tar.lzma ]; then
	echo "deleting crap"
	rm "$base"/chrome.tar.lzma
else
	echo "..."
fi

if [ -d "$base"/chrome-unstable ]; then
	echo "deleting crap"
	rm -rf "$base"/chrome-unstable
else
	echo "..."
fi

#remount the root partition
echo "remount rootfs" && sleep 5
mount -o remount, rw /

#gettingbinutils
echo "downloading binutils" && sleep 5
wget "$chromebrewbinutils" -O "$base"/binutils.rb
binutilsurl=`cat "$base"/binutils.rb | grep "https://" | grep "$(uname -m)" | tr "'" '"' | sed -n '/"/!{/\n/{P;b}};s/"/\n/g;D'`
wget --progress=dot $binutilsurl -O "$base"/binutils.tgz
tar -zxvf "$base"/binutils.tgz usr/local/$(uname -m)-pc-linux-gnu/bin/ar
cp "$base"/usr/local/$(uname -m)-pc-linux-gnu/bin/ar /usr/bin

if [ -f /usr/bin/ar ]; then
	echo "ar found"
	rm -rf "$base"/usr
	rm -f "$base"/binutils.*
else
	echo "couldn't find ar - something went wrong - aborting!"
	exit 1;
fi

#remove that ugly string at the login screen
sed -i '/CHROMEOS_RELEASE_DESCRIPTION/d' /etc/lsb-release

#codecs and other cool stuff
echo "Downloading codecs" && sleep 5
wget --progress=dot $CHROME -O "$base"/chrome-bin.deb
mkdir "$base"/chrome-unstable
/usr/bin/ar -p "$base"/chrome-bin.deb data.tar.lzma >> "$base"/data.tar.lzma
tar -xvf "$base"/data.tar.lzma -C "$base"/chrome-unstable

if [ -f "$base"/data.tar.lzma ]; then
	echo "success" && sleep 5
    rm "$base"/chrome-bin.deb
    rm "$base"/data.tar.lzma
else
	echo "something went wrong - aborting!"
	exit 1;
fi

echo "Installing codecs" && sleep 5
#codecs
cp "$base"/chrome-unstable/opt/google/chrome-unstable/libffmpegsumo.so "/opt/google/chrome" -f
cp "$base"/chrome-unstable/opt/google/chrome-unstable/libpdf.so "/opt/google/chrome" -f

#that stuff won't work even if loaded with an info file
#cp "$base"/chrome-unstable/opt/google/chrome-unstable/libppGoogleNaClPluginChrome.so "/opt/google/chrome" -f
#cp "$base"/chrome-unstable/opt/google/chrome-unstable/libwidevinecdm.so "/opt/google/chrome" -f
#cp "$base"/chrome-unstable/opt/google/chrome-unstable/libwidevinecdmadapter.so "/opt/google/chrome" -f
#libs?
cp -R "$base"/chrome-unstable/opt/google/chrome-unstable/lib /opt/google/chrome
#flash
mkdir -p /opt/google/chrome/pepper
cp "$base"/chrome-unstable/opt/google/chrome-unstable/PepperFlash/libpepflashplayer.so /opt/google/chrome/pepper/ -f
cp "$base"/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json /opt/google/chrome/pepper/ -f
flashversion=`cat "$base"/chrome-unstable/opt/google/chrome-unstable/PepperFlash/manifest.json | grep version | sed 's/[^0-9.]*//g'`
echo -e "FILE_NAME=/opt/google/chrome/pepper/libpepflashplayer.so\nPLUGIN_NAME=\"Shockwave Flash\"\nVERSION=\"$flashversion\"\nVISIBLE_VERSION=\"$flashversion\"\nMIME_TYPES=\"application/x-shockwave-flash\"" >/opt/google/chrome/pepper/pepper-flash.info

#remove chrome-dir
rm -rf "$base"/chrome-unstable

echo "done, cross fingers and reboot"
sleep 5
echo "PS: type reboot to reboot :P"
