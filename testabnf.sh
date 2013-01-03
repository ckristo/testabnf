#!/bin/bash

#######
#
# A simple script that allows to run tests for checking the correctness 
# of an ABNF-file for parse2
#
# Author: ckristo
# Date: 03.01.2013
# Usage: testabnf <APARSE-JAR> <ABNF-FILE> <TESTS-FILE>
#
#######

scriptname=`basename $0`
usage="Usage: $scriptname <APARSE-JAR> <ABNF-FILE> <TESTS-FILE>"

# function definitions
realpath() {
	if [[ ! "$1" =~ ^\.\.?\/ && ! "$1" =~ ^\/ ]]
	then
		echo "`pwd -P`/$1"
	else
		olddir=$PWD
		fname=${1##*/}
		fdir=${1%/*}
		cd "$fdir" 2> /dev/null || return $?
		echo "`pwd -P`/$fname"
		cd "$olddir" 2> /dev/null || return $?
	fi
	return 0
}

# check arguments
if [ $# -lt 3 ]
then
	echo "Invalid number of arguments!" 1>&2
	echo $usage
	exit 1
fi

# check if $1 is valid -- if aparse.jar exists
if [ ! -e "$1" ]
then
	echo "<APARSE-JAR> doesn't exist!" 1>&2
	echo $usage
	exit 1
fi

# check if $2 exists -- if ABNF-FILE exists
if [ ! -e "$2" ]
then
	echo "<ABNF-FILE> doesn't exist!" 1>&2
	echo $usage
	exit 1
fi
if [[ ! $1 != *.abnf ]]
then
	echo "Invalid <ABNF-FILE>!" 1>&2
	echo $usage
	exit 1
fi

# check if $3 exists -- if TESTS exists
if [ ! -e "$3" ]
then
	echo "<TESTS-FILE> doesn't exist" 1>&2
	echo $usage
	exit 1
fi

# get absolute argument paths
arg1=`realpath $1` || exit 1
arg2=`realpath $2` || exit 1
arg3=`realpath $3` || exit 1

# prepare parser
parser_name=`basename ${2%.abnf}`

# generate temp dir for parser generation
curr_dir=$PWD
temp_dir=`mktemp -d /tmp/${parser_name}_XXXXXX` || exit 1
cd "$temp_dir"

# generate parser
java -cp "$arg1" com.parse2.aparse.Parser "$arg2" || exit 1
javac Parser.java Rule.java Rule_*.java Terminal_*.java ParserContext.java ParserException.java Visitor.java Displayer.java XmlDisplayer.java

ret=0

# perform tests
while read l
do
	# remove sharp comments first
	if [[ $l =~ ^(.*)(\#.*)$ ]]
	then
		l=${BASH_REMATCH[1]}		# remove comment BASH_REMATCH[2]
		l=${l##[![:space:]]}		# remove trailing whitespace char
	fi

	# get sign and command for test
	if [[ ! $l =~ ^([+-])[:space:\ ]+(.+)$ ]]
	then
		continue
	fi
	
	#i=0
	#n=${#BASH_REMATCH[*]}
	#while [[ $i -lt $n ]]
	#do
	#	echo "  BASH_REMATCH[$i]: ${BASH_REMATCH[$i]}"
	#	let i++
	#done
	
	# save matched groups
	sign="${BASH_REMATCH[1]}"
	testcmd="${BASH_REMATCH[2]}"
	
	# perform test case
	result=`java Parser -visitor Displayer -string "$testcmd"`
	success=0
	if [[ "$result" =~ ^"parser error:" ]]
	then
		if [[ "$sign" == "-" ]]
		then
			success=1
		fi
	elif [[ "$result" == "$testcmd" ]]
	then
		if [[ "$sign" == "+" ]]
		then
			success=1
		fi
	else
		echo "Unexpected parser output!" 1>&2
		echo $result
		echo "$testcmd"
		exit 1
	fi

	echo -n "$l => "
	if [ "$success" -eq "1" ]
	then
		tput setaf 2
		echo "success"
		tput sgr0
	else
		tput setaf 1
        echo "fail"
        tput sgr0
	fi
done < "$arg3"

# perform cleanup
rm -rf "$temp_dir"
cd "$curr_dir"

exit "$ret"
