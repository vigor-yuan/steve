-- Add new columns to file_storage table
ALTER TABLE file_storage 
    ADD COLUMN version VARCHAR(50) COMMENT 'Version number of the file',
    ADD COLUMN update_notes TEXT COMMENT 'Update notes for this version',
    ADD COLUMN download_url VARCHAR(500) COMMENT 'Download URL for the file',
    ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update time';

