drop table if exists enrollments cascade;
drop table if exists pre_rex cascade;
drop table if exists course_offerings cascade;
drop table if exists students cascade;
drop table if exists courses cascade;
drop function if exists student_exists_trigger() cascade;
drop function if exists pre_rex_course_offering_existed_at_one_point_function() cascade;
drop function if exists enrollments_check_if_enrolled() cascade;
drop function if exists enrollments_check_max_capacity() cascade;
drop function if exists enrollments_pre_req_check() cascade;
drop function if exists enrollments_allow_null_drop() cascade;
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
	check( (grade >= 0 and grade <= 100) or (grade is null) ),
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
	return null;
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

--ENROLLMENT restrict DROP if grade not null
create function enrollments_allow_null_drop()
returns trigger as
$BODY$
begin
if old.grade is not null
then
	raise notice 'Cannot delete non-null enrollment';
else return old;
end if;
return null;
end
$BODY$
language plpgsql;
--ENROLLMENT restrict DROP if grade not null trigger
create trigger enrollments_allow_null_drop_trigger
before delete on enrollments
for each row
execute procedure enrollments_allow_null_drop();

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

--ENROLLMENT pre-req check
create function enrollments_pre_req_check()
returns trigger as
$BODY$
declare i integer := 0;
declare has_course integer := 0;
declare p record;
declare S_has_taken record;
begin
	--For each pre-req for an enrollment course
	for p in (select * from pre_rex
	where new.course_id = pre_rex.course_id and	new.term_code = pre_rex.term_code) loop
		i := i+1;
		raise notice 'Prereq#%, % requires course %',i,p.course_id,p.prereq;
		--For all courses taken by a student
		for S_has_taken in (select * from enrollments
		where new.student_id = enrollments.student_id) loop
			--Check if student has taken the pre-req for the enrollment course
			if p.prereq = S_has_taken.course_id AND 
			   S_has_taken.term_code < new.term_code AND
               ((S_has_taken.grade >= 50) OR (S_has_taken.grade is null)) then
				has_course := 1;
				raise notice 'Student DOES HAVE PRE-REQ % per: %!',p.prereq,S_has_taken;
			elsif p.prereq = S_has_taken.course_id AND S_has_taken.grade < 50 then
				raise notice 'Student HAS TAKEN % on %, but FAILED: %',p.prereq,S_has_taken.term_code,S_has_taken;
			elsif p.prereq = S_has_taken.course_id AND S_has_taken.term_code >= new.term_code then
				raise notice 'Student has SIGNED UP FOR course which has concurrent prerequisitve course %',p.prereq;

			end if;
		end loop;
		if has_course = 0 then 
			raise exception 'ERROR: Student % does not have required course %',new.student_id,p.prereq;
		else has_course := 0;
		end if;
	end loop;
--if i > 1
--then
--	raise exception 'Error: Pre-requisites not met. Either failed or student is
--	registered in the pre-req course for a term LATER than this enrollment.';
--end if;
return new;
end
$BODY$
language plpgsql;
--ENROLLMENT pre-req check trigger
create trigger enrollments_pre_req_check_trigger
before insert on enrollments
for each row
execute procedure enrollments_pre_req_check();

/*
--Test case COURSES
insert into courses values('CSC 225'),('MATH 122'),('CSC 226'),('CSC 115'),('CSC 110'),('MATH 101');

--Test case STUDENTS
insert into students values('V00123456','Cameron Elwood');
insert into students values('V00223344','Alex Deweert');
insert into students values('V00556677','Bilbo Baggins');

--Test case COURSE OFFERINGS
insert into course_offerings values('CSC 225',201801,'Special Algorithms I','Bill Bird',125);
insert into course_offerings values('MATH 122',201701,'Logic and Foundations','Gary M',50);
insert into course_offerings values('CSC 115',201701,'Java II','Tibor van Rooij',200);
insert into course_offerings values('CSC 115',201601,'Original Java II','Teebs',3);
insert into course_offerings values('CSC 115',201801,'Improved Java II','Teebs',23);
insert into course_offerings values('CSC 110',201501,'Java I','Bob',10);
insert into course_offerings values('CSC 110',201509,'Java I Remedial','Bob',5);
insert into course_offerings values('CSC 110',201601,'Java For Dummies','Guy',15);
insert into course_offerings values('MATH 101',201501,'Calculus I','Amy',126);

--Test case PRE_REQS  ( [PRE-REQ] [COURSE THAT NEEDS IT] [COURSE THAT NEEDS IT TERM CODE] )
insert into pre_rex values('MATH 122', 'CSC 225', 201801),
						  ('CSC 115', 'CSC 225', 201801),
						  ('CSC 110', 'CSC 115', 201701),
						  ('CSC 110', 'CSC 115', 201601),
						  ('CSC 110', 'CSC 115', 201801),
						  ('MATH 101','MATH 122', 201701);

--Test case ENROLLMENTS
insert into enrollments values('CSC 110', 201501, 'V00123456',50);
insert into enrollments values('MATH 101', 201501,'V00123456',58);
insert into enrollments values('MATH 122',201701,'V00123456',100);
insert into enrollments values('CSC 115',201601,'V00123456',52);
--insert into enrollments values('CSC 115',201601,'V00223344', 51);
insert into enrollments values('CSC 225',201801,'V00123456', 84);

insert into enrollments values('MATH 101', 201501,'V00556677',68);
insert into enrollments values('MATH 122',201701,'V00556677',67);
insert into enrollments values('CSC 110',201501,'V00556677', 49);
insert into enrollments values('CSC 110',201509,'V00556677', 55);
insert into enrollments values('CSC 115',201601,'V00556677', 78);
insert into enrollments values('CSC 115',201801,'V00556677', 93);
insert into enrollments values('CSC 225',201801,'V00556677', null);
delete from enrollments where course_id = 'CSC 225';
*/
