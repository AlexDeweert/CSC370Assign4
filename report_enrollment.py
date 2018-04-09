#
# report_enrollment.py
# Alex L. Deweert
# V00855767
# CSC 370 April 4th, 2018

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
cur.execute("""
with a as( select enrollments.course_id, enrollments.term_code, count(*) over (partition by enrollments.course_id, enrollments.term_code) as c from enrollments),
b as ( select course_offerings.capacity as cap, course_offerings.term_code as baa, course_offerings.course_id as boo, a.c, a.course_id as 
blah, a.course_id as acid, a.term_code as atc, course_offerings.instructor as iname, course_offerings.name as cnamec from a full outer join course_offerings 
on a.course_id = course_offerings.course_id and a.term_code = course_offerings.term_code)
select
b.baa,
b.boo, 
b.cnamec, 
b.iname,
case when b.c is null then 0 else b.c end as total_enrollment, 
b.cap
from b
group by baa, boo, cnamec, iname, total_enrollment, cap
order by baa asc, boo;""")
rows = []
rows = cur.fetchall()

for a in rows:
	print_row(a[0], a[1], a[2], a[3], a[4], a[5])

#print_row(201709, 'CSC 106', 'The Practice of Computer Science', 'Bill Bird', 203, 215)
#print_row(201709, 'CSC 110', 'Fundamentals of Programming: I', 'Jens Weber', 166, 200)
#print_row(201801, 'CSC 370', 'Database Systems', 'Bill Bird', 146, 150)

cur.close()
conn.close()
