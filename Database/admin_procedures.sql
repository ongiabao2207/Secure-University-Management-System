ALTER SESSION SET CONTAINER=PDB_QLDH;
show con_name;


--CREATE USER QLDH IDENTIFIED BY 123456;
--GRANT CREATE SESSION TO QLDH;
--GRANT ALTER SESSION TO QLDH;
--GRANT RESOURCE TO QLDH; 
--GRANT CREATE VIEW TO QLDH;
--GRANT SELECT ANY DICTIONARY TO QLDH;
--GRANT CREATE USER, ALTER USER, DROP USER TO QLDH;
--GRANT CREATE ROLE, ALTER ANY ROLE, DROP ANY ROLE TO QLDH;
--GRANT GRANT ANY ROLE TO QLDH;
--GRANT GRANT ANY PRIVILEGE TO QLDH;
--GRANT GRANT ANY OBJECT PRIVILEGE TO QLDH;
--ALTER USER QLDH QUOTA UNLIMITED ON SYSTEM;



-- Xem danh sách người dùng trong hệ thống
SELECT USERNAME, USER_ID, ACCOUNT_STATUS, CREATED FROM DBA_USERS
ORDER BY USER_ID;


-- Xem danh sách vai trò trong hệ thống
SELECT ROLE, ROLE_ID, PASSWORD_REQUIRED, AUTHENTICATION_TYPE FROM DBA_ROLES
ORDER BY ROLE_ID;


-- Proc drop view nếu đã tồn tại
select count(*) from USER_VIEWS WHERE VIEW_NAME = 'V_DONVI_SV4001';
CREATE OR REPLACE PROCEDURE SP_Drop_View (
    view_name IN VARCHAR2
)
AS
    cnt NUMBER;
    sql_str VARCHAR2(1000);
BEGIN
    cnt := 0;
    -- Kiểm tra xem view có tồn tại không
    SELECT COUNT(*) INTO cnt
    FROM USER_VIEWS
    WHERE VIEW_NAME = UPPER(TRIM(view_name));

    IF cnt > 0 THEN
        -- Nếu tồn tại thì thực hiện DROP VIEW
        sql_str := 'DROP VIEW ' || TRIM(view_name);
        EXECUTE IMMEDIATE sql_str;
    END IF;
END;
/



-- Proc kiểm tra user đã tồn tại hay chưa, trả về 0 nếu không tồn tại, trả về 1 nếu đã tồn tại
CREATE OR REPLACE PROCEDURE SP_Check_User_Exists (
    user_ in char,
    result_ out number
)
AS
    cnt int;
BEGIN
    SELECT count(*) into cnt FROM DBA_USERS WHERE username = user_;
    if cnt > 0 then
        result_ := 1;
    else
        result_ := 0;
    end if;
END;
/
--SET SERVEROUTPUT ON;
--declare
--    res number;
--begin
--   SP_Check_User_Exists('NV001', res);
--   dbms_output.put_line(res);
--end;
--/

-- Proc tạo mới user
CREATE OR REPLACE PROCEDURE SP_Create_User (
    username_ in char,
    password_ in char
)
AS
    is_exists number;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user đã tồn tại hay chưa
    SP_Check_User_Exists(username_, is_exists);
    if is_exists = 0 then -- nếu chưa tồn tại
        begin
            str_SQL := 'CREATE USER "' || username_ || 
                    '" IDENTIFIED BY "' || password_ || '"';
            EXECUTE IMMEDIATE str_SQL;
            
            str_SQL := 'GRANT CONNECT TO "' || username_ || '"';
            EXECUTE IMMEDIATE str_SQL;
        end;
    else -- nếu đã tồn tại
        -- Ném lỗi
        RAISE_APPLICATION_ERROR(-20001, 'User "' || username_ || '" has already existed!');
    end if;
END;
/
--exec sp_create_user('SV4001', '123');

