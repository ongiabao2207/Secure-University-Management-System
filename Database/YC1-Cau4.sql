-- Mở pluggable database
ALTER PLUGGABLE DATABASE PDB_QLDH OPEN;
ALTER SESSION SET CONTAINER = PDB_QLDH;

GRANT EXECUTE ON DBMS_RLS TO QLDH;

-- Kiểm tra schema hiện tại
--SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema FROM DUAL;
--
---- Tạo schema VPD
--BEGIN
--   EXECUTE IMMEDIATE 'CREATE USER VPD IDENTIFIED BY 123';
--EXCEPTION
--   WHEN OTHERS THEN NULL;
--END;
--/
--GRANT CONNECT, RESOURCE TO VPD;
--ALTER USER VPD QUOTA UNLIMITED ON SYSTEM;
--GRANT EXECUTE ON DBMS_RLS TO QLDH;
--
---- Chuyển sang schema VPD
--ALTER SESSION SET CURRENT_SCHEMA = VPD;

---- Tạo các bảng trong schema VPD
--CREATE TABLE VPD.DONVI AS SELECT * FROM SYS.DONVI;
--CREATE TABLE VPD.NHANVIEN AS SELECT * FROM SYS.NHANVIEN;
--CREATE TABLE VPD.SINHVIEN AS SELECT * FROM SYS.SINHVIEN;
--CREATE TABLE VPD.HOCPHAN AS SELECT * FROM SYS.HOCPHAN;
--CREATE TABLE VPD.MOMON AS SELECT * FROM SYS.MOMON;
--CREATE TABLE VPD.DANGKY AS SELECT * FROM SYS.DANGKY;
--
--INSERT INTO VPD.DONVI SELECT * FROM SYS.DONVI;
--INSERT INTO VPD.NHANVIEN SELECT * FROM SYS.NHANVIEN;
--INSERT INTO VPD.SINHVIEN SELECT * FROM SYS.SINHVIEN;
--INSERT INTO VPD.HOCPHAN SELECT * FROM SYS.HOCPHAN;
--INSERT INTO VPD.MOMON SELECT * FROM SYS.MOMON;
--INSERT INTO VPD.DANGKY SELECT * FROM SYS.DANGKY;


-- Cấp quyền cho các vai trò
CREATE ROLE Role_SV;
CREATE ROLE Role_GV;
CREATE ROLE Role_NV_PDT;
CREATE ROLE Role_NV_PKT;

GRANT SELECT, INSERT, UPDATE, DELETE ON DANGKY TO Role_SV;
GRANT SELECT ON DANGKY TO Role_GV;
GRANT SELECT ON MOMON TO Role_GV;
GRANT SELECT ON HOCPHAN TO Role_GV;
GRANT SELECT, INSERT, UPDATE, DELETE ON DANGKY TO Role_NV_PDT;
GRANT SELECT, UPDATE (DIEMTH, DIEMQT, DIEMCK, DIEMTK) ON DANGKY TO Role_NV_PKT;
GRANT SELECT ON NHANVIEN TO Role_NV_PKT;

-- Tạo user
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER SV0001 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER NV0612 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER NV0716 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER NV0742 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
GRANT CREATE SESSION TO NV0716, SV0001, NV0612, NV0742;

-- Gán role cho user
GRANT Role_SV TO SV0001;
GRANT Role_NV_PDT TO NV0716;
GRANT Role_NV_PKT TO NV0742;
GRANT Role_GV TO NV0612;

-- Trigger kiểm tra MASV cho sinh viên khi INSERT
CREATE OR REPLACE TRIGGER check_masv_insert
BEFORE INSERT ON DANGKY
FOR EACH ROW
DECLARE
    v_user VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
BEGIN
    IF v_user LIKE 'SV%' THEN
        IF :NEW.MASV != v_user THEN
            RAISE_APPLICATION_ERROR(-20001, 'Sinh viên chỉ được thêm dữ liệu của chính mình');
        END IF;
    END IF;
END;
/

-- Trigger kiểm tra giới hạn 14 ngày và điểm số NULL cho sinh viên và NV PĐT
CREATE OR REPLACE TRIGGER CHECK_14_DAYS
BEFORE INSERT OR UPDATE OR DELETE ON DANGKY
FOR EACH ROW
DECLARE
    v_user VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_vaitro VARCHAR2(20);
    v_start_date DATE;
    --v_current_date DATE := SYSDATE; 
    v_current_date DATE := TO_DATE('2025-09-02', 'YYYY-MM-DD');

    v_semester_start DATE;
