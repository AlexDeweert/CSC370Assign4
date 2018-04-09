# add_drop.py
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
	print("Connected!")
except:
	print("Error: Unable to connect to the database!")

cur = conn.cursor()

input_row = []
row_list = []
pre_rex_list = []
course_set = []

#Read in input to row lists
with open(input_filename) as f:
	for row in csv.reader(f):
		if len(row) == 0:
			continue #ignore blank row
		if len(row) < 4:
			print("Error: Invalid input line \"%s\""%(','.join(row)), file=sys.stderr)
			#Abort here if necessary
			break
		input_row = row[0:5]
		pre_rex_list = row[5:]
		input_row.append(pre_rex_list)
		row_list.append(input_row)

#Add distinct course codes to courses
for e in row_list:
	course_set.append(e[0])
course_set = set(course_set)
for p in course_set:
	try: 
		cur.execute("""INSERT INTO courses VALUES('{0}');""".format(p))
		#conn.commit()
	except psycopg2.Error as e:
		conn.rollback()
		print(e.pgerror)

#Add to the course offerings tables
for a in row_list:
	#print(a[0:5])
	try:
		cur.execute("""INSERT INTO course_offerings VALUES('{}',{},'{}','{}','{}');""".format(a[0],a[2],a[1],a[3],a[4]))
		#conn.commit()
	except psycopg2.Error as e:
		conn.rollback()
		print(e.pgerror)

#Add to the pre-requisites table
for b in row_list:
	#print("Inserting row: " + str(b))
	if b[5]:
		for pre_req in b[5]:
			try:
				cur.execute("""INSERT INTO pre_rex VALUES('{}','{}',{});""".format(pre_req,b[0],b[2]))
				#conn.commit()
			except psycopg2.Error as e:
				conn.rollback()
				print(e.pgerror)
conn.commit()
cur.close()
conn.close()
