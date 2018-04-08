drop table if exists enrollments cascade;
drop table if exists pre_rex cascade;
drop table if exists course_offerings cascade;
drop table if exists students cascade;
drop table if exists courses cascade;
drop function if exists student_exists_trigger() cascade;
drop function if exists pre_rex_course_offering_existed_at_one_point_function() cascade;
drop function if exists enrollments_check_if_enrolled() cascade;
drop function if exists enrollments_check_max_capacity() cascade;
create table students (
	student_id varchar(9) primary key,
	name varchar(255) not null,
	check( student_id ~ 'V00\d\d\d\d\d\d' )
);
create table courses (
	course_id varchar(10) primary key
);
create table course_offerings (
	course_id varchar(10),
	term_code integer,
	name varchar(128),
	instructor varchar(255),
	capacity int,
	foreign key( course_id ) references courses( course_id ),
	primary key( course_id, term_code ),
	constraint c1 check( char_length(name) > 0 ),
	constraint c2 check( capacity > 0 ),
	constraint c3 check( char_length(instructor) > 0 )  
);--TODO Add trigger to verify enrolment
create table pre_rex (
	prereq varchar(10),
	course_id varchar(10),
	term_code integer,
	foreign key( prereq ) references courses( course_id )
		on delete restrict
		on update cascade,
	foreign key( course_id, term_code ) references course_offerings( course_id, term_code )
		on delete restrict
		on update cascade,
	constraint c5 check( prereq != course_id ),
	primary key( prereq, course_id, term_code )
);
create table enrollments (
	course_id varchar(10),
	term_code integer,
	student_id varchar(9),
	grade int,
	check(grade >= 0 and grade <= 100),
	primary key( course_id, term_code, student_id ),
	foreign key( course_id, term_code ) references course_offerings( course_id, term_code )
		on delete restrict
		on update cascade,
	foreign key( student_id ) references students( student_id )
		on delete restrict
		on update cascade
);

--Function for student duplication constraint
create function student_exists_trigger()
returns trigger as
$BODY$
begin
if ( select count(student_id) from students where student_id = new.student_id ) > 0
then 
	return null;--raise exception 'Student already in database';
end if;
return new;
end
$BODY$
language plpgsql;
--Trigger for student duplication constraint
create trigger student_exists_constraint
before insert on students
for each row
execute procedure student_exists_trigger();

--Function: Check insert into pre-rex
--Before insert check to see if course-offering exists
--Then also check that the course_id is a valid one for the pre-req
create function pre_rex_course_offering_existed_at_one_point_function()
returns trigger as
$BODY$
begin
if ( select count(course_offerings.course_id) from course_offerings where new.prereq = course_offerings.course_id ) = 0
then
	raise exception 'Error: Cannot insert prerequisite course. Course does not exist in Course Offerings';
end if;
return new;
end
$BODY$
language plpgsql;
--Pre-requisite trigger
create constraint trigger pre_rex_course_offering_existed_at_one_point_trigger
after insert or update on pre_rex
deferrable
for each row
execute procedure pre_rex_course_offering_existed_at_one_point_function();

--Function: ENROLLMENTS Check if already enrolled
create function enrollments_check_if_enrolled()
returns trigger as
$BODY$
declare counts integer;
begin
--When enrolling, we insert course_id, term_code, student_id, grade
--If inserting course_id && term_code && student_id the same, deny
if( select count(enrollments.student_id)
	from enrollments where 
	new.student_id = enrollments.student_id
	and new.course_id = enrollments.course_id
	and new.term_code = enrollments.term_code
) > 0
then
	raise exception 'Error: Student already enrolled.';
end if;
return new;
end
$BODY$
language plpgsql;
--ENROLLMENT check if enrolled trigger
create trigger enrollments_check_if_enrolled_trigger
before insert on enrollments
for each row
execute procedure enrollments_check_if_enrolled();

--ENROLLMENT check not max capacity
create function enrollments_check_max_capacity()
returns trigger as
$BODY$
begin
if( select count(*) from enrollments 
     where new.course_id = enrollments.course_id
	 and 
	 new.term_code = enrollments.term_code )
   >
  ( select capacity from course_offerings
    where new.course_id = course_offerings.course_id
    and new.term_code = course_offerings.term_code )
then
	raise exception 'Error: Course at max capacity. Cannot enroll!';
end if;
return new;
end
$BODY$
language plpgsql;
--ENROLLMENT check not max cap trigger
create trigger enrollments_check_max_capacity_trigger
after insert on enrollments
for each row
execute procedure enrollments_check_max_capacity();

--Test case COURSES
insert into courses values('CSC 225'),('MATH 122'),('CSC 226'),('CSC 115');

--Test case STUDENTS
insert into students values('V00123456','Cameron Elwood');
insert into students values('V00223344','Alex Deweert');
insert into students values('V00556677','Bilbo Baggins');

--Test case COURSE OFFERINGS
insert into course_offerings values('CSC 225',201801,'Special Algorithms I','Bill Bird',125);
insert into course_offerings values('MATH 122',201701,'Logic and Foundations','Gary M',50);
insert into course_offerings values('CSC 115',201701,'Java II','Tibor van Rooij',200);
insert into course_offerings values('CSC 115',201601,'Original Java','Teebs',3);

--Test case PRE_REQS
insert into pre_rex values('MATH 122', 'CSC 225', 201801),('CSC 115', 'CSC 225', 201801);

--Test case ENROLLMENTS
insert into enrollments values('MATH 122',201701,'V00556677',100);
insert into enrollments values('CSC 115',201601,'V00123456', 25);
insert into enrollments values('CSC 115',201601,'V00223344', 51);
insert into enrollments values('CSC 115',201601,'V00556677', 78);
--insert into enrollments values('CSC 115',201601,'V00123456', 25);
