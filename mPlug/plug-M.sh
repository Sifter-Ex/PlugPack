#!/bin/bash
ORNG='\033[0;33m'
NC='\033[0m'
W='\033[1;37m'
LP='\033[1;35m'
YLW='\033[1;33m'
LBBLUE='\e[104m'
RED='\033[0;31m'
LGRY='\033[0;37m'
INV='\e[7m'
BRED='\033[1;31m'
UPURPLE='\033[4;35m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
UBLUE='\033[4;34m'
URED='\033[4;31m'
WORKDIR=$(pwd)
MDIR='/opt/sifter/modules/mPlug'

depIn(){
	echo -e "${BRED}Installing DependancyWalker${NC}"
	cd
	if [[ -d '.wine' ]]; then
		if [[ ! -d '.local/share/wineprefixes' ]]; then
			mkdir .local/share/wineprefixes
		fi
		mv .wine .local/share/wineprefixes/default_1
	fi
	sudo apt-get install winetricks wine wine64 libgettextpo0 libwine-dev libwinpr2-2 wine64-tools q4wine wine-binfmt winexe
	wine64 ipconfig &>/dev/null
	echo -e " ${W}====================================================================${NC}"
	echo -e " ${BIGreen}[ ${LP}1 ${BIGreen}] ${ORNG}Winetricks will now open, please select the default prefix${NC}"
	echo -e "\n ${BIGreen}[ ${LP}2 ${BIGreen}] ${ORNG}Then select ${W}Install a Windows component or dll${NC}"
	echo -e "\n ${BIGreen}[ ${LP}3 ${BIGreen}] ${ORNG}Please ensure ${W}vc6run & vc6runSp6 ${ORNG}are selected for install and click ${LGRY}OK${NC}"
	echo -e " ${W}====================================================================${NC}"
	cd /opt/sifter/modules/mPlug/DepWalker
	mkdir 32
	cd 32 && unzip ../depends22_x86.zip
	mkdir 64
	cd 64 && unzip ../depends22_x64.zip
	echo -e "${RED}[ ${W}! ${RED}] ${BIGreen}Checking if DependancyWalker has been installed properly\n If everything is OK DepWalker should open. Please close it once it has to complete the M Plugin install${NC}"
	sleep 5
	wine depends.exe
	echo -e "${YLW}Did DepWalker open correctly? ${W}(y/n)${NC}"
	read DWI6
	if [[ ${DWI6} == "n" ]]; then
		cd ../32
		echo -e "${YLW}Trying to open DepWalker again, please close it once it opens.${NC}"
		sleep 5
		wine depends.exe
		echo -e "${YLW}Did DepWalker open correctly? ${W}(y/n)${NC}"
		read DWI3
		if [[ ${DWI3} == "n" ]]; then
			echo -e "${RED}DepWalker will now be reinstalled. Please ensure the steps are correctly followed or open an issue on ${W}Github${NC}"
			sleep 5
			depWalk
		else
			cd ..
			rm -rf 64
			mv 32 /opt/sifter/modules/mPlug/DepWalk
		fi
	else
		cd ..
		rm -rf 32
		mv 64 /opt/sifter/modules/mPlug/DepWalk
	fi
}

# Evolve
evoIn(){
	echo -e "${BRED}Installing Evolve${NC}"
	cd ${MDIR}
	git clone https://github.com/JamesHabben/evolve
	cd evolve
	echo -e "${YLW}[${ORNG}!${YLW}] ${LP}Installing Dependancies for Evolve\n${LGRY}: ${RED}Volatility${NC}"
	git clone https://github.com/volatilityfoundation/volatility
	cd volatility
	sudo python2 setup.py install
	sudo python2 -m pip install yara bottle distorm3 maxminddb
}

# OleTools (Python3)
oleIn(){
	echo -e "${BRED}Installing OleTools${NC}"
	cd ${MDIR}
	git clone https://github.com/decalage2/oletools
	sudo python3 -m pip install oletools
}

# VirusTotal Desktop Uploader
vtIn(){
	echo -e "${BRED}Installing VirusTotal Desktop Uploader${NC}"
	cd ${MDIR}
	mkdir VTU
	# get dependencies
	sudo apt-get install build-essential qtchooser qt5-default libjansson-dev libcurl4-openssl-dev git zlib1g-dev
	# clone the c-vtapi library
	git clone https://github.com/VirusTotal/c-vtapi.git
	#change to c-vtapi directory
	cd c-vtapi
	# get c-vtapi dependencies
	sudo apt-get install automake autoconf libtool libjansson-dev libcurl4-openssl-dev
	# configure with default options and make
	autoreconf -fi && ./configure && make
	# install to system, by default this goes to /usr/local/lib
	sudo make install 
	# configure dynamic linker to add /usr/local/lib to path
	sudo sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf'
	sudo ldconfig
	# go back to base directory
	cd ..
	#clone QT VirusTotal Uplaoder
	git clone https://github.com/VirusTotal/qt-virustotal-uploader.git
	cd qt-virustotal-uploader
	# run qmake, specifing qt5 
	qtchooser -run-tool=qmake -qt=5
	# compile with 4 parellel jobs
	make -j4
	echo -e "${BIGreen}Would you like to install the VirusTotal Uploader to (${YLW}s${BIGreen})ystem or use by (${YLW}i${BIGreen})nvoking script? (${YLW}s/i${BIGreen})${NC}"
	read VTOPT
	if [[ ${VTOPT} == "s" ]]; then
		#optionally install 
		sudo make install
	else
		sudo ln -s -r VirusTotalUploader /usr/sbin
	fi
}

REMIn(){
	echo -e "${BRED}REMNux Install ${NC}"
	echo -e "${RED}REMNux ${YLW}will require either VirtualBox or VMWare to run.\nA link to the OVA file from REMNux will be provided for manual download as the file is large${NC}"
	echo -e "${W}Would you like to download the REMNux ova Virtual Machine? (y/n)${NC}"
	read REMO
	if [[ ${REMO} == "y" ]]; then
		echo -e "${ORNG}You can download REMNux ova provided directly by REMNux from:\n - https://drive.google.com/u/0/uc?export=download&confirm=m5P_&id=12RCtE9_5fd1hsfiFmQi-kOlW7nPj59Y8"
	fi
}

lolcat .inc/ban
# Initial mPlug Dir Check
if [[ ! -d '/opt/sifter/modules/mPlug' ]]; then
	mkdir /opt/sifter/modules/mPlug
	cp -r ${WORKDIR}/scripts/* -t ${MDIR}
	cp -r .git -t /opt/sifter/modules/mPlug
fi

################
# Tool Install #
################
depIn
evoIn
vtIn
oleIn
REMIn

# Clean Up
cd 
sudo rm -rf ${WORKDIR}
