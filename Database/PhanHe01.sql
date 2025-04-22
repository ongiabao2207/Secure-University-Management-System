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
--   SP_CheckUserExists('NV001', res);
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