
-- ================================================
-- BACKUP & RESTORE SCRIPT – PHÂN HỆ 2 – YÊU CẦU 4
-- ATBM 2025 – Nhóm 04 – Trường ĐH KHTN
-- Phương pháp: Data Pump dùng DBMS_DATAPUMP (Oracle nội bộ)
-- ================================================

-- Bước 1: Tạo thư mục backup (đường dẫn phải tồn tại trên hệ thống máy chủ Oracle)
CREATE OR REPLACE DIRECTORY dpdir AS '/u01/app/oracle/oradata/backup';
GRANT READ, WRITE ON DIRECTORY dpdir TO ADMIN;

-- Bước 2: Export schema ADMIN dùng DBMS_DATAPUMP
DECLARE
  h1 NUMBER;
BEGIN
  h1 := DBMS_DATAPUMP.OPEN(operation => 'EXPORT', job_mode => 'SCHEMA', job_name => 'EXPORT_JOB1', version => 'LATEST');
  DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => 'admin_backup.dmp', directory => 'DPDIR');
  DBMS_DATAPUMP.METADATA_FILTER(handle => h1, name => 'SCHEMA_EXPR', value => '= ''ADMIN''');
  DBMS_DATAPUMP.START_JOB(handle => h1);
  DBMS_DATAPUMP.DETACH(handle => h1);
END;
/

-- Bước 3: Xóa thử bảng để kiểm tra restore
-- DROP TABLE TEST_TABLE;

-- Bước 4: Import schema ADMIN từ file backup (phục hồi)
DECLARE
  h1 NUMBER;
BEGIN
  h1 := DBMS_DATAPUMP.OPEN(operation => 'IMPORT', job_mode => 'SCHEMA', job_name => 'IMPORT_JOB1', version => 'LATEST');
  DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => 'admin_backup.dmp', directory => 'DPDIR');
  DBMS_DATAPUMP.METADATA_REMAP(handle => h1, name => 'REMAP_SCHEMA', old_value => 'ADMIN', value => 'ADMIN');
  DBMS_DATAPUMP.START_JOB(handle => h1);
  DBMS_DATAPUMP.DETACH(handle => h1);
END;
/