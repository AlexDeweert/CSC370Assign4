--Part 2
with a as ( select * from enrollments natural join course_offerings
where course_id = 'CSC 115' and term_code = 201801 ),
b as ( select course_id, name, term_code, instructor, student_id, grade from a )
select * from b natural join course_offerings

--Part 3
with a as ( select term_code, course_id, grade, student_id from enrollments where student_id = 'V00123456'),
b as ( select term_code, course_id, name as course_name, grade, student_id from a natural join course_offerings order by term_code, course_id),
c as ( select * from b cross join students where b.student_id = students.student_id )
select term_code, course_id, course_name, grade, name from c
