-- Add unique constraint to original_name in file_storage table
ALTER TABLE file_storage 
    DROP INDEX idx_file_storage_name,
    ADD UNIQUE INDEX unq_file_storage_original_name (original_name);
