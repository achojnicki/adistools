#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

run() {
	prompt_char='$'
	if [ "$EUID" == 0 ]
	  then 
	  	prompt_char="#"
	  exit
	fi

	command=$*
	output=`$* 2>&1`
	exit_code=$?


	echo $prompt_char $command
	
	if [ $exit_code != 0 ]
  		then 
  			echo -e Status: ${red}Failed${nc}
  			echo $output
  		else
  			echo -e Status: ${green}Succesed${nc}
		fi

}

