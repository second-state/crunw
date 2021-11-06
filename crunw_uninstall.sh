#!/bin/bash
#WARNING: THIS FILE WILL AUTOMATICALLY REMOVE A LOT OF PACKAGES. PLEASE UNDERSTAND WHAT IS RUNNING BELOW AND DO NOT USE THIS AUTOMATED REMOVAL TOOL IF YOU ARE NOT SURE
echo -e "Removing packages, please wait ..."
export OS="xUbuntu_20.04"
export VERSION="1.21"
export DEST1="/etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
export DEST2="/etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list"
sudo rm -rf "$DEST1"
sudo rm -rf "$DEST2"
sudo apt purge -y libseccomp2
sudo apt autoremove -y
sudo apt purge -y criu
sudo apt autoremove -y
sudo apt purge -y libyajl2
sudo apt autoremove -y
sudo apt purge -y cri-o
sudo apt autoremove -y
sudo apt purge -y cri-o-runc
sudo apt autoremove -y
sudo apt purge -y cri-tools
sudo apt autoremove -y
sudo apt purge -y containernetworking-plugins
sudo apt autoremove -y
sudo rm -rf ~/.wasmedge
echo -e "Finished"
