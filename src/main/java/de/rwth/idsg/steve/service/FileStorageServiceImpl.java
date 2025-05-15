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

import de.rwth.idsg.steve.SteveConfiguration;
import de.rwth.idsg.steve.SteveException;
import de.rwth.idsg.steve.repository.FileStorageRepository;
import de.rwth.idsg.steve.web.dto.FileStorageForm;
import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FilenameUtils;
import org.joda.time.DateTime;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * Implementation of the FileStorageService interface
 *
 * @author CASCADE AI Assistant
 */
@Slf4j
@Service
public class FileStorageServiceImpl implements FileStorageService {

    private final Path fileStorageLocation;
    private final List<String> allowedFileTypes;
    private final long maxFileSize;

    private final FileStorageRepository fileStorageRepository;

    @Autowired
    public FileStorageServiceImpl(FileStorageRepository fileStorageRepository) {
        this.fileStorageRepository = fileStorageRepository;
        
        // Get configuration from properties
        String uploadDir = SteveConfiguration.CONFIG.getFileUploadDir();
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        this.allowedFileTypes = Arrays.asList(
                SteveConfiguration.CONFIG.getFileUploadAllowedTypes().split(","));
        
        this.maxFileSize = SteveConfiguration.CONFIG.getFileUploadMaxSize();
        
        log.info("File storage service initialized with upload directory: {}", fileStorageLocation);
        log.info("Allowed file types: {}", allowedFileTypes);
        log.info("Max file size: {} bytes", maxFileSize);
    }

    @PostConstruct
    public void init() {
        try {
            Files.createDirectories(fileStorageLocation);
            log.info("Created file storage directory: {}", fileStorageLocation);
        } catch (IOException ex) {
            throw new SteveException("Could not create the directory where the uploaded files will be stored", ex);
        }
    }

    @Override
    public FileStorageRecord storeFile(MultipartFile file, String description, String username) throws IOException {
        // Check if file is empty
        if (file.isEmpty()) {
            throw new SteveException("Failed to store empty file");
        }
        
        // Check file size
        if (file.getSize() > maxFileSize) {
            throw new SteveException("File size exceeds maximum allowed size of " + maxFileSize + " bytes");
        }
        
        // Check file type
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
        if (!isFileTypeAllowed(originalFilename)) {
            throw new SteveException("File type not allowed. Allowed types: " + String.join(", ", allowedFileTypes));
        }
        
        // Generate a unique file name to prevent conflicts
        String extension = FilenameUtils.getExtension(originalFilename);
        String newFilename = UUID.randomUUID().toString() + "." + extension;
        
        // Copy file to the target location
        Path targetLocation = this.fileStorageLocation.resolve(newFilename);
        Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
        
        // Save file metadata to database
        FileStorageRecord record = FileStorageRecord.builder()
                .fileName(newFilename)
                .originalName(originalFilename)
                .fileSize(file.getSize())
                .contentType(file.getContentType())
                .uploadTime(DateTime.now())
                .uploadBy(username)
                .filePath(targetLocation.toString())
                .description(description)
                .build();
        
        return fileStorageRepository.save(record);
    }

    @Override
    public FileStorageRecord storeFile(FileStorageForm form, String username) throws IOException {
        return storeFile(form.getFile(), form.getDescription(), username);
    }

    @Override
    public Resource loadFileAsResource(Long id) throws IOException {
        try {
            FileStorageRecord record = fileStorageRepository.getById(id);
            if (record == null) {
                throw new SteveException("File not found with id: " + id);
            }
            
            Path filePath = Paths.get(record.getFilePath());
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists()) {
                return resource;
            } else {
                throw new SteveException("File not found: " + record.getFileName());
            }
        } catch (MalformedURLException ex) {
            throw new SteveException("File not found", ex);
        }
    }

    @Override
    public List<FileStorageRecord> getAll() {
        return fileStorageRepository.getAll();
    }

    @Override
    public FileStorageRecord getById(Long id) {
        return fileStorageRepository.getById(id);
    }

    @Override
    public boolean deleteFile(Long id) {
        FileStorageRecord record = fileStorageRepository.getById(id);
        if (record == null) {
            return false;
        }
        
        // Delete file from filesystem
        try {
            File file = new File(record.getFilePath());
            if (file.exists() && file.delete()) {
                // Delete record from database
                return fileStorageRepository.delete(id);
            } else {
                log.warn("Could not delete file: {}", record.getFilePath());
                return false;
            }
        } catch (Exception e) {
            log.error("Error deleting file", e);
            return false;
        }
    }

    @Override
    public boolean isFileTypeAllowed(String filename) {
        String extension = FilenameUtils.getExtension(filename).toLowerCase();
        return allowedFileTypes.contains(extension);
    }
    
    @Override
    public String getAllowedFileTypes() {
        return String.join(", ", allowedFileTypes);
    }
}