BEGIN
    -- Xác định ngày bắt đầu học kỳ dựa vào tháng hiện tại
    IF TO_CHAR(v_current_date, 'MM') IN ('09', '10', '11', '12') THEN
        v_semester_start := TO_DATE(TO_CHAR(v_current_date, 'YYYY') || '-09-01', 'YYYY-MM-DD'); -- Học kỳ 1 (tháng 9)
    ELSIF TO_CHAR(v_current_date, 'MM') IN ('01', '02', '03', '04') THEN
        v_semester_start := TO_DATE(TO_CHAR(v_current_date, 'YYYY') || '-01-01', 'YYYY-MM-DD'); -- Học kỳ 2 (tháng 1)
    ELSIF TO_CHAR(v_current_date, 'MM') IN ('05', '06', '07', '08') THEN
        v_semester_start := TO_DATE(TO_CHAR(v_current_date, 'YYYY') || '-05-01', 'YYYY-MM-DD'); -- Học kỳ 3 (tháng 5)
    END IF;

    -- Kiểm tra vai trò của người dùng
    IF v_user LIKE 'SV%' THEN
        v_vaitro := 'SV';
    ELSE
        BEGIN
            SELECT MADV INTO v_vaitro
            FROM NHANVIEN
            WHERE MANV = v_user;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_vaitro := 'UNKNOWN';
        END;
    END IF;

    -- Kiểm tra xem thao tác có trong 14 ngày đầu học kỳ không
    IF v_current_date > v_semester_start + 14 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Chỉ được thao tác trong 14 ngày đầu học kỳ');
    END IF;

    -- Kiểm tra vai trò và dữ liệu điểm số
    IF v_vaitro IN ('SV', 'PDT') THEN
        -- Kiểm tra điểm số NULL khi INSERT hoặc UPDATE
        IF INSERTING OR UPDATING THEN
            IF :NEW.DIEMTH IS NOT NULL OR :NEW.DIEMQT IS NOT NULL OR
               :NEW.DIEMCK IS NOT NULL OR :NEW.DIEMTK IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20003, 'Sinh viên và NV PĐT không được nhập điểm số');
            END IF;
        END IF;
    END IF;
END;

-- Tạo hàm chính sách DANGKY_POLICY_FUNC
CREATE OR REPLACE FUNCTION DANGKY_POLICY_FUNC (
    p_schema IN VARCHAR2,
    p_object IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(30);
    v_vaitro VARCHAR2(30);
    v_madv VARCHAR2(30);
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

    IF SYS_CONTEXT('USERENV', 'ISDBA') = 'TRUE' OR v_user = 'QLDH' THEN
        RETURN '1=1';

    ELSIF v_user LIKE 'SV%' THEN
        RETURN 'MASV = ''' || v_user || '''';

    ELSE
        BEGIN
            SELECT VAITRO, MADV INTO v_vaitro, v_madv
            FROM NHANVIEN_VPD
            WHERE MANV = v_user;

            IF v_vaitro = 'NV PKT' THEN
                RETURN '1=1';

            ELSIF v_vaitro = 'NV PDT' THEN
                RETURN '1=1';

            ELSIF v_vaitro = 'GV' THEN
                RETURN 'MAMM IN (
                    SELECT MAMM
                    FROM MOMON
                    WHERE MAGV = ''' || v_user || '''
                )';

            ELSE
                RETURN '1=0';
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN '1=0';
        END;
    END IF;
END;
/
-- Áp dụng chính sách cho DANGKY
BEGIN
   DBMS_RLS.ADD_POLICY(
      object_schema    => 'QLDH',
      object_name      => 'DANGKY',
      policy_name      => 'DANGKY_POLICY',
      function_schema  => 'QLDH',
      policy_function  => 'DANGKY_POLICY_FUNC',
      statement_types  => 'SELECT, UPDATE, DELETE',
      update_check     => TRUE
   );
END;
/

/*
-- Kiểm tra
SELECT * FROM DANGKY;

INSERT INTO DANGKY (MASV, MAMM)
VALUES ('SV0001', 'MM002');

UPDATE DANGKY
SET MAMM = 'MM003'
WHERE MASV = 'SV0001' AND MAMM = 'MM003';
DELETE FROM DANGKY
WHERE MASV = 'SV0001' AND MAMM = 'MM002';

BEGIN
   DBMS_RLS.DROP_POLICY(
      object_schema    => 'QLDH',
      object_name      => 'DANGKY', 
      policy_name      => 'DANGKY_POLICY' 
   );
END;
/
*/

