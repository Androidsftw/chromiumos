This installs even more plugins (currently [amd64](http://en.wikipedia.org/wiki/X86-64) builds only!).

## Install

* close all & open crosh: **Press CTRL+ALT+T**
* Enter: **`shell`**
* Navigate to the Downloads dir: **`cd ~/Downloads`**
* Download the script: **`wget http://goo.gl/9T2hrI -O plugins.sh`**
* Become root: **`sudo su`**
* Run the script: **`bash plugins.sh`**

### Update

if you updated to the latest dev server you need to rerun the script in Downloads

* close all & open crosh: **Press CTRL+ALT+T**
* Enter: **`shell`**
* Navigate to the Downloads dir: **`cd ~/Downloads`**
* Become root: **`sudo su`**
* Run the script: **`bash plugins.sh`**

### If something goes wrong

This script will create a hidden dir in your ~/Downloads folder to make updates easier so if you want to change your API keys you have to remove it first

* close all & open crosh: **Press CTRL+ALT+T**
* Enter: **`shell`**
* Navigate to the Downloads dir: **`cd ~/Downloads`**
* Become root: **`sudo su`**
* Delete the tmp dir: rm -drf .codectmp
