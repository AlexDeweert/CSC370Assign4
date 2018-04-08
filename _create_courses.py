# create_courses.py
# CSC 370
#
# Student Alex L. DEWEERT
# V00855767
DEBUG = 1


import sys, csv, psycopg2

if len( sys.argv ) < 2:
	print( "Usage: %s <input file>", file=sys.stderr )
	sys.exit(0)

input_filename = sys.argv[1]

#Open DB Connection
try:
	conn = psycopg2.connect( dbname="alexand", user="alexand", host="studdb1.csc.uvic.ca", password="V00855767")
	print("Connected!")
	conn.close()
except:
	print("Error: Unable to connect to the database!")

with open(input_filename) as f:
	for row in csv.reader(f):
		if len(row) == 0:
			continue #ignore blank row
		if len(row) < 4:
			print("Error: Invalid input line \"%s\""%(','.join(row)), file=sys.stderr)
			#TODO ABORT TRANSACTION AND ROLLBACK
			break
		code,name,term,instructor,capacity=row[0:5]
		pre_rex=row[5:] #0 or more pre-rex
		if DEBUG: print("[DEBUG] Retrieved CODE: ",code)
		if DEBUG: print("[DEBUG] Retrieved NAME: ",name)
		if DEBUG: print("[DEBUG] Retrieved TERM: ",term)
		if DEBUG: print("[DEBUG] Retrieved INSTRUCTOR: ",instructor)
		if DEBUG: print("[DEBUG] Retrieved CAPACITY: ",capacity)
		for p in pre_rex:
			if DEBUG: print("[DEBUG] Retrieved PRE_REX: ",p)
		if DEBUG: print("")

