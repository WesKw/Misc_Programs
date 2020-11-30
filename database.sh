#!/bin/bash
#A shell script that lets the use create, view, and modify a database.
#Wesley Kwiecinski
#CSCI330 Section 1
#Assignment 6 - Automobile Database Shell Program
#Due 10/30/2020

cmd=""		#current command
dbname=""	#name of database to modify / view
cmdopts=()	#Command options

#Creates a new database in the current directory with name dbname.
#Args: $1 - dbname, $2 - optional database label
new() {
	if [ "$1" = "" ]	#exit if database name is blank
	then
		echo "dbname is empty!"
		return -1
	fi

	#Check if file exits
	if [ -f "$1" ]
	then
		echo "$1 already exists!"
		return -1
	fi

	touch $1 #create new file

	#if label is empty, print untitled database to new file
	if [ "$2" = "" ]
	then
		echo "Untitled databse" >> "$1"
	else
		echo $2 >> "$1" #otherwise print the command option
	fi

	echo "$1 created successfully."
	return 0
}

#Adds a new record to an existing data file.
#Takes 5 parameters:
#$1 = database name to add to
#Args 2, 3, 5 must be greater than 0 chars
#$2 = Make of the car
#$3 = Model of the car
#$4 = Year of the car. Must be greater than 1870 and less than 2025
#$5 = Color of the car.
add() {
	#check if database exists and is writable
	if [ -w "$1" ]
	then
		#Check if the parameters are valid.
		if [ -n "$2" ] && [ -n "$3" ] && [ -n "$5" ] && [ "$4" -gt 1870 ] && [ "$4" -lt 2025 ]; then
			string="$2 $3 $4 $5"
			sed -i '$ a '"$string"'' $1	#appends string to end of file.
		else
			echo "One of the parameters specified is invalid."
			return -1
		fi
	else
		echo "File is not writable or doesn't exist."
		return -1
	fi

	chmod +rw $1	# change file permissions

	echo "Record added to $1 successfully."
	return 0
}

#Shows records in an existing database.
#Takes up to 4 arguments.
#$1 = database name
#$2 = how many records to show.
#	all - shows all
#	single - shows one record
#	range - shows a range of records
#$3 = if $2 is range, lower bound. If $2 is single, show line at specified number.
#$4 = if $2 is range, upper bound.
show() {
	#Check if database exists and is readable
	if [ -r "$1" ]
	then
		if [ ! -s "$1" ]; then #Check if file is empty
			echo "$1 is empty."
			return 0
		fi
		max=$(wc -l < $1)
		case $2 in
			all)	cat "$1"	#Call cat then exit
				return 0
				;;
			single)	if [ "$3" -ge 1 ] && [ "$3" -le $max ]	#check if value is greater than 0 and less than or equal line count
				then
					#call sed to print line
					sed -n -e "$3 p" $1
					return 0
				else
					#Output error message and exit function
					echo "Not a valid line. (Did you use a number? The number may be outside the file range.)"
					return -1
				fi
				;;
			range)	if [ "$3" -ge 1 ] && [ "$4" -ge 1 ] && [ "$3" -le $max ] && [ "$4" -le $max ]	#Check if both values are greater than or equal to 0
				then
					sed -n -e "$3,$4 p" $1	#Print using range
					return 0
				else
					echo "Invalid range. End range may be too high, or beginning is too low."
					return -1		#Print error if range is invalid
				fi
				;;
			*)	echo "Use specifiers [ all, single, or range ]"	#Print error message and return.
				return -1
				;;
		esac
	else
		echo "File does not exist, or is not readable."
		return -1
	fi
}

#Deletes records from the specified database.
#Uses sed to delete records.
#Args: 	$1 = database name, must exist and be readable and writable.
#	$2 = How many records to delete
#		all - deletes every record except for the label.
#		single - deletes a single record indicated by $3.
#		range - deletes a range of addresses indicated by $3 and $4
#	$3 = [single] - the line to delete, [range] - the beginning line to delete
#	$4 = [range] - the last line to delete.
delete() {
	#Check if file is readable and writable.
	if [ -r "$1" ] && [ -w "$1" ]
	then
		if [ ! -s "$1" ]; then #Check if file is empty
			echo "File is empty."
			return -1
		fi
		max=$(wc -l < $1)
		case $2 in
			all)	sed -i "1!d" $1	#Every line but first
				echo "Deleted successfully."
				return 0
				;;
			single)	if [ "$3" -gt 0 ] && [ "$3" -le $max ]; then #Delete only if line is in the file
					sed -i "$3d" $1		#delete a single line
					echo "Line $3 deleted successfully."
					return 0
				else
					echo "Could not find the specified line."
					return -1
				fi
				;;
			range)	if [ "$3" -gt 0 ] && [ "$3" -le $max ] && [ "$4" -gt 0 ] && [ "$4" -le $max ]; then #Check if range is valid
					sed -i "$3,$4d" $1	#Delete using a range
					echo "Lines $3 to $4 deleted successfully."
					return 0
				else
					echo "Range is invalid."
					return -1
				fi
				;;
			*)	echo "Use specifiers [all, single, or range.]" #Display error if command is invalid
				return -1
				;;
		esac
	else
		echo "File is not readable or writable, or it does not exist."
	fi
	return 0
}

#Counts and prints the number of rows in a database.
#Uses wc to get line totals.
#Args: 	$1 = database name
#Return: number of lines.
count() {
	if [ -r "$1" ]	#Check if file exists and can be read or if filename is empty
	then
		count=$(wc -l < $1)	#store result of wc into variable
		echo $count		#print line total
		return 0
	else
		echo "Missing databse! Does the database exist? Is it readable?"
		return -1	#exit if file can't be found
	fi
}

#Asks for the player to input a command if no args. Will continue after a command is completed
menu() {
	#Loops and waits for user input. Calls a command based on the input.
	while true; do
		read -p "Enter a command. Type 'db help' for help. " dbname cmd cmdopts[0] cmdopts[1] cmdopts[2] cmdopts[3] cmdopts[4]
			case $cmd in
				new) 	new $dbname ${cmdopts[0]}
					;;
				add) 	add $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]} ${cmdopts[3]}
					;;
				show) 	show $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]}
					;;
				delete) delete $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]}
					;;
				count)	count $dbname
					;;
				help)	echo "Format: dbname [new, add, show, delete, count] args"
					;;
				*) 	return 0	#returns on invalid command
					;;
			esac
	done
}

#$1 is always the database name
#calls a function based on the command
if [ "$#" -ge 1 ] #if there are command arguments...
then
	#Store every command option into the array
	dbname=$1
	cmdopts[0]=$3
	cmdopts[1]=$4
	cmdopts[2]=$5
	cmdopts[3]=$6
	case $2 in	#Call a function based on $2
		new)	new $dbname ${cmdopts[0]}
			;;
		add)	add $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]} ${cmdopts[3]}
			;;
		show)	show $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]}
			;;
		delete)	delete $dbname ${cmdopts[0]} ${cmdopts[1]} ${cmdopts[2]}
			;;
		count)	count $dbname
			;;
		*)  	echo "That is not a command!"
			;;
	esac
else
	menu #Enter interactive mode
fi
