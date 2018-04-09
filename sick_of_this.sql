with a as ( select * from enrollments natural join course_offerings
where course_id = 'CSC 115' and term_code = 201801 ),
b as ( select course_id, name, term_code, instructor, student_id, grade from a ),
c as ( select course_id, course_offerings.name as course_name, term_code, instructor, b.student_id, grade, capacity, students.name
from b natural join course_offerings cross join students where b.student_id = students.student_id)
select course_id, course_name, term_code, instructor, student_id, grade, capacity, name from c