-- Proc xoá user
CREATE OR REPLACE PROCEDURE SP_Drop_User (
    username_ IN VARCHAR2
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user có tồn tại không
    SP_Check_User_Exists(username_, is_exists);

    IF is_exists = 1 THEN -- nếu đã tồn tại
        str_SQL := 'DROP USER "' || username_ || '" CASCADE';
        EXECUTE IMMEDIATE str_SQL;
    ELSE -- nếu chưa tồn tại
        RAISE_APPLICATION_ERROR(-20002, 'User "' || username_ || '" does not exist!');
    END IF;
END;
/
--exec SP_Drop_User('SV4001');


-- Proc chỉnh sửa mật khẩu cho user
CREATE OR REPLACE PROCEDURE SP_Change_User_Password (
    user_ in char,
    new_pass in char,
    confirm_new_pass in char
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user có tồn tại không
    SP_Check_User_Exists(user_, is_exists);
    
    if is_exists = 0 then -- nếu không tồn tại
        RAISE_APPLICATION_ERROR(-20003, 'User "' || user_ || '" does not exist!');
    else
        begin
            if new_pass != confirm_new_pass then
                RAISE_APPLICATION_ERROR(-20004, 'Different password!');
            else
                str_SQL := 'ALTER USER "' || user_ || '" IDENTIFIED BY "' || new_pass || '"';
                EXECUTE IMMEDIATE str_SQL;
            end if;
        end;
    end if;
END;
/
--exec SP_Change_User_Password('SV4001', 'bao', 'bao');


-- Proc khoá tài khoản
CREATE OR REPLACE PROCEDURE SP_Lock_User (
    user_ in char
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user có tồn tại không
    SP_Check_User_Exists(user_, is_exists);
    
    if is_exists = 0 then -- nếu không tồn tại
        RAISE_APPLICATION_ERROR(-20005, 'User "' || user_ || '" does not exist!');
    else
        begin
            str_SQL := 'ALTER USER "' || user_ || '" ACCOUNT LOCK';
            EXECUTE IMMEDIATE str_SQL;
        end;
    end if;
END;
/


-- Proc mở khoá tài khoản
CREATE OR REPLACE PROCEDURE SP_Unlock_User (
    user_ in char
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user có tồn tại không
    SP_Check_User_Exists(user_, is_exists);
    
    if is_exists = 0 then -- nếu không tồn tại
        RAISE_APPLICATION_ERROR(-20006, 'User "' || user_ || '" does not exist!');
    else
        begin
            str_SQL := 'ALTER USER "' || user_ || '" ACCOUNT UNLOCK';
            EXECUTE IMMEDIATE str_SQL;
        end;
    end if;
END;
/
--exec SP_Lock_User('SV4001');
--exec SP_Unlock_User('SV4001');


-- Proc kiểm tra role đã tồn tại hay chưa, trả về 0 nếu không tồn tại, trả về 1 nếu đã tồn tại
CREATE OR REPLACE PROCEDURE SP_Check_Role_Exists (
    role_ in char,
    result_ out number
)
AS
    cnt int;
BEGIN
    SELECT count(*) into cnt FROM DBA_ROLES WHERE role = role_;
    if cnt > 0 then
        result_ := 1;
    else
        result_ := 0;
    end if;
END;
/
declare
    res number;
begin
   SP_Check_Role_Exists('SV', res);
   dbms_output.put_line(res);
end;
/


-- Proc tạo mới role
CREATE OR REPLACE PROCEDURE SP_Create_Role (
    role_ in char,
    password_ in char
)
AS
    is_exists number;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra role đã tồn tại hay chưa
    SP_Check_Role_Exists(role_, is_exists);
    if is_exists = 0 then -- nếu chưa tồn tại
        begin
            if password_ is NULL then -- để trống password
                str_SQL := 'CREATE ROLE "' || role_ || '"';
            else
                str_SQL := 'CREATE ROLE "' || role_ || '" IDENTIFIED BY "' || password_ || '"';
            end if;
            EXECUTE IMMEDIATE str_SQL;
        end;
    else -- nếu đã tồn tại
        -- Ném lỗi
        RAISE_APPLICATION_ERROR(-20007, 'Role "' || role_ || '" has already existed!');
    end if;
END;
/
--exec sp_create_role('test_role', '111');

-- Proc xoá role
CREATE OR REPLACE PROCEDURE SP_Drop_Role (
    role_ IN VARCHAR2
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra role có tồn tại không
    SP_Check_Role_Exists(role_, is_exists);

    IF is_exists = 1 THEN -- nếu đã tồn tại
        str_SQL := 'DROP ROLE "' || role_ || '"';
        EXECUTE IMMEDIATE str_SQL;
    ELSE -- nếu chưa tồn tại
        RAISE_APPLICATION_ERROR(-20008, 'Role  "' || role_ || '" does not exist!');
    END IF;
END;
/
--exec SP_Drop_Role('test_role');


-- Proc chỉnh sửa mật khẩu cho role
CREATE OR REPLACE PROCEDURE SP_Change_Role_Password (
    role_ in char,
    new_pass in char,
    confirm_new_pass in char
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra role có tồn tại không
    SP_Check_Role_Exists(role_, is_exists);
    
    if is_exists = 0 then -- nếu không tồn tại
        RAISE_APPLICATION_ERROR(-20009, 'Role "' || role_ || '" does not exist!');
    else
        begin
            if new_pass != confirm_new_pass then
                RAISE_APPLICATION_ERROR(-20010, 'Different password!');
            else
                if new_pass is NULL then
                    str_SQL := 'ALTER ROLE "' || role_ || '" NOT IDENTIFIED';
                else
                    str_SQL := 'ALTER ROLE "' || role_ || '" IDENTIFIED BY "' || new_pass || '"';
                end if;
                EXECUTE IMMEDIATE str_SQL;
            end if;
        end;
    end if;
END;
/
--exec SP_CHANGE_ROLE_PASSWORD('test_role', '123', '123');
--SELECT ROLE, ROLE_ID, PASSWORD_REQUIRED, AUTHENTICATION_TYPE FROM DBA_ROLES WHERE ROLE = 'test_role'
--ORDER BY ROLE_ID;

--GRANT SELECT(MATB, NOIDUNG) ON ADMIN_OLS.THONGBAO TO SV4001;

-- Proc cấp quyền select trên thuộc tính của một bảng cho một user hoặc role (không dùng grant select vì trong Oracle không cho phép grant select trên vài thuộc tính của bảng)
CREATE OR REPLACE PROCEDURE SP_Grant_Select_Privilege (
    user_role in char,
    schema_name in char,
    table_name in char,
    column_name in char,
    withgrantoption in char
)
AS
    view_string char(100);
    is_exists number;
BEGIN
    -- Kiểm tra user/role có tồn tại hay chưa
    SP_Check_Role_Exists(user_role, is_exists);
    if is_exists = 0 then
        SP_Check_User_Exists(user_role, is_exists);
    end if;
    if is_exists = 0 then
        RAISE_APPLICATION_ERROR(-20011, 'User/Role "' || user_role || '" does not exist!');
    else
        begin
            view_string := 'V_' || table_name || '_' || user_role ;
--            SP_Drop_View(view_string);
            EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW ' || view_string || ' AS SELECT ' ||column_name || ' FROM ' ||schema_name || '.' || table_name;
            EXECUTE IMMEDIATE 'GRANT SELECT ON ' || view_string || ' TO ' || user_role || ' ' || withgrantoption;
        end;
    end if;
END;
/

--Test tạo view và phân quyền select cho user SV4001
--exec SP_Grant_Select_Privilege('SV4001', 'QLDH', 'DONVI', 'MADV, TENDV', 'WITH GRANT OPTION');

--xem các view đã tạo
--SELECT * FROM ALL_OBJECTS WHERE OBJECT_TYPE = 'VIEW' and OWNER = 'SYS';

-- Proc cấp quyền UPDATE trên thuộc tính của một bảng cho một user hoặc role
CREATE OR REPLACE PROCEDURE SP_Grant_Update_Privilege (
    user_role in char,
    table_name in char,
    column_name in char,
    withgrantoption char
)
as
    is_exists number;
begin
    -- Kiểm tra user/role có tồn tại hay chưa
    SP_Check_Role_Exists(user_role, is_exists);
    if is_exists = 0 then
        SP_Check_User_Exists(user_role, is_exists);
    end if;
    if is_exists = 0 then
        RAISE_APPLICATION_ERROR(-20012, 'User/Role "' || user_role || '" does not exist!');
    else
        EXECUTE IMMEDIATE 'GRANT UPDATE (' || column_name || ') ON ' || table_name || ' TO ' || user_role || ' ' || withgrantoption;
    end if;
end;
/
--exec SP_Grant_Update_Privilege('SV4001','DONVI','TenDV', '');


-- Proc cấp quyền insert trên một bảng cho một user hoặc role
CREATE OR REPLACE PROCEDURE SP_Grant_Insert_Privilege(
    user_role in char,
    table_name in char,
    withgrantoption char
)
as
    is_exists number;
begin
    -- Kiểm tra user/role có tồn tại hay chưa
    SP_Check_Role_Exists(user_role, is_exists);
    if is_exists = 0 then
        SP_Check_User_Exists(user_role, is_exists);
    end if;
    if is_exists = 0 then
        RAISE_APPLICATION_ERROR(-20013, 'User/Role "' || user_role || '" does not exist!');
    else
        EXECUTE IMMEDIATE 'GRANT INSERT ON ' || table_name || ' TO ' || user_role || ' ' || withgrantoption;
    end if;
end;
/
--exec SP_Grant_Insert_Privilege('SV4001','DONVI', '');


-- Proc cấp quyền delete trên một bảng cho một user hoặc role
CREATE OR REPLACE PROCEDURE SP_Grant_Delete_Privilege(
    user_role in char,
    table_name in char,
    withgrantoption char
)
as
    is_exists number;
begin
    -- Kiểm tra user/role có tồn tại hay chưa
    SP_Check_Role_Exists(user_role, is_exists);
    if is_exists = 0 then
        SP_Check_User_Exists(user_role, is_exists);
    end if;
    if is_exists = 0 then
        RAISE_APPLICATION_ERROR(-20014, 'User/Role "' || user_role || '" does not exist!');
    else
        EXECUTE IMMEDIATE 'GRANT DELETE ON ' || table_name || ' TO ' || user_role || ' ' || withgrantoption;
    end if;
end;
/
--exec SP_Grant_Delete_Privilege('SV4001','DONVI','WITH GRANT OPTION');
