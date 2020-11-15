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
MDIR='/opt/sifter/modules/mPlug'

cd ${MDIR}/evolve
echo -e "${RED}"
figlet -f mini "Evolve"
echo -e "${NC}"
echo -e "${YLW}Please enter the full path/to/RAMDump"
read RDUMP
echo -e "${W}Would you like to use a specific memory profile? ${YLW}eg. ${ORNG}WinXPSP2x86 ${W}(y/n)${NC}"
read POPT
if [[ ${POPT} == "y" ]]; then
	PRO='--profile'
	echo -e "${YLW}Please enter the Memory profile to use${NC}"
	read FILE
	PROFILE="${PRO} ${FILE}"
else
	PROFILE=''
fi
echo -e "${YLW}Would you like to manually specific extra volatililty plugins to use? ${W}(y/n)${NC}"
read VPLUG
if [[ ${VLUG} == "y" ]]; then
	VP='--plugins'
	echo -e "${W}Please specify the full path/to/volatility_plugins${NC}"
	read VPTH
	VPATH="${VP} ${VPTH}"
else
	VPATH=''
fi

python evolve.py -f ${RDUMP} --local -w 8181 ${PROFILE} ${VPATH} 