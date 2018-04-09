with a as( select course_id, term_code, count(student_id) over( partition by course_id, term_code ) as c from enrollments group by course_id, term_code, student_id),
b as ( select * from a group by course_id, term_code, c ),
d as ( select * from b union select course_id, term_code, 0 as c from enrollments)
select term_code,course_id,name,instructor,c from d natural join enrollments natural join course_offerings;
