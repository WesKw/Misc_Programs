#Awk script to generate a report from input data in a specified format.
#Wesley Kwiecinski
#CSCI 330 - Section 1
#Assignment 7 - Reporting With awk
#Due 11/6/2020

#Formatting, display
BEGIN {
	print("Sales performance for No-op Computing in 2018")
	printf("%-20s %-15s %+15s", "Name", "Position", "Sales Ammount\n")
	printf("%-20s %-15s %+15s", "----", "--------", "-------------\n")
	FS = ":"	#Set field seperator
}

#Get the product and its price
#Check for records with only 4 fields
#$1 must be a product number, $3 must be a name, $4 must be a number with a decimal point
/^[0-9]:.+:.+:[0-9]+\.[0-9]+/ {
	products[$1]=$3		#Store description of product
	prices[$3]=$4		#Use desc as key for storing prices.
}

#Check if end only has no digits
#Used to grab and store names
/[a-z]$/ {
	names[$1]=$2		#Store names using ID
	position[$2]=$3		#Use name as key for position
}

#Get sales records Only finds sales made in 2018. Match records with five fields and 2018 as the year1
#Any number at the beginning, $2 must be a product value, $3 must be an ammount, $4 must have 2018 in it, $5 must be one of the employees
/[0-9]+:[1-6]:[1-9]+:.+[:2018:]:[1-9]/ {
	total_sales[names[$5]]+=(prices[products[$2]]*$3)	#Use the product key to get the price of the product, multiply it by # sold
}

#Format output for each salesperson
 END {
	#For every name, print position and total sales
	for(i in names){
		split(names[i], last_first, " ")
		#Print name, position, and total sales in 2018, sort output: reverse sort, sort column 4, use human numeric sort for floats/doubles
		printf("%-20s %-15s %14.2f\n", last_first[2] ", " last_first[1], position[names[i]], total_sales[names[i]]) | "sort -hr -k4"
	}
}
