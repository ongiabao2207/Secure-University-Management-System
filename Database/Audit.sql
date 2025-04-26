
CREATE PLUGGABLE DATABASE PROJECT_AUDIT_PDB 
  ADMIN USER pdbadmin IDENTIFIED BY pdbadmin123
  FILE_NAME_CONVERT = (
    'C:\APP\ASUS\PRODUCT\21C\ORADATA\XE\PDBSEED\', 
    'C:\APP\ASUS\PRODUCT\21C\ORADATA\XE\PROJECT_AUDIT_PDB\'
  )
  STORAGE UNLIMITED 
  TEMPFILE REUSE;

ALTER PLUGGABLE DATABASE PROJECT_AUDIT_PDB OPEN;

ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Mở lại PDB không ở chế độ hạn chế
ALTER PLUGGABLE DATABASE PROJECT_AUDIT_PDB CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE PROJECT_AUDIT_PDB OPEN;


ALTER SESSION SET CONTAINER = PROJECT_AUDIT_PDB;

CREATE USER project_audit IDENTIFIED BY matkhau123;
GRANT CONNECT, RESOURCE TO project_audit;
GRANT DBA TO project_audit;

SELECT NAME FROM V$PDBS;

ALTER SESSION SET CONTAINER = CDB$ROOT;
-- audit
-- 1. Kích hoạt ghi nhật ký hệ thống

-- Bật chế độ ghi nhật ký lưu vào DB
ALTER SYSTEM SET audit_trail = DB, EXTENDED SCOPE = SPFILE;

-- Khởi động lại CSDL để cấu hình có hiệu lực
SHUTDOWN IMMEDIATE;
STARTUP;

SHOW CON_NAME;

-- 2. Ghi nhật ký dùng Standard Audit
ALTER SESSION SET CONTAINER = QLHP;
-- Audit mọi hành động CRUD trên bảng SINHVIEN
AUDIT SELECT, INSERT, UPDATE, DELETE ON PDB_ADMIN.SINHVIEN BY ACCESS;

-- Audit khi người dùng không có quyền xóa mà vẫn cố DELETE trên DANGKY
AUDIT DELETE ON PDB_ADMIN.DANGKY WHENEVER NOT SUCCESSFUL;

-- Audit việc gọi thủ tục (PROCEDURE) ví dụ PROC_CAPNHAT_DIEM
AUDIT EXECUTE ON PDB_ADMIN.insert_sinhvien;
AUDIT EXECUTE ON PDB_ADMIN.insert_hocphan;


--GRANT SELECT, INSERT, UPDATE, DELETE ON SINHVIEN TO project_audit;
--GRANT EXECUTE ON insert_sinhvien TO project_audit;
--GRANT EXECUTE ON insert_hocphan TO project_audit;




SHOW PARAMETER audit_trail;

-- Kịch bản kiểm tra đề xuất – Standard Audit
-- 1. Truy vấn bảng SINHVIEN
SELECT * FROM pdb_admin.SINHVIEN;

SELECT * FROM DBA_OBJ_AUDIT_OPTS WHERE OBJECT_NAME = 'SINHVIEN';


SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'SELECT'
  AND OBJ_NAME = 'SINHVIEN'
ORDER BY TIMESTAMP DESC;

SELECT DISTINCT OBJ_NAME FROM DBA_AUDIT_TRAIL;

-- 2. Thêm sinh viên bằng thủ tục
BEGIN
  insert_sinhvien(
    'SV5000', N'Nguyễn Nhật Linh', 'Nữ',
    TO_DATE('2002-12-15','YYYY-MM-DD'),
    N'Trần Hưng Đạo, Hà Nội',
    '0901234567',
    'CNTT',
    N'Đang học'
  );
END;
/

-- 3. Gọi thủ tục thêm học phần
BEGIN
  insert_hocphan(
    'HP500', N'Trí tuệ nhân tạo',
    3, 2, 1,
    'CNTT'
  );
END;
/


-- 4. Cập nhật dữ liệu
UPDATE SINHVIEN
SET HOTEN = N'Nguyễn Nhật Linh (Updated)'
WHERE MASV = 'SV5000';

