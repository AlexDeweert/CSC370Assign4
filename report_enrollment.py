import psycopg2, sys

try:
	conn = psycopg2.connect( dbname="alexand", user="alexand", host="studdb1.csc.uvic.ca", password="V00855767")
	#print("Connected!")
except:
	print("Error: Unable to connect to the database!")

cur = conn.cursor()


def print_row(term, course_code, course_name, instructor_name, total_enrollment, maximum_capacity):
	print("%6s %10s %-35s %-25s %s/%s"%(str(term), str(course_code), str(course_name), str(instructor_name), str(total_enrollment), str(maximum_capacity)) )

# Mockup: Print some data for a few made up classes
cur.execute("""with a as( select course_id, term_code, count(student_id) over( partition by course_id, term_code ) as c from enrollments group by course_id, term_code, student_id),
b as ( select * from a group by course_id, term_code, c ),
d as ( select * from b union select course_id, term_code, 0 as c from enrollments)
select term_code as term,course_id,name as course_name,instructor as instructor_name, c as total_enrollment, capacity as maximum_capacity from d natural join enrollments natural join course_offerings;""")
rows = []
trimmed = []
updated = []
rows = cur.fetchall()

for a in rows:
	#print(a)
	if a[0:5] not in trimmed:
		trimmed.append(a[0:5])
		updated.append(a)

for j in updated:
	print(j)



#Add students
'''for s in rows:
	for j in rows:
		if s[0] == j[0] and s[1] == j[1] and s[2] == j[2] and s[3]==j[3] and s[4]!=j[4] and s[5]==j[5]:
			if s[4] != 0:
				trimmed.append(s)
			elif j[4] != 0:
				trimmed.append(j)
		else:
			trimmed.append(j)

for x in trimmed:
	print(x)
#print_row(201709, 'CSC 106', 'The Practice of Computer Science', 'Bill Bird', 203, 215)
#print_row(201709, 'CSC 110', 'Fundamentals of Programming: I', 'Jens Weber', 166, 200)
#print_row(201801, 'CSC 370', 'Database Systems', 'Bill Bird', 146, 150)
'''
cur.close()
conn.close()
