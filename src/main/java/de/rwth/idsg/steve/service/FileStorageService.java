/*
 * SteVe - SteckdosenVerwaltung - https://github.com/RWTH-i5-IDSG/steve
 * Copyright (C) 2013-2022 RWTH Aachen University - Information Systems - Intelligent Distributed Systems Group (IDSG).
 * All Rights Reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
package de.rwth.idsg.steve.service;

import de.rwth.idsg.steve.web.dto.FileStorageForm;
import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Map;

/**
 * Service interface for file storage operations
 *
 * @author CASCADE AI Assistant
 */
public interface FileStorageService {

    FileStorageRecord storeFile(FileStorageForm form, String description, String username) throws IOException;

    /**
     * Store a file from form
     *
     * @param form The form containing file and description
     * @param username Username of uploader
     * @return The stored file record
     * @throws IOException If file storage fails
     */
    FileStorageRecord storeFile(FileStorageForm form, String username) throws IOException;
    
    /**
     * Store a file from form with overwrite option
     *
     * @param form The form containing file and description
     * @param username Username of uploader
     * @param overwrite Whether to overwrite existing file
     * @return The stored file record
     * @throws IOException If file storage fails
     */
    FileStorageRecord storeFile(FileStorageForm form, String username, boolean overwrite) throws IOException;

    /**
     * Load a file as a resource
     *
     * @param id The file ID
     * @return The file resource
     * @throws IOException If file loading fails
     */
    Resource loadFileAsResource(Long id) throws IOException;
    
    /**
     * Update file version
     * 
     * @param id The file ID
     * @param file The new file
     * @param description The updated description (optional)
     * @param version The new version
     * @param updateNotes Update notes
     */
    void updateFileVersion(Long id, MultipartFile file, String description, String version, String updateNotes);

    /**
     * Load a file as a resource
     *
     * @param fileName The file name
     * @return The file resource
     * @throws IOException If file loading fails
     */
    Resource loadFileAsResource(String fileName) throws IOException;
    
    /**
     * Get the original filename of a file
     *
     * @param id The file ID
     * @return The original filename
     */
    String getOriginalFilename(Long id);

    /**
     * Load a file description as a resource
     *
     * @param id The file ID
     * @return The file description resource
     * @throws IOException If file loading fails
     */
    Resource loadFileDescriptionAsResource(Long id) throws IOException;

    /**
     * Get all file records
     *
     * @return List of all file records
     */
    List<FileStorageRecord> getAll();
    
    /**
     * Get all file records with pagination
     *
     * @param offset The offset to start from
     * @param limit The maximum number of records to return
     * @return List of file records
     */
    List<FileStorageRecord> getAll(int offset, int limit);

    /**
     * Get file record by ID
     *
     * @param id The file ID
     * @return The file record
     */
    FileStorageRecord getById(Long id);
    
    /**
     * Get file record by original file name
     *
     * @param originalName The original file name
     * @return The file record or null if not found
     */
    FileStorageRecord getByOriginalName(String originalName);
    
    /**
     * Check if a file with the given original name exists
     *
     * @param originalName The original file name
     * @return true if file exists
     */
    boolean fileExists(String originalName);

    /**
     * Delete a file
     *
     * @param id The file ID
     * @return true if deletion successful
     */
    boolean deleteFile(Long id);

    /**
     * Check if file type is allowed
     *
     * @param filename The filename to check
     * @return true if file type is allowed
     */
    boolean isFileTypeAllowed(String filename);
    
    /**
     * Get allowed file types as a comma-separated string
     *
     * @return Allowed file types
     */
    String getAllowedFileTypes();
    
    /**
     * Calculate MD5 hash of a file
     *
     * @param inputStream The input stream of the file
     * @return MD5 hash of the file
     * @throws IOException If MD5 calculation fails
     */
    String calculateMD5(InputStream inputStream) throws IOException;
    
    /**
     * Generate description file for a file
     *
     * @param record The file record
     * @param updateContent The update content
     * @throws IOException If description file generation fails
     */
    void generateDescriptionFile(FileStorageRecord record, String updateContent) throws IOException;
    
    /**
     * Increment download count for a file
     *
     * @param id The file ID
     * @return The updated file record
     */
    FileStorageRecord incrementDownloadCount(Long id);
    
    /**
     * Update the disabled status of a file
     *
     * @param id The file ID
     * @param disabled The new disabled status
     * @return The updated file record
     */
    FileStorageRecord updateDisabledStatus(Long id, boolean disabled);
    
    /**
     * Update the maximum downloads for a file
     *
     * @param id The file ID
     * @param maxDownloads The new maximum downloads
     * @return The updated file record
     */
    FileStorageRecord updateMaxDownloads(Long id, int maxDownloads);
    
    /**
     * Get total count of files
     *
     * @return Total count of files
     */
    int getTotalCount();
    
    /**
     * Update file version
     *
     * @param id The file ID
     * @param file The new file
     * @param version The new version
     * @param updateNotes Update notes
     */
    void updateFileVersion(Long id, MultipartFile file, String version, String updateNotes);
    
    /**
     * Toggle file status (enabled/disabled)
     *
     * @param id The file ID
     * @param disabled Whether the file should be disabled
     */
    void toggleFileStatus(Long id, boolean disabled);
}
