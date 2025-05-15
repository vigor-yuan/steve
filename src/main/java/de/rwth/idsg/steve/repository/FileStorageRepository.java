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
package de.rwth.idsg.steve.repository;

import de.rwth.idsg.steve.web.dto.FileStorageRecord;

import java.util.List;

/**
 * Repository interface for file storage operations
 *
 * @author CASCADE AI Assistant
 */
public interface FileStorageRepository {

    /**
     * Save a file record to database
     *
     * @param record The file record to save
     * @return The saved file record with ID
     */
    FileStorageRecord save(FileStorageRecord record);

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
     * @return The file record or null if not found
     */
    FileStorageRecord getById(Long id);

    /**
     * Delete a file record
     *
     * @param id The file ID
     * @return true if deletion successful
     */
    boolean delete(Long id);
    
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
     * Get file name by ID
     *
     * @param id The file ID
     * @return The file name
     */
    String getFileName(Long id);
    
    /**
     * Update file version
     *
     * @param id The file ID
     * @param fileName The new file name
     * @param version The new version
     * @param updateNotes The update notes
     * @param md5Hash The new MD5 hash
     * @param fileSize The new file size
     * @return The updated file record
     */
    FileStorageRecord updateFileVersion(Long id, String fileName, String version, String updateNotes, String md5Hash, long fileSize);
    
    /**
     * Update file info
     *
     * @param id The file ID
     * @param description The new description
     * @param version The new version
     * @return The updated file record
     */
    FileStorageRecord updateFileInfo(Long id, String description, String version);
}
