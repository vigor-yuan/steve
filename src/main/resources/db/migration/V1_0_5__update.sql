-- Add MD5 and download count fields to file_storage table

ALTER TABLE file_storage 
ADD COLUMN md5_hash VARCHAR(32) COMMENT 'MD5 hash of the file',
ADD COLUMN download_count INT DEFAULT 0 COMMENT 'Number of times the file has been downloaded',
ADD COLUMN max_downloads INT DEFAULT 0 COMMENT 'Maximum allowed downloads (0 = unlimited)',
ADD COLUMN disabled BOOLEAN DEFAULT FALSE COMMENT 'Whether the file is disabled',
ADD COLUMN modify_date TIMESTAMP NULL COMMENT 'File modification date';

-- Add index for faster search by MD5
CREATE INDEX idx_file_storage_md5 ON file_storage(md5_hash);
