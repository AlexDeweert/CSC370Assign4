# assign_grades.py
# CSC 370
#
# Student Alex L. DEWEERT
# V00855767

import sys, csv, psycopg2

if len( sys.argv ) < 2:
	print( "Usage: %s <input file>", file=sys.stderr )
	sys.exit(0)

input_filename = sys.argv[1]

#Open DB Connection
try:
	conn = psycopg2.connect( dbname="alexand", user="alexand", host="studdb1.csc.uvic.ca", password="V00855767")
	#print("Connected!")
except:
	print("Error: Unable to connect to the database!")

cur = conn.cursor()

input_row = []
row_list = []

#Read in input to row lists
with open(input_filename) as f:
	for row in csv.reader(f):
		if len(row) == 0:
			continue #ignore blank row
		if len(row) < 4:
			print("Error: Invalid input line \"%s\""%(','.join(row)), file=sys.stderr)
			#Abort here if necessary
			break
		input_row = row[0:]
		row_list.append(input_row)

#student_set = set(student_set)
for g in row_list:
	#print(s)
	try: 
		cur.execute("""UPDATE enrollments SET grade={} WHERE course_id = '{}' AND term_code = {} AND student_id = '{}';""".format(g[3],g[0],g[1],g[2]))
	except psycopg2.Error as e:
		conn.rollback()
		print(e.pgerror)

conn.commit()
cur.close()
conn.close()
