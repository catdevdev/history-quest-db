CREATE ROLE "ordinary_user";
CREATE ROLE "moderator";
CREATE ROLE "server_worker";
CREATE ROLE "admin";
CREATE ROLE "super_admin";

-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- /////////////////////// User ///////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////

CREATE OR REPLACE function get_user_by_username(_username Text)
returns table("User_id" Integer, "email" text, "username" text, "imageAvatar" text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
    SELECT "User"."User_id", "User"."email", "User"."username", "User"."imageAvatar"
    FROM "User"
    where "User"."username" = _username;
END
$function$;


REVOKE EXECUTE ON FUNCTION get_user_by_username(text) FROM public;
grant execute on function get_user_by_username(text) to "server_worker";
grant execute on function get_user_by_username(text) to "admin";
select * from get_user_by_username('catprogrammer12')


CREATE OR REPLACE function create_user(_email Text, _username text, _password Text)
returns table("email" text, "username" text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
    INSERT INTO "User"("email", "username") VALUES (_email, _username) RETURNING "User"."email", "User"."username";
    execute ('CREATE USER ' || _username || ' WITH ENCRYPTED PASSWORD ' || '''' || _password || '''' || ';');
    execute ('GRANT ' || 'ordinary_user' || ' TO ' || _username || ';');
END
$function$;


REVOKE execute on function create_user(text, text, text) FROM public;
grant execute on function create_user(text, text, text) to "server_worker";
select * from create_user('catprogrammer@gmail.com', 'postgres123', 'postgres123');


CREATE OR REPLACE function logged_in_user()
returns table("User_id" int, "email" text, "username" text, "imageAvatar" texT)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
    SELECT "User"."User_id", "User"."email", "User"."username", "User"."imageAvatar" FROM "User" where "User"."username" = (SELECT session_user);
END
$function$;


REVOKE execute on function logged_in_user() FROM public;
grant execute on function logged_in_user() to "ordinary_user";
select * from logged_in_user();


-- //

CREATE OR REPLACE function update_image_avatar(_image_cover_url text)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
declare
    current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    update "User" 
    set "imageAvatar" = _image_cover_url
    where "User"."User_id" = current_user_id;
    return current_user_id;
END
$function$;


REVOKE execute on function update_image_avatar(text) FROM public;
grant execute on function update_image_avatar(text) to "ordinary_user";
select * from update_image_avatar('edited123');


CREATE OR REPLACE function get_roles_of_user(_username text)
returns table("rolname" name)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
    SELECT b.rolname
        FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
        join pg_catalog.pg_roles r on (m.member = r.oid)
        where r.rolname = _username;
END
$function$;


REVOKE execute on function get_roles_of_user(text) FROM public;
grant execute on function get_roles_of_user(text) to "admin";
select * from get_roles_of_user('catprogrammer12')


CREATE OR REPLACE function give_user_role(_username text, _role_name Text)
returns TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    execute ('GRANT ' || _role_name || ' TO ' || _username || ';');
    return _role_name;
END
$function$;


REVOKE execute on function give_user_role(text, text) FROM public;
grant execute on function give_user_role(text, text) to "admin";
select * from give_user_role('catprogrammer', 'ordinary_user')


CREATE OR REPLACE function remove_user_role(_username text, _role_name Text)
returns TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    execute ('REVOKE ' || _role_name || ' FROM ' || _username || ';');
    return _role_name;
END
$function$;


REVOKE execute on function remove_user_role(text, text) FROM public;
grant execute on function remove_user_role(text, text) to "admin";
select * from remove_user_role('catprogrammer', 'ordinary_user');


CREATE OR REPLACE function write_statistic_about_logging_user(_ipAddress text, _systemName text)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
declare
    current_user_id int;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "DeviceInfo"("User_id", "ipAddress", "systemName", "loggedAt") VALUES (current_user_id,  _ipAddress, _systemName, now());
    return current_user_id;
END
$function$;


REVOKE execute on function write_statistic_about_logging_user(text, text) FROM public;
grant execute on function write_statistic_about_logging_user(text, text) to "server_worker";
select * from write_statistic_about_logging_user('192.0.0.1', 'IOS')


CREATE OR REPLACE function get_statistic_about_logging_user_by_user_name(_user_name text)
returns table("User_id" int, "loggedAt" date, "ipAddress" text, "systemName" text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
        select * from "DeviceInfo" where "DeviceInfo"."User_id" = (select "User"."User_id" from "User" where "User"."username" = _user_name);
END
$function$;


REVOKE execute on function get_statistic_about_logging_user_by_user_name(text) FROM public;
grant execute on function get_statistic_about_logging_user_by_user_name(text) to "admin";
select * from get_statistic_about_logging_user_by_user_name('postgres');




-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ///////////////// Category and Genge ///////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////


CREATE OR REPLACE function add_genre_to_userpost(_user_post_id int, _genre_id int)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
BEGIN
    insert into "Genres"("UserPost_id", "Genre_id") values (_user_post_id, _genre_id) returning "Genre_id" into id;
    return id;
END
$function$;


REVOKE execute on function add_genre_to_userpost(int, int) FROM public;
grant execute on function add_genre_to_userpost(int, int) to "ordinary_user";
select * from add_genre_to_userpost(1, 5)

-- ////
-- ////

CREATE OR REPLACE function add_category_to_userpost(_user_post_id int, _category_id int)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
BEGIN
    insert into "Categories"("UserPost_id", "Category_id") values (_user_post_id, _category_id) returning "Category_id" into id;
    return id;
END
$function$;

REVOKE execute on function add_category_to_userpost(int, int) FROM public;
grant execute on function add_category_to_userpost(int, int) to "ordinary_user";
select * from add_category_to_userpost(2, 4)



-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////// UserPost ////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////

   
CREATE OR REPLACE view all_user_post as       
        select a."UserPost_id", a."User_id", a.title, 'Story' as "userpostType", a.description, a."inReview", a."isBanned", a."isPublished", a."inTrash", a."imageCover"
        from "UserPost" a 
        JOin "Story" b 
        on (a."UserPost_id" = b."Story_id")
        union
        select a."UserPost_id", a."User_id", a.title, 'Quest' as "userpostType", a.description, a."inReview", a."isBanned", a."isPublished", a."inTrash", a."imageCover"
        from "UserPost" a 
        JOin "Quest" b 
        on (a."UserPost_id" = b."Quest_id");
        

CREATE OR REPLACE function get_all_userposts()
returns table("UserPost_id" int, "User_id" Int, title text, "userpostType" text, "description" text, "inReview" boolean, "isBanned" boolean, "isPublished" boolean, "inTrash" boolean, "imageCover" Text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
        select * from all_user_post;
END
$function$;

REVOKE execute on function get_all_userposts() FROM public;
grant execute on function get_all_userposts() to "ordinary_user";
select * from get_all_userposts();

CREATE OR REPLACE function get_all_my_userposts()
returns table("UserPost_id" int, "User_id" Int, title text, "userpostType" text, "description" text, "inReview" boolean, "isBanned" boolean, "isPublished" boolean, "inTrash" boolean, "imageCover" Text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN  
    return query 
        select * from all_user_post where all_user_post."User_id" = (
            select loggen_in_user."User_id" as id from loggen_in_user()
        );
  
END
$function$;


REVOKE execute on function get_all_my_userposts() FROM public;
grant execute on function get_all_my_userposts() to "ordinary_user";
select * from get_all_my_userposts();


CREATE OR REPLACE function move_into_trash_user_post(_user_post_id int)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "UserPost" 
    set "inTrash" = true
    where "UserPost"."UserPost_id" = _user_post_id;
    return _user_post_id;
END
$function$;

REVOKE execute on function move_into_trash_user_post(int) FROM public;
grant execute on function move_into_trash_user_post(int) to "ordinary_user";
select * from move_into_trash_user_post(66)

            
CREATE OR REPLACE function update_image_cover(_user_post_id int, _image_cover_url text)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "UserPost" 
    set "imageCover" = _image_cover_url
    where "UserPost"."UserPost_id" = _user_post_id;
    return _user_post_id;
END
$function$;


REVOKE execute on function update_image_cover(int, text) FROM public;
grant execute on function update_image_cover(int, text) to "ordinary_user";
select * from update_image_cover(90, 'edited123');


CREATE OR REPLACE function like_or_dislike_user_post(_user_post_id int, _isLike boolean)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    IF not EXISTS(SELECT * FROM "RatingActionUserPost" WHERE "RatingActionUserPost"."UserPost_id" = _user_post_id and "RatingActionUserPost"."User_id" = current_user_id) then
        INSERT INTO "RatingActionUserPost"("UserPost_id", "User_id", "isLike") VALUES (_user_post_id, current_user_id, _isLike);
        return _user_post_id;
    END if ;
    return _user_post_id;
END
$function$;

REVOKE execute on function like_or_dislike_user_post(int, boolean) FROM public;
grant execute on function like_or_dislike_user_post(int, boolean) to "ordinary_user";
select * from like_or_dislike_user_post(110, true);


CREATE OR REPLACE function get_like_or_dislike_user_post(_user_post_id int)
returns table("isLike" boolean, "User_id" int, "UserPost_id" int)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    return query
        select * from "RatingActionUserPost" where "RatingActionUserPost"."UserPost_id" = _user_post_id;
END
$function$;

REVOKE execute on function get_like_or_dislike_user_post(int) FROM public;
grant execute on function get_like_or_dislike_user_post(int) to "ordinary_user";
select * from get_like_or_dislike_user_post(110);


CREATE OR REPLACE function write_user_post_view_statistic(_user_post_id int)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "UserPostView"("UserPost_id", "User_id", "createdAt") VALUES (_user_post_id, current_user_id, now());
    return _user_post_id;
END
$function$;

REVOKE execute on function write_user_post_view_statistic(int) FROM public;
grant execute on function write_user_post_view_statistic(int) to "ordinary_user";
select * from write_user_post_view_statistic(110);


CREATE OR REPLACE function get_number_of_views_by_userpost(_user_post_id int)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id int;
  current_user_id int;
  number_of_views int;
BEGIN
    select count(*) into number_of_views from "UserPostView" where "UserPostView"."UserPost_id" = _user_post_id;
    return number_of_views;
END
$function$


REVOKE execute on function get_number_of_views_by_userpost(int) FROM public;
grant execute on function get_number_of_views_by_userpost(int) to "ordinary_user";
select * from get_number_of_views_by_userpost(3);


-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- /////////////////////// Story //////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////


CREATE OR REPLACE function create_story(_title Text, _description text default null)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "UserPost"("title", "description", "User_id") VALUES (_title, _description, current_user_id) RETURNING "UserPost_id" into id;
    INSERT INTO "Story"("Story_id", "content") VALUES (id, null);
    return id;
END
$function$;


REVOKE execute on function create_story(text, text) FROM public;
grant execute on function create_story(text, text) to "ordinary_user";
select * from create_story('tesdt', '123');


CREATE OR REPLACE function get_story_by_id(_story_id int)
returns table("title" text, "UserPost_id" int, "User_id" int, "description" text, "isPublished" boolean, "inReview" boolean, "inBanned" boolean, "imageCover" text, "inTrash" boolean, "Story_id" int, "content" text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
        select a.*, b.* 
        from "UserPost" a 
        JOin "Story" b 
        on (a."UserPost_id" = b."Story_id")
        where a."UserPost_id" = _story_id;
END
$function$;

REVOKE execute on function get_story_by_id(int) FROM public;
grant execute on function get_story_by_id(int) to "ordinary_user";
select * from get_story_by_id(60);


CREATE OR REPLACE function update_story_content(_story_id int, _content text)
returns int
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "Story" 
    set "content" = _content
    where "Story"."Story_id" = _story_id;
    return _story_id;
END
$function$;


REVOKE execute on function update_story_content(int, text) FROM public;
grant execute on function update_story_content(int, text) to "ordinary_user";
select * from update_story_content(90, 'edited');



-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- /////////////////////// Quest //////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////


CREATE OR REPLACE function create_quest(_title Text, _description text default null)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "UserPost"("title", "description", "User_id") VALUES (_title, _description, current_user_id) RETURNING "UserPost_id" into id;
    INSERT INTO "Quest"("Quest_id") VALUES (id);
    return id;
END
$function$;

REVOKE execute on function create_quest(text, text) FROM public;
grant execute on function create_quest(text, text) to "ordinary_user";
select * from create_quest('tesdt', '123');


-- to add check if it is yours quest
CREATE OR REPLACE function create_quest_node(_quest_id int, _content text default null)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "QuestNode"("content", "Quest_id") VALUES (_content, _quest_id) RETURNING "QuestNode_id" into id;
    return id;
END
$function$;


REVOKE execute on function create_quest_node(int, text) FROM public;
grant execute on function create_quest_node(int, text) to "ordinary_user";
select * from create_quest_node(68, 'you see red and blue doors');


-- to add check if it is yours quest
CREATE OR REPLACE function create_quest_node_choice(_quest_id int, _quest_node_from int, _choice_content text)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  quest_node_id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    select create_quest_node into quest_node_id from create_quest_node(_quest_id);
    INSERT INTO "QuestNodeChoice"("content", "toQuestNode", "QuestNode_id") VALUES (_choice_content, quest_node_id, _quest_node_from);
    update "QuestNode" set "isEnd" = false where "QuestNode"."QuestNode_id" = _quest_node_from;
    
    return quest_node_id;
END
$function$;


REVOKE execute on function create_quest_node_choice(int, int, text) FROM public;
grant execute on function create_quest_node_choice(int, int, text) to "ordinary_user";
select * from create_quest_node_choice(68, 7, 'go to blue door');


CREATE OR REPLACE function update_quest_node_content(_quest_node_id int, _content text)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "QuestNode"
    set "content" = _content
    where "QuestNode"."QuestNode_id" = _quest_node_id;
    return _quest_node_id;
END
$function$;


REVOKE execute on function update_quest_node_content(int, text) FROM public;
grant execute on function update_quest_node_content(int, text) to "ordinary_user";
select * from update_quest_node_content(7, 'llloool')


CREATE OR REPLACE function get_quest_node_content(_quest_node_id int)
returns table("Quest_id" int, "QuestNode_id" int, "isEnd" boolean, "content" text)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    return query
    select * from "QuestNode" where "QuestNode"."QuestNode_id" = _quest_node_id;
END
$function$;


REVOKE execute on function get_quest_node_content(int) FROM public;
grant execute on function get_quest_node_content(int) to "ordinary_user";
select * from get_quest_node_content(7);


CREATE OR REPLACE function get_quest_node_choices(_quest_node_id int)
returns table("QuestNode_id" int, "content" text, "toQuestNode" int)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    return query
    select * from "QuestNodeChoice" where "QuestNodeChoice"."QuestNode_id" = _quest_node_id;
END
$function$;


REVOKE execute on function get_quest_node_choices(int) FROM public;
grant execute on function get_quest_node_choices(int) to "ordinary_user";
select * from get_quest_node_choices(7);





-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ///////////////////// Comments /////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////

CREATE OR REPLACE function all_comments_by_userpost(_user_post_id int)
returns table("UserPost_id" int, "content" text, "isBanned" boolean, "Comment_id" int, "username" text, "imageAvatar" text, "createdAt" date)
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
BEGIN
    return query
        select "Comment"."UserPost_id", "Comment"."content", "Comment"."isBanned", "Comment"."Comment_id", "User"."username", "User"."imageAvatar", "Comment"."createdAt" from "Comment"
        inner join "User" on "User"."User_id" = "Comment"."User_id"
        where "Comment"."UserPost_id" = _user_post_id;
END
$function$;


REVOKE execute on function all_comments_by_userpost(int) FROM public;
grant execute on function all_comments_by_userpost(int) to "ordinary_user";
select * from all_comments_by_userpost(3)


CREATE OR REPLACE function add_comment(_user_post_id int, _content text)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  id integer;
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "Comment"("content", "User_id", "UserPost_id", "createdAt") VALUES (_content, current_user_id, _user_post_id, now()) RETURNING "Comment_id" into id;
    return id;
END
$function$;


REVOKE execute on function add_comment(int, text) FROM public;
grant execute on function add_comment(int, text) to "ordinary_user";
select * from add_comment(1, 'go to blue door');


CREATE OR REPLACE function heart_comment(_comment_id int)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
  current_user_id integer;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    INSERT INTO "HeartActionComment"("Comment_id", "User_id") VALUES (_comment_id, current_user_id);
    return _comment_id;
END
$function$;


REVOKE execute on function heart_comment(int) FROM public;
grant execute on function heart_comment(int) to "ordinary_user";
select * from heart_comment(2);


CREATE OR REPLACE function ban_comment(_comment_id int)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "Comment" 
    set "isBanned" = true
    where "Comment"."Comment_id" = _comment_id;
    return _comment_id;
END
$function$;

REVOKE execute on function ban_comment(int) FROM public;
grant execute on function ban_comment(int) to "moderator";

select * from ban_comment(2);


CREATE OR REPLACE function unban_comment(_comment_id int)
returns integer
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
    update "Comment" 
    set "isBanned" = false
    where "Comment"."Comment_id" = _comment_id;
    return _comment_id;
END
$function$;


REVOKE execute on function unban_comment(int) FROM public;
grant execute on function unban_comment(int) to "moderator";

select * from unban_comment(2);


-- this is for add sequence
CREATE SEQUENCE comment_id_seq;
ALTER TABLE "Comment"
  ALTER COLUMN "Comment_id" SET DEFAULT nextval('category_id_seq');
 
 
 
select * from User;

SELECT * FROM pg_user;

SELECT * FROM pg_roles;

CREATE ROLE "server";
CREATE ROLE "ordinary_user";


ALTER ROLE guest WITH LOGIN;
ALTER ROLE ordinary_user WITH LOGIN;
ALTER ROLE ordinary_user WITH select on "current_user";

SELECT oid, rolname FROM pg_roles WHERE
  pg_has_role( 'lol228', oid, 'member');


alter user postgres password 'postgres'

GRANT ALL ON PROCEDURE create_user TO guest;
  
CREATE USER youruser2324 WITH ENCRYPTED PASSWORD 'yourpas234s';
GRANT youruser2324 TO "ordinary_user";

select passwd from pg_user

SELECT rolpassword FROM pg_authid



grant select on table "current_user" to my_new_user;


-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ///////////////////// Triggers /////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////

CREATE OR REPLACE function log_userpost_actions()
returns TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $function$
DECLARE
    current_user_id int;
    userpost_id int;
    action_name text;
    retstr text;
BEGIN
    select "User_id" into current_user_id from loggen_in_user();
    
    IF TG_OP = 'INSERT' THEN
        userpost_id = NEW."UserPost_id";
        action_name := 'CREATED';
        INSERT INTO "UserPostLogs"("action", "createdAt", "User_id", "UserPost_id") values (action_name, NOW(), current_user_id, userpost_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        userpost_id = NEW."UserPost_id";
        action_name := 'UPDATED';
        INSERT INTO "UserPostLogs"("action", "createdAt", "User_id", "UserPost_id") values (action_name, NOW(), current_user_id, userpost_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        userpost_id = OLD."UserPost_id";
        action_name := 'DELETED';
        INSERT INTO "UserPostLogs"("action", "createdAt", "User_id", "UserPost_id") values (action_name, NOW(), current_user_id, userpost_id);
        RETURN OLD;
    END IF;
END
$function$;


CREATE TRIGGER user_post_update
AFTER INSERT OR UPDATE OR DELETE ON "UserPost" FOR EACH ROW EXECUTE PROCEDURE log_userpost_actions();

drop trigger "user_post_update" on "UserPost";











