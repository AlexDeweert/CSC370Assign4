# report_classlist.py
# CSC 370 - Spring 2018
# Alex L. DEWEERT
# V00855767 CSC 370 - Spring 2018 - Starter code for Assignment 4

import psycopg2, sys

try:
	conn = psycopg2.connect( dbname="alexand", user="alexand", host="studdb1.csc.uvic.ca", password="V00855767")
except:
	print("Error: Unable to connect to the database!")

cur = conn.cursor()

def print_header(course_code, course_name, term, instructor_name):
	print("Class list for %s (%s)"%(str(course_code), str(course_name)) )
	print("  Term %s"%(str(term), ) )
	print("  Instructor: %s"%(str(instructor_name), ) )
	
def print_row(student_id, student_name, grade):
	if grade is not None:
		print("%10s %-25s   GRADE: %s"%(str(student_id), str(student_name), str(grade)) )
	else:
		print("%10s %-25s"%(str(student_id), str(student_name),) )

def print_footer(total_enrolled, max_capacity):
	print("%s/%s students enrolled"%(str(total_enrolled),str(max_capacity)) )


#The lines below would be helpful in your solution
if len(sys.argv) < 3:
	print('Usage: %s <course code> <term>'%sys.argv[0], file=sys.stderr)
	sys.exit(0)
	
course_code, term = sys.argv[1:3]

try:
	cur.execute(""" 
	with a as ( select * from enrollments natural join course_offerings
	where course_id = '{}' and term_code = {} ),
	b as ( select course_id, name, term_code, instructor, student_id, grade from a ),
	c as ( select course_id, course_offerings.name as course_name, term_code, instructor, b.student_id, grade, capacity, students.name
	from b natural join course_offerings cross join students where b.student_id = students.student_id)
	select course_id, course_name, term_code, instructor, student_id, grade, capacity, name from c
	;""".format(course_code,term))
except:
	print("Error")

rows = []
rows = cur.fetchall()

#for a in rows:
#	print(a)

# Mockup: Print a class list for CSC 370
course_name = rows[0][1]
course_term = term
instructor_name = rows[0][3]
print_header(course_code, course_name, course_term, instructor_name)

count=0
#Print records for a few students
for a in rows:
#print_row('V00123456', 'Rebecca Raspberry', 81)
	print_row(a[4],a[7],a[5])
	count = count+1

#Print the last line (enrollment/max_capacity)
print_footer(count,rows[0][6])
cur.close()
conn.close()
