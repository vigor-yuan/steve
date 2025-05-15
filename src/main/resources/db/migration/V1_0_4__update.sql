-- Add file storage table for file upload/download feature

CREATE TABLE file_storage (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL COMMENT 'Stored file name on server',
    original_name VARCHAR(255) NOT NULL COMMENT 'Original file name',
    file_size BIGINT NOT NULL COMMENT 'File size in bytes',
    content_type VARCHAR(100) COMMENT 'MIME type of the file',
    upload_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Upload timestamp',
    upload_by VARCHAR(100) COMMENT 'Username who uploaded the file',
    file_path VARCHAR(500) NOT NULL COMMENT 'Path to the file on server',
    description TEXT COMMENT 'Optional file description'
) COMMENT 'Table for storing file metadata for upload/download feature';

-- Add index for faster search
CREATE INDEX idx_file_storage_name ON file_storage(original_name);
CREATE INDEX idx_file_storage_upload_time ON file_storage(upload_time);
