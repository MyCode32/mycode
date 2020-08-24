#!/usr/bin/env bash

mycode_check_ap() {
  readonly SUPPORT_AP=$(sed -n -e "$(echo $(($1+4)))p" devices.xml | cut -d ">" -f2 | cut -d "<" -f1)
  echo "$SUPPORT_AP"
}

mycode_check_mo() {
  readonly SUPPORT_MO=$(sed -n -e "$(echo $(($1+6)))p" devices.xml | cut -d ">" -f2 | cut -d "<" -f1)
  echo "$SUPPORT_MO"
}

# first identifier
mycode_check_chipset() {
  declare -r LINE=$(grep "$1" devices.xml -n | head -n 1 | cut -d ":" -f1)

  if [ "$(mycode_check_ap "$LINE")" == "n" ] || [ "$(mycode_check_mo "$LINE")" == "n" ];then
    echo "false"
  else
	  if [ "$(mycode_check_ap "$LINE")" == "?" ] || [ "$(mycode_check_mo "$LINE")" == "?" ];then
	    echo "Chipset not in list"
	  else
	    echo "true"
	  fi
  fi
}

mycode_check_chipset "$1"
