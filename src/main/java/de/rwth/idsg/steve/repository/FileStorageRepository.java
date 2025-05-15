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
}
