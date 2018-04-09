# report_transcript.py
# CSC 370 - Spring 2018
# Alex L. DEWEERT
# V00855767

import psycopg2, sys



try:
	conn = psycopg2.connect( dbname="alexand", user="alexand", host="studdb1.csc.uvic.ca", password="V00855767")
	#print("Connected!")
except:
	print("Error: Unable to connect to the database!")

cur = conn.cursor()


def print_row(term, course_code, course_name, instructor_name, total_enrollment, maximum_capacity):
	print("%6s %10s %-35s %-25s %s/%s"%(str(term), str(course_code), str(course_name), str(instructor_name), str(total_enrollment), str(maximum_capacity)) )


#The lines below would be helpful in your solution
if len(sys.argv) < 2:
	print('Usage: %s <student id>'%sys.argv[0], file=sys.stderr)
	sys.exit(0)
	
student_id = sys.argv[1]

# Mockup: Print some data for a few made up classes
cur.execute("""  
with a as ( select term_code, course_id, grade, student_id from enrollments where student_id = '{}'),
b as ( select term_code, course_id, name as course_name, grade, student_id from a natural join course_offerings order by term_code, course_id),
c as ( select * from b cross join students where b.student_id = students.student_id )
select term_code, course_id, course_name, grade, name from c
""".format(student_id))
rows = []
rows = cur.fetchall()

def print_header(student_id, student_name):
	print("Transcript for %s (%s)"%(str(student_id), str(student_name)) )
	
def print_row(course_term, course_code, course_name, grade):
	if grade is not None:
		print("%6s %10s %-35s   GRADE: %s"%(str(course_term), str(course_code), str(course_name), str(grade)) )
	else:
		print("%6s %10s %-35s   (NO GRADE ASSIGNED)"%(str(course_term), str(course_code), str(course_name)) )


# Mockup: Print a transcript for V00123456 (Rebecca Raspberry)
student_name = rows[0][4]
print_header(student_id, student_name)

for r in rows:
	print_row( r[0],r[1],r[2],r[3] )
#print_row(201709,'CSC 110','Fundamentals of Programming: I', 90)
#print_row(201709,'CSC 187','Recursive Algorithm Design', None) #The special value None is used to indicate that no grade is assigned.
#print_row(201801,'CSC 115','Fundamentals of Programming: II', 75)

cur.close()
conn.close()