-- 5. Xóa sinh viên
DELETE FROM SINHVIEN WHERE MASV = 'SV5000';

------------------------------------------------------------------------------

ALTER SESSION SET CONTAINER = PROJECT_AUDIT_PDB;
-- Kiểm tra Truy vấn bảng SINHVIEN
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'SELECT'
  AND OBJ_NAME = 'SINHVIEN'
ORDER BY TIMESTAMP DESC;

-- Kiểm tra Thêm sinh viên bằng thủ tục insert_sinhvien
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'EXECUTE'
  AND OBJ_NAME = 'INSERT_SINHVIEN'
ORDER BY TIMESTAMP DESC;

SELECT ACTION_NAME, OBJ_NAME, USERNAME, TIMESTAMP
FROM DBA_AUDIT_TRAIL
WHERE TIMESTAMP > SYSDATE - 1
ORDER BY TIMESTAMP DESC;


-- Kiểm tra Thêm học phần bằng thủ tục insert_hocphan
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'EXECUTE'
  AND OBJ_NAME = 'INSERT_HOCPHAN'
ORDER BY TIMESTAMP DESC;

-- Kiểm tra Cập nhật sinh viên
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'UPDATE'
  AND OBJ_NAME = 'SINHVIEN'
ORDER BY TIMESTAMP DESC;

-- Kiểm tra Xóa sinh viên
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE ACTION_NAME = 'DELETE'
  AND OBJ_NAME = 'SINHVIEN'
ORDER BY TIMESTAMP DESC;

-- Câu 3
-- Câu a – Audit khi UPDATE điểm trong DANGKY, nhưng user KHÔNG phải “NV PKT”
-- Tạo user 
CREATE USER pkt_user IDENTIFIED BY matkhau123;
GRANT CONNECT, RESOURCE TO pkt_user;
GRANT UPDATE ON pdb_admin.DANGKY TO pkt_user;
GRANT RESTRICTED SESSION TO pkt_user;

-- Thực hiện ghi nhật ký bằng Fine-Grained Audit (FGA)
ALTER SESSION SET CONTAINER = QLHP;

-- Cập nhật bảng DANGKY khi không phải NV PKT
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'pdb_admin',
    object_name     => 'DANGKY',
    policy_name     => 'AUD_UPDATE_DANGKY_NOT_PKT',
    audit_condition => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''PKT_USER''',
    audit_column    => 'DIEMTH,DIEMQT,DIEMCK,DIEMTK',
    statement_types => 'UPDATE',
    audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED
  );
END;
/

-- Vào user project_audit kiểm tra
-- Chạy thử
UPDATE DANGKY
SET DIEMTH = 8.5
WHERE MASV = 'SV5000';


-- Đăng nhập pkt_user
UPDATE PROJECT_AUDIT.DANGKY
SET DIEMQT = 9
WHERE MASV = 'SV5000';

-- Kiểm tra log
SELECT DB_USER, OBJECT_NAME, POLICY_NAME, SQL_TEXT, TIMESTAMP
FROM DBA_FGA_AUDIT_TRAIL
WHERE OBJECT_NAME = 'DANGKY'
ORDER BY TIMESTAMP DESC;


-- Câu b – Audit SELECT LUONG, PHUCAP nếu KHÔNG phải “NV TCHC”
-- Tạo user
CREATE USER tchc_user IDENTIFIED BY matkhau123;
GRANT CONNECT, RESOURCE TO tchc_user;
GRANT SELECT ON PROJECT_AUDIT.NHANVIEN TO tchc_user;
GRANT RESTRICTED SESSION TO tchc_user;

-- Tạo chính sách FGA:
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'PROJECT_AUDIT',
    object_name     => 'NHANVIEN',
    policy_name     => 'AUD_SELECT_LUONG_PHUCAP_NOT_TCHC',
    audit_condition => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''TCHC_USER''',
    audit_column    => 'LUONG,PHUCAP',
    statement_types => 'SELECT',
    audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED
  );
END;
/

-- Đăng nhập project_audit → test:
SELECT HOTEN, LUONG, PHUCAP FROM NHANVIEN;

