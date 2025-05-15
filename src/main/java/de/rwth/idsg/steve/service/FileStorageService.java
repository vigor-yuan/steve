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

import java.io.IOException;
import java.util.List;

/**
 * Service interface for file storage operations
 *
 * @author CASCADE AI Assistant
 */
public interface FileStorageService {

    /**
     * Store a file
     *
     * @param file The file to store
     * @param description Optional description
     * @param username Username of uploader
     * @return The stored file record
     * @throws IOException If file storage fails
     */
    FileStorageRecord storeFile(MultipartFile file, String description, String username) throws IOException;

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
     * Load a file as a resource
     *
     * @param id The file ID
     * @return The file resource
     * @throws IOException If file loading fails
     */
    Resource loadFileAsResource(Long id) throws IOException;

    /**
     * Get all file records
     *
     * @return List of all file records
     */
    List<FileStorageRecord> getAll();

    /**
     * Get file record by ID
     *
     * @param id The file ID
     * @return The file record
     */
    FileStorageRecord getById(Long id);

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
}
