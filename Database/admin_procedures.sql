ALTER SESSION SET CONTAINER=PDB_QLDH;


-- Xem danh sách người dùng trong hệ thống
SELECT USERNAME, USER_ID, ACCOUNT_STATUS, CREATED FROM DBA_USERS
ORDER BY USER_ID;


-- Xem danh sách vai trò trong hệ thống
SELECT ROLE, ROLE_ID, PASSWORD_REQUIRED, AUTHENTICATION_TYPE FROM DBA_ROLES
ORDER BY ROLE_ID;


-- Proc kiểm tra user đã tồn tại hay chưa, trả về 0 nếu không tồn tại, trả về 1 nếu đã tồn tại
CREATE OR REPLACE PROCEDURE SP_CheckUserExists (
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
CREATE OR REPLACE PROCEDURE SP_CreateUser (
    username_ in char,
    password_ in char
)
AS
    is_exists number;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user đã tồn tại hay chưa
    SP_CheckUserExists(username_, is_exists);
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
--exec sp_createuser('SV4001', '123');

-- Proc xoá user
CREATE OR REPLACE PROCEDURE SP_DropUser (
    username_ IN VARCHAR2
)
AS
    is_exists NUMBER;
    str_SQL VARCHAR2(1000);
BEGIN
    -- Kiểm tra user có tồn tại không
    SP_CheckUserExists(username_, is_exists);

    IF is_exists = 1 THEN -- nếu đã tồn tại
        str_SQL := 'DROP USER "' || username_ || '" CASCADE';
        EXECUTE IMMEDIATE str_SQL;
    ELSE -- nếu chưa tồn tại
        RAISE_APPLICATION_ERROR(-20002, 'User "' || username_ || '" does not exist!');
    END IF;
END;
/
--exec SP_DropUser('SV4001');