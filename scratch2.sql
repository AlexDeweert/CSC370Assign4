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
order by baa asc, boo
