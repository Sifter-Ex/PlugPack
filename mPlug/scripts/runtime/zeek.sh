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

runtime(){
	echo -e "${RED}"
	figlet -f mini "ZeeK"
	echo -e "${NC}"
	echo -e "${YLW}[ ${LP}! ${YLW}] ${RED}NOTE: ${W}When you are done with zeek close this window.${NC}"
	sleep 5
	echo -e "${YLW}============================\n ${W}Zeek runtime options:${NC}"
	sudo docker run -it --rm blacktop/zeek
	echo -e "${YLW}============================${NC}"
	echo -e "${ORNG}Please enter the flags to use along with valid variables (${INV}please use single quotes ${LP}' '${INV} if needed${ORNG})${NC}"
	read VARS
	sudo docker run -it --rm blacktop/zeek ${VARS}
	runtime
}
runtime