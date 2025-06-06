--ALTER PLUGGABLE DATABASE QLHP OPEN;
--ALTER SESSION SET CONTAINER = PDB_QLDH;
-- Tạo các vai trò
CREATE ROLE Role_NVCB;
CREATE ROLE Role_GV;
CREATE ROLE Role_TRGDV;
CREATE ROLE Role_NV_TCHC;
CREATE ROLE Role_NV_PDT;
CREATE ROLE Role_NV_CTSV;
CREATE ROLE Role_NV_PKT;
CREATE ROLE Role_SV;

-- Câu 1

-- Cấp quyền truy cập bảng NHANVIEN và DONVI cho các vai trò
--GRANT SELECT ON NHANVIEN TO Role_NVCB;
--GRANT SELECT ON NHANVIEN TO Role_TRGDV;
--GRANT SELECT ON NHANVIEN TO Role_NV_TCHC;
--GRANT SELECT ON DONVI TO Role_TRGDV;

-- Tạo view View_NHANVIEN_Read_Self
CREATE OR REPLACE VIEW View_NHANVIEN_Read_Self AS
SELECT MANV, HOTEN, PHAI, NGSINH, LUONG, PHUCAP, DT, VAITRO, MADV
FROM NHANVIEN
WHERE MANV = SYS_CONTEXT('USERENV', 'SESSION_USER');

-- Cấp quyền cho Role_NVCB
GRANT SELECT, UPDATE(DT) ON View_NHANVIEN_Read_Self TO Role_NVCB, Role_GV, Role_TRGDV, Role_NV_TCHC, Role_NV_PDT


-- Tạo view View_NHANVIEN_Read_Unit_Employees
CREATE OR REPLACE VIEW View_NHANVIEN_Read_Unit_Employees AS
SELECT n.MANV, n.HOTEN, n.PHAI, n.NGSINH, n.DT, n.VAITRO, n.MADV
FROM NHANVIEN n
JOIN DONVI d ON n.MADV = d.MADV
WHERE d.TRGDV = SYS_CONTEXT('USERENV', 'SESSION_USER')
AND n.MANV != SYS_CONTEXT('USERENV', 'SESSION_USER');

-- Cấp quyền cho Role_TRGDV
GRANT SELECT ON View_NHANVIEN_Read_Unit_Employees TO Role_TRGDV;

-- Tạo view View_NHANVIEN_Manage_Employees
CREATE OR REPLACE VIEW View_NHANVIEN_Manage_Employees AS
SELECT MANV, HOTEN, PHAI, NGSINH, LUONG, PHUCAP, DT, VAITRO, MADV
FROM NHANVIEN;

-- Cấp quyền cho Role_NV_TCHC
GRANT SELECT, INSERT, UPDATE, DELETE ON View_NHANVIEN_Manage_Employees TO Role_NV_TCHC;

CREATE USER NV0001 IDENTIFIED BY 123;
CREATE USER NV0612 IDENTIFIED BY 123;
CREATE USER NV0746 IDENTIFIED BY 123;
CREATE USER NV0016 IDENTIFIED BY 123;
CREATE USER NV0716 IDENTIFIED BY 123;

GRANT CREATE SESSION TO NV0001, NV0612, NV0746, NV0016, NV0716;

GRANT Role_NVCB TO NV0016;
GRANT Role_GV TO NV0612;
GRANT Role_TRGDV TO NV0001;
GRANT Role_NV_TCHC TO NV0746;
GRANT Role_NV_PDT TO NV0716;

--Kiem tra với user NV0001
SET ROLE ROLE_NVCB
SELECT * FROM QLDH.View_NHANVIEN_Read_Self;
UPDATE QLDH.View_NHANVIEN_Read_Self SET DT = '0999999999';

--Kiểm tra với user NV0756 
SET ROLE ROLE_TRGDV;
SELECT * FROM QLDH.View_NHANVIEN_Read_Unit_Employees;

-- Kiểm tra với user NV0075
SET ROLE Role_NV_TCHC;
SELECT * FROM QLDH.View_NHANVIEN_Manage_Employees;

INSERT INTO QLDH.View_NHANVIEN_Manage_Employees (
    MANV, HOTEN, PHAI, NGSINH, LUONG, PHUCAP, DT, VAITRO, MADV
) VALUES (
    'NV0999', 'Nguyễn Văn Thử', 'Nam', TO_DATE('01-01-1990', 'DD-MM-YYYY'),
    15000000, 2000000, '0123455677', 'NV TCHC', 'TCHC'
);

UPDATE QLDH.View_NHANVIEN_Manage_Employees
SET HOTEN = 'Nguyễn Văn Đổi'
WHERE MANV = 'NV0999';

DELETE FROM QLDH.View_NHANVIEN_Manage_Employees
WHERE MANV = 'NV0999';

-- Câu 2
-- Role_GV: chỉ cần SELECT trên MOMON
GRANT SELECT ON MOMON TO Role_GV;

-- Role_NV_PDT: toàn quyền trên MOMON
GRANT SELECT, INSERT, UPDATE, DELETE ON MOMON TO Role_NV_PDT;

-- Role_TRGDV: cần truy cập MOMON, NHANVIEN, DONVI
GRANT SELECT ON MOMON TO Role_TRGDV;
GRANT SELECT ON NHANVIEN TO Role_TRGDV;
GRANT SELECT ON DONVI TO Role_TRGDV;

-- Role_SV: cần truy cập MOMON, HOCPHAN, SINHVIEN
GRANT SELECT ON MOMON TO Role_SV;
GRANT SELECT ON HOCPHAN TO Role_SV;
GRANT SELECT ON SINHVIEN TO Role_SV;

--Xem bảng momon mà bản thân giảng viên được phân công
CREATE OR REPLACE VIEW View_MOMON_Read_Self AS
SELECT * FROM MOMON
WHERE MAGV = SYS_CONTEXT('USERENV', 'SESSION_USER');

GRANT SELECT ON View_MOMON_Read_Self TO Role_GV;

--xem bảng mở môn của học kì hiện tại
CREATE OR REPLACE VIEW View_MOMON_Manage_Current AS
SELECT *
FROM MOMON
WHERE
  HK = CASE
         WHEN EXTRACT(MONTH FROM SYSDATE) BETWEEN 9 AND 12 THEN 1
         WHEN EXTRACT(MONTH FROM SYSDATE) BETWEEN 1 AND 4 THEN 2
         ELSE 3  -- tháng 5–8
       END
  AND NAM = CASE
              WHEN EXTRACT(MONTH FROM SYSDATE) BETWEEN 9 AND 12 THEN EXTRACT(YEAR FROM SYSDATE)
              ELSE EXTRACT(YEAR FROM SYSDATE) - 1
            END
WITH CHECK OPTION;


GRANT SELECT, INSERT, UPDATE, DELETE ON View_MOMON_Manage_Current TO Role_NV_PDT;

--xem bảng mở môn của tất cả học kì
/*CREATE OR REPLACE VIEW View_MOMON_Read_All AS
SELECT * FROM MOMON;

GRANT SELECT ON View_MOMON_Read_All TO Role_NV_PDT;*/

--xem các phân công giảng dạy của giảng viên trong đơn vị mà mình làm trưởng 
CREATE OR REPLACE VIEW View_MOMON_Read_Unit AS
SELECT M.*
FROM MOMON M
JOIN NHANVIEN GV ON M.MAGV = GV.MANV
JOIN DONVI D ON GV.MADV = D.MADV
WHERE D.TRGDV = SYS_CONTEXT('USERENV', 'SESSION_USER');

GRANT SELECT ON View_MOMON_Read_Unit TO Role_TRGDV;

--xem bảng mở môn với những sinh viên có trạng thái là đâng học trong khoa
CREATE OR REPLACE VIEW View_MOMON_Read_Faculty AS
SELECT M.*
FROM SINHVIEN SV
JOIN HOCPHAN HP ON SV.KHOA = HP.MADV
JOIN MOMON M ON M.MAHP = HP.MAHP
WHERE SV.MASV = SYS_CONTEXT('USERENV', 'SESSION_USER')
  AND UPPER(SV.TINHTRANG) = N'ĐANG HỌC';

GRANT SELECT ON View_MOMON_Read_Faculty TO Role_SV;

--tạo user là sv0030
CREATE USER SV0006 IDENTIFIED BY 123;
GRANT CREATE SESSION TO SV0006;

GRANT Role_SV TO SV0006;
--Kiểm tra với user giangr viên NV0612
SET ROLE Role_GV;
SELECT * FROM QLDH.View_MOMON_Read_Self;
--Kiểm tra user nhân viên PDT NV0042
--INSERT INTO MOMON (MAMM, MAHP, MAGV, HK, NAM) VALUES ('MM013', 'HP001', 'NV0612', 2, 2025);
SET ROLE Role_NV_PDT;
SELECT * FROM QLDH.View_MOMON_Manage_Current;

INSERT INTO QLDH.View_MOMON_Manage_Current (MAMM, MAHP, MAGV, HK, NAM)
VALUES ('MM999', 'HP001', 'NV0612', 2, 2025);

UPDATE QLDH.View_MOMON_Manage_Current
SET MAGV = 'NV0613'
WHERE MAMM = 'MM999';

DELETE FROM QLDH.View_MOMON_Manage_Current
WHERE MAMM = 'MM999';

--SELECT * FROM SYS.View_MOMON_Read_All;
--SELECT * FROM MOMON;

--Kiểm tra với user TRGPDT NV0756
SET ROLE Role_TRGDV;
SELECT * FROM QLDH.View_MOMON_Read_Unit;

--Kiểm tra với user sinh viên SV0030 
SET ROLE Role_SV;
SELECT * FROM QLDH.View_MOMON_Read_Faculty;

SELECT * FROM QLDH.MOMON;

--
GRANT SELECT ON QLDH.SINHVIEN TO SV0006;