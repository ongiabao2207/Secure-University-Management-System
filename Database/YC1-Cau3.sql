-- Mở pluggable database
ALTER PLUGGABLE DATABASE QLHP OPEN;
ALTER SESSION SET CONTAINER = QLHP;
-- Kiểm tra schema hiện tại
SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema FROM DUAL;
-- Tạo schema VPD 
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER VPD IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL; 
END;
/
GRANT CONNECT, RESOURCE TO VPD;
ALTER USER VPD QUOTA UNLIMITED ON SYSTEM;
GRANT EXECUTE ON DBMS_RLS TO VPD;
-- Chuyển sang schema VPD
ALTER SESSION SET CURRENT_SCHEMA = VPD;

-- Tạo bảng mới trong schema VPD
CREATE TABLE VPD.SINHVIEN AS SELECT * FROM SYS.SINHVIEN;
CREATE TABLE VPD.NHANVIEN AS SELECT * FROM SYS.NHANVIEN;
CREATE TABLE VPD.DONVI AS SELECT * FROM SYS.DONVI;
-- Tạo bảng tạm VPD.NHANVIEN_VPD
CREATE TABLE VPD.NHANVIEN_VPD (
    MANV VARCHAR2(30),
    MADV VARCHAR2(30),
    VAITRO VARCHAR2(30)
);
-- Chèn dữ liệu từ VPD.NHANVIEN vào VPD.NHANVIEN_VPD
INSERT INTO VPD.NHANVIEN_VPD (MANV, MADV, VAITRO)
SELECT MANV, MADV, VAITRO FROM VPD.NHANVIEN;
--COPY DỮ LIỆU TỪ BẢNG TRONG SYS SANG VPD
MERGE INTO VPD.SINHVIEN d
USING SYS.SINHVIEN s
ON (d.MASV = s.MASV)  
WHEN NOT MATCHED THEN
    INSERT (MASV, HOTEN, PHAI, NGSINH, ĐCHI, ĐT, KHOA, TINHTRANG)
    VALUES (s.MASV, s.HOTEN, s.PHAI, s.NGSINH, s.ĐCHI, s.ĐT, s.KHOA, s.TINHTRANG);
    
MERGE INTO VPD.NHANVIEN d
USING SYS.NHANVIEN s
ON (d.MANV = s.MANV)  
WHEN NOT MATCHED THEN
    INSERT (MANV, HOTEN, PHAI, NGSINH, LUONG, PHUCAP, DT, VAITRO, MADV)
    VALUES (s.MANV, s.HOTEN, s.PHAI, s.NGSINH, s.LUONG, s.PHUCAP, s.DT, s.VAITRO, s.MADV);

MERGE INTO VPD.DONVI d
USING SYS.DONVI s
ON (d.MADV = s.MADV)  
WHEN NOT MATCHED THEN
    INSERT (MADV, TENDV, LOAIDV, TRGDV)
    VALUES (s.MADV, s.TENDV, s.LOAIDV, s.TRGDV);

/*-- Tạo các role
CREATE ROLE Role_NVCB;
CREATE ROLE Role_GV;
CREATE ROLE Role_TRGDV;
CREATE ROLE Role_NV_TCHC;
CREATE ROLE Role_NV_PDT;
CREATE ROLE Role_NV_CTSV;
CREATE ROLE Role_NV_PKT;
CREATE ROLE Role_SV;
*/
-- Gán quyền cho các role
GRANT SELECT, UPDATE(ĐCHI, ĐT) ON VPD.SINHVIEN TO Role_SV;
GRANT SELECT, UPDATE(TINHTRANG) ON VPD.SINHVIEN TO Role_NV_PDT;
GRANT SELECT ON VPD.NHANVIEN TO Role_NV_PDT;
GRANT SELECT, INSERT, DELETE, UPDATE ON VPD.SINHVIEN TO Role_NV_CTSV;
GRANT SELECT ON VPD.NHANVIEN TO Role_NV_CTSV;
GRANT SELECT ON VPD.NHANVIEN_VPD TO Role_NV_CTSV;
GRANT SELECT ON VPD.DONVI TO Role_NV_CTSV;

-- Tạo user mẫu và gán role cho user
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
   EXECUTE IMMEDIATE 'CREATE USER NV0003 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'CREATE USER NV0042 IDENTIFIED BY 123';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/
GRANT CREATE SESSION TO NV0003, SV0001, NV0612, NV0042;
-- Gán role cho user
GRANT Role_SV TO SV0001;
GRANT Role_NV_PDT TO NV0042;
GRANT Role_NV_CTSV TO NV0003;
GRANT Role_GV TO NV0612;


-- Tạo hàm SV_POLICY_FUNC 
CREATE OR REPLACE FUNCTION VPD.SINHVIEN_POLICY_FUNC(
    p_schema IN VARCHAR2,
    p_object IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_madv VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('User: ' || v_user);

    IF SYS_CONTEXT('USERENV', 'ISDBA') = 'TRUE' OR v_user = 'VPD' THEN
        RETURN '1=1';
    ELSIF v_user LIKE 'SV%' THEN
        RETURN 'MASV = ''' || v_user || '''';
    ELSE
        SELECT MADV INTO v_madv 
        FROM VPD.NHANVIEN_VPD 
        WHERE MANV = v_user 
        AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('MADV: ' || NVL(v_madv, 'NULL'));

        IF v_madv = 'CTSV' THEN
            RETURN '1=1';
        ELSIF v_madv = 'PDT' THEN
            RETURN '1=1';
        ELSIF v_madv IS NOT NULL THEN
            RETURN 'KHOA = ''' || v_madv || '''';
        ELSE
            RETURN '1=0';
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found for user: ' || v_user);
        RETURN '1=0';
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Too many rows for user: ' || v_user);
        RETURN '1=0';
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in SINHVIEN_POLICY_FUNC: ' || SQLERRM);
        RETURN '1=0';
END;
/

-- Tạo hàm GV_POLICY_FUNC 
CREATE OR REPLACE FUNCTION VPD.GV_POLICY_FUNC (
    obj_schema VARCHAR2,
    obj_name   VARCHAR2
) RETURN VARCHAR2
AS
    v_user  VARCHAR2(30);
    v_madv  VARCHAR2(30);
    v_vaitro VARCHAR2(30);
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

    IF v_user = 'VPD' OR SYS_CONTEXT('USERENV', 'ISDBA') = 'TRUE' THEN
        RETURN '1=1';
    END IF;

    BEGIN
        SELECT MADV INTO v_madv 
        FROM VPD.NHANVIEN_VPD 
        WHERE MANV = v_user 
        AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('MADV: ' || NVL(v_madv, 'NULL'));
        
        IF v_madv = 'PDT' THEN
            RETURN '1=1'; -- Cho phép PDT thấy toàn bộ bảng
        ELSIF v_vaitro = 'GV' THEN
            RETURN 'KHOA = ''' || v_madv || ''''; -- Giới hạn GV theo MADV
        ELSE
            RETURN '1=0';
        END IF;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '1=0';
    END;
END;
/

BEGIN
   DBMS_RLS.ADD_POLICY(
      object_schema    => 'VPD',
      object_name      => 'SINHVIEN',
      policy_name      => 'SINHVIEN_POLICY',
      function_schema  => 'VPD',
      policy_function  => 'SINHVIEN_POLICY_FUNC',
      statement_types  => 'SELECT, UPDATE, DELETE',
      update_check     => TRUE
   );
   DBMS_RLS.ADD_POLICY(
      object_schema    => 'VPD',
      object_name      => 'NHANVIEN',
      policy_name      => 'GV_POLICY',
      function_schema  => 'VPD',
      policy_function  => 'GV_POLICY_FUNC',
      statement_types  => 'SELECT'
   );
END;
/

CREATE OR REPLACE PROCEDURE VPD.insert_sinhvien (
    p_MASV   IN VARCHAR2,
    p_HOTEN  IN NVARCHAR2,
    p_PHAI   IN NVARCHAR2,
    p_NGSINH IN DATE,
    p_ĐCHI   IN NVARCHAR2,
    p_ĐT     IN VARCHAR2,
    p_KHOA   IN VARCHAR2
) AS
    v_count INT;
    v_masv_count INT;
BEGIN
    -- Kiểm tra mã khoa có tồn tại và đúng loại là 'Khoa'
    SELECT COUNT(*) INTO v_count
    FROM VPD.DONVI
    WHERE MADV = p_KHOA AND LOAIDV = 'Khoa';

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Mã khoa không hợp lệ hoặc không phải là khoa');
    END IF;

    -- Kiểm tra tính duy nhất của MASV
    SELECT COUNT(*) INTO v_masv_count
    FROM VPD.SINHVIEN
    WHERE MASV = p_MASV;

    IF v_masv_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Mã sinh viên đã tồn tại');
    END IF;

    -- Thêm sinh viên, mặc định TINHTRANG là NULL
    INSERT INTO VPD.SINHVIEN (
        MASV, HOTEN, PHAI, NGSINH, ĐCHI, ĐT, KHOA, TINHTRANG
    ) VALUES (
        p_MASV, p_HOTEN, p_PHAI, p_NGSINH, p_ĐCHI, p_ĐT, p_KHOA, NULL
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Lỗi khi thêm sinh viên: ' || SQLERRM);
END insert_sinhvien;
/

GRANT EXECUTE ON VPD.insert_sinhvien TO Role_NV_CTSV;

CREATE OR REPLACE TRIGGER trg_prevent_pctsv_update_tinhtrang
BEFORE UPDATE OF TINHTRANG ON SINHVIEN
FOR EACH ROW
DECLARE
    v_madv VARCHAR2(30);
BEGIN
    -- Lấy mã đơn vị của nhân viên
    SELECT MADV INTO v_madv
    FROM VPD.NHANVIEN
    WHERE MANV = SYS_CONTEXT('USERENV', 'SESSION_USER');

    IF v_madv = 'CTSV' THEN
        RAISE_APPLICATION_ERROR(-20002, 'NV CTSV không được cập nhật tình trạng học vụ.');
    END IF;
END;
/

-- Kiểm tra
ALTER SESSION SET CURRENT_SCHEMA = VPD;

SELECT * FROM VPD.SINHVIEN;
SELECT * FROM VPD.NHANVIEN;
SELECT * FROM VPD.DONVI;

UPDATE VPD.SINHVIEN
SET TINHTRANG = 'Bảo lưu'
WHERE MASV = 'SV0001';

BEGIN
    VPD.insert_sinhvien(
        p_MASV   => 'SV1000',
        p_HOTEN  => N'Nguyen Thi Hoa',
        p_PHAI   => N'Nữ',
        p_NGSINH => TO_DATE('2001-02-15', 'YYYY-MM-DD'),
        p_ĐCHI   => N'123 Đường Láng, Hà Nội',
        p_ĐT     => '0987654321',
        p_KHOA   => 'HOA'
    );
    COMMIT;
END;
/

/*BEGIN
   DBMS_RLS.DROP_POLICY(
      object_schema => 'VPD',
      object_name   => 'SINHVIEN',
      policy_name   => 'SINHVIEN_POLICY'
   );
   DBMS_RLS.DROP_POLICY(
      object_schema => 'VPD',
      object_name   => 'NHANVIEN',
      policy_name   => 'GV_POLICY'
   );
END;
/*/