-- Kiểm tra log
SELECT * FROM DBA_FGA_AUDIT_TRAIL
WHERE OBJECT_NAME = 'NHANVIEN'
ORDER BY TIMESTAMP DESC;

-- Câu c 
ALTER SESSION SET CONTAINER = PROJECT_AUDIT_PDB;

BEGIN
  DBMS_FGA.DROP_POLICY('PROJECT_AUDIT', 'DANGKY', 'AUD_DANGKY_KHAC_MASV');
  DBMS_FGA.DROP_POLICY('PROJECT_AUDIT', 'DANGKY', 'AUD_DANGKY_SAI_THOIGIAN');
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/


-- Ghi log khi thao tác trên dòng MASV khác user
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'PROJECT_AUDIT',
    object_name     => 'DANGKY',
    policy_name     => 'AUD_DANGKY_KHAC_MASV',
    audit_condition => 'MASV IS NOT NULL AND MASV != SYS_CONTEXT(''USERENV'', ''SESSION_USER'')',
    statement_types => 'INSERT, UPDATE, DELETE',
    audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED
  );
END;
/

-- Ghi log nếu thao tác ngoài thời gian cho phép
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'PROJECT_AUDIT',
    object_name     => 'DANGKY',
    policy_name     => 'AUD_DANGKY_SAI_THOIGIAN',
    audit_condition => '
      NOT (
        EXTRACT(DAY FROM SYSDATE) BETWEEN 1 AND 14 AND
        EXTRACT(MONTH FROM SYSDATE) IN (1, 5, 9)
      )
    ',
    statement_types => 'INSERT, UPDATE, DELETE',
    audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED
  );
END;
/




-- Tạo user
CREATE USER SV5000 IDENTIFIED BY sv5000pass;
GRANT CONNECT, RESOURCE TO SV5000;
GRANT INSERT, UPDATE, DELETE ON PROJECT_AUDIT.DANGKY TO SV5000;
GRANT RESTRICTED SESSION TO SV5000;
-- Cấp quota UNLIMITED cho user (ví dụ SV5000)
ALTER USER SV5000 QUOTA UNLIMITED ON SYSTEM;


-- Kiểm tra
-- Đăng nhập bằng user SV5000
-- Trong ngày 1/4, ko bị log
INSERT INTO DANGKY (MASV, MAMM, DIEMTH, DIEMQT, DIEMCK, DIEMTK)
VALUES ('SV5000', 'MM001', 8.0, 8.0, 8.0, 8.0);

-- Vẫn đăng nhập user SV5000
-- Nhưng ghi sai MASV hoặc sai thời gian
INSERT INTO DANGKY (MASV, MAMM, DIEMTH, DIEMQT, DIEMCK, DIEMTK)
VALUES ('SV0100', 'MM011', 9, 9, 9, 9);

DELETE FROM DANGKY
WHERE MASV = 'SV0100' AND MAMM = 'MM011';

UPDATE DANGKY
SET DIEMCK = 9.5
WHERE MASV = 'SV0100';


-- kiểm tra log
ALTER SESSION SET CONTAINER = PROJECT_AUDIT_PDB;

SELECT DB_USER, OBJECT_NAME, POLICY_NAME, STATEMENT_TYPE, SQL_TEXT, TIMESTAMP
FROM DBA_FGA_AUDIT_TRAIL
WHERE OBJECT_NAME = 'DANGKY'
ORDER BY TIMESTAMP DESC;



-- Câu 4
-- Kiểm tra tất cả hành vi đã được log (Standard Audit)
SELECT USERNAME, ACTION_NAME, OBJ_NAME, TIMESTAMP, SQL_TEXT
FROM DBA_AUDIT_TRAIL
WHERE OBJ_NAME IN ('SINHVIEN', 'DANGKY', 'INSERT_SINHVIEN', 'INSERT_HOCPHAN')
ORDER BY TIMESTAMP DESC;

-- Truy vấn log Fine-Grained Audit (FGA)
SELECT DB_USER, OBJECT_NAME, POLICY_NAME, STATEMENT_TYPE, SQL_TEXT, TIMESTAMP
FROM DBA_FGA_AUDIT_TRAIL
ORDER BY TIMESTAMP DESC;
