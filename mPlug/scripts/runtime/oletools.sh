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

echo -e "${LGRY}==========================================${NC}"
echo -e "\n${ORNG}Tools to analyze malicious documents${NC}"
echo -e "${LGRY}-------------------------------------------${NC}"
echo -e "${LP}oleid${YLW}: to analyze OLE files to detect specific characteristics usually found in malicious files."
echo -e "${LP}olevba${YLW}: to extract and analyze VBA Macro source code from MS Office documents (OLE and OpenXML)."
echo -e "${LP}MacroRaptor${YLW}: to detect malicious VBA Macros"
echo -e "${LP}msodde${YLW}: to detect and extract DDE/DDEAUTO links from MS Office documents, RTF and CSV"
echo -e "${LP}pyxswf${YLW}: to detect, extract and analyze Flash objects (SWF) that may be embedded in files such as MS Office documents (e.g. Word, Excel) and RTF, which is especially useful for malware analysis."
echo -e "${LP}oleobj${YLW}: to extract embedded objects from OLE files."
echo -e "${LP}rtfobj${YLW}: to extract embedded objects from RTF files."
echo -e "${LGRY}==========================================${NC}"
echo -e "${W}Tools to analyze the structure of OLE files${NC}"
echo -e "${LGRY}-------------------------------------------${NC}"
echo -e "${LP}olebrowse${YLW}: A simple GUI to browse OLE files (e.g. MS Word, Excel, Powerpoint documents), to view and extract individual data streams."
echo -e "${LP}olemeta${YLW}: to extract all standard properties (metadata) from OLE files."
echo -e "${LP}oletimes${YLW}: to extract creation and modification timestamps of all streams and storages."
echo -e "${LP}oledir${YLW}: to display all the directory entries of an OLE file, including free and orphaned entries."
echo -e "${LP}olemap${YLW}: to display a map of all the sectors in an OLE file."
echo -e "${LGRY}==========================================${NC}"

echo -n "Please enter the name of the tool you would like to use: "
read TOOL
${TOOL} -h
echo -n "Please add any desired flags for execution: "
read FLAGS
${TOOL} ${FLAGS}