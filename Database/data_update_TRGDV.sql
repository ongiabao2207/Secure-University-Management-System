UPDATE DONVI SET TRGDV = 'NV0001' WHERE MADV = 'CNTT';
UPDATE DONVI SET TRGDV = 'NV0002' WHERE MADV = 'DIENTU';
UPDATE DONVI SET TRGDV = 'NV0003' WHERE MADV = 'HOA';
UPDATE DONVI SET TRGDV = 'NV0004' WHERE MADV = 'LICHSU';
UPDATE DONVI SET TRGDV = 'NV0005' WHERE MADV = 'QUANTRI';
UPDATE DONVI SET TRGDV = 'NV0006' WHERE MADV = 'XAHOI';
UPDATE DONVI SET TRGDV = 'NV0007' WHERE MADV = 'PDT';
UPDATE DONVI SET TRGDV = 'NV0008' WHERE MADV = 'PKT';
UPDATE DONVI SET TRGDV = 'NV0009' WHERE MADV = 'TCHC';
UPDATE DONVI SET TRGDV = 'NV0010' WHERE MADV = 'CTSV';
UPDATE DONVI SET TRGDV = 'NV0011' WHERE MADV = 'MOITRUONG';
UPDATE DONVI SET TRGDV = 'NV0012' WHERE MADV = 'BAOCHI';
UPDATE DONVI SET TRGDV = 'NV0013' WHERE MADV = 'TC-KT';
UPDATE DONVI SET TRGDV = 'NV0014' WHERE MADV = 'GIAODUC';
UPDATE DONVI SET TRGDV = 'NV0015' WHERE MADV = 'VATLY';
COMMIT;

/*ALTER TABLE DONVI DISABLE CONSTRAINT FK_TRGDV;
DELETE FROM DANGKY;
DELETE FROM MOMON;
DELETE FROM HOCPHAN;
DELETE FROM SINHVIEN;
DELETE FROM NHANVIEN;
DELETE FROM DONVI;
ALTER TABLE DONVI ENABLE CONSTRAINT FK_TRGDV;
*/

