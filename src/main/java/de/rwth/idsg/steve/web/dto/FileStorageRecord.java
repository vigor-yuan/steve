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
package de.rwth.idsg.steve.web.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.joda.time.DateTime;

/**
 * DTO for file storage records
 *
 * @author CASCADE AI Assistant
 */
@Getter
@Setter
@Builder
public class FileStorageRecord {
    private Long id;
    private String fileName;
    private String originalName;
    private Long fileSize;
    private String contentType;
    private DateTime uploadTime;
    private String uploadBy;
    private String filePath;
    private String description;
    private String md5Hash;
    private Integer downloadCount;
    private Integer maxDownloads;
    private Boolean disabled;
    private DateTime modifyDate;
    private String version;
    private String updateNotes;
    private DateTime lastUpdated;
    private String downloadUrl;
    
    /**
     * Check if download is allowed based on max downloads
     * 
     * @return true if download is allowed, false otherwise
     */
    public boolean isDownloadAllowed() {
        if (disabled != null && disabled) {
            return false;
        }
        
        if (maxDownloads == null || maxDownloads == 0) {
            return true; // unlimited downloads
        }
        
        return downloadCount < maxDownloads;
    }
    
    /**
     * Get remaining downloads
     * 
     * @return remaining downloads or -1 if unlimited
     */
    public int getRemainingDownloads() {
        if (maxDownloads == null || maxDownloads == 0) {
            return -1; // unlimited downloads
        }
        
        return Math.max(0, maxDownloads - downloadCount);
    }
}
