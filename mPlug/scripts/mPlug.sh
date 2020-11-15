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
MDIR='/opt/sifter/modules/mPlug'

mpopt(){
    echo -e "${RED}"
    figlet -f mini "Malware Analysis Plugin"
    echo -e "${ORNG}"
    ASTAT=$(cat /home/$USER/.config/.anon_status)
    echo -e "${EXC} ${BIGreen}Anonymous: ${BIYellow}${ASTAT}${NC}"
    echo -e " ${W}==================================================\n ${ORNG}Which tool would you like to use?\n ${W}==================================================${NC}"
    echo -e "\n ${ORNG}1.${W} OleTools           ${ORNG}4.${W} DependancyWalker ${NC}"
    echo -e " ${ORNG}2.${W} Evolve             ${ORNG}5.${W} Zeek ${NC}"
    echo -e " ${ORNG}3.${W} VT-Uploader        ${ORNG}6.${W} Back ${NC}"
    echo -e " ${W}"
    echo -n " =============================#?: "
    read MPM
    if [[ ${MPM} == "1" ]]; then
        bash /opt/sifter/modules/mPlug/runtime/oletools.sh
    elif [[ ${MPM} == "2" ]]; then
        bash /opt/sifter/modules/mPlug/runtime/evolve.sh
    elif [[ ${MPM} == "3" ]]; then
        VirusTotalUploader &
    elif [[ ${MPM} == "4" ]]; then
        wine /opt/sifter/modules/mPlug/DepWalk/depends.exe &
    elif [[ ${MPM} == "5" ]]; then
        xterm -e bash /opt/sifter/modules/mPlug/runtime/zeek.sh &
    elif [[ ${MPM} == "6" ]]; then
            exit
    else
            echo -e "${YLW}[ ${RED}! ${YLW}] ${W}Invalid option chosen, please select the corresponding number\n${LP}eg. ${BIGreen} 2 = Evolve${NC}"
            mpopt
    fi
}
mpopt