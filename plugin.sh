#!/bin/bash
WD=$(pwd)
# All Plugins
all(){
	cd ${WD}/cPlug; bash plug-C.sh
	cd ${WD}/fPlug; bash plug-F.sh
	cd ${WD}/gPlug; bash plug-G.sh
	cd ${WD}/mPlug; bash plug-M.sh
}
# Malware Analysis
mP(){
	cd ${WD}/mPlug; bash plug-M.sh
}
# Cobalt Strike runtime
cP(){
        cd ${WD}/cPlug; bash plug-C.sh
}
# Sifter GUI
gP(){
        cd ${WD}/gPlug; bash plug-G.sh
}
# DanderFuzz Framework
fP(){
        cd ${WD}/fPlug; bash plug-F.sh
}
if [[ ! -d '/opt/sifter' ]]; then
        echo -e "${RED}Sifter is not installed! ${YLW}Would you like to install it now? ${W}(y/n)${NC}"
        read SI
        if [[ ${SI} == "n" ]]; then
                exit 1
        else
		git clone https://github.com/s1l3nt78/sifter; cd sifter; bash install.sh
	fi
fi
echo -e "${YLW}Please enter the plugins to be installed ${ORNG}eg. ${W}cmf${NC}\n${YLW}If you would like to install them all, enter ${W}A${NC}"
read INS
echo ${INS} > ~/.plugging
AP=$(cat ~/.plugging | grep A)
if [[ ${AP} == "A" ]]; then
	allP
else
	# Check if cPlug is selected
	CC=$(cat ~/.plugging | grep c)
	if [[ ${CC} == "c" ]]; then
		cP
	fi
	# Check if fPlug is selected
	FC=$(cat ~/.plugging | grep f)
	if [[ ${FC} == "f" ]]; then
		fP
	fi
	# Check if gPlug is selected
	GC=$(cat ~/.plugging | grep g)
        if [[ ${GC} == "g" ]]; then
                gP
        fi
	# Check if mPlug is selected
	MC=$(cat ~/.plugging | grep m)
        if [[ ${CC} == "m" ]]; then
                mP
        fi
fi
rm ~/.plugging
