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
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.io.FilenameUtils;
import org.joda.time.DateTime;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
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
    private final String[] allowedFileTypes;
    private final long maxFileSize;

    private final FileStorageRepository fileStorageRepository;

    @Autowired
    public FileStorageServiceImpl(FileStorageRepository fileStorageRepository) {
        this.fileStorageRepository = fileStorageRepository;
        
        // Get configuration from properties
        String uploadDir = SteveConfiguration.CONFIG.getFileUploadDir();
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        this.allowedFileTypes = SteveConfiguration.CONFIG.getFileUploadAllowedTypes().split(",");
        
        this.maxFileSize = SteveConfiguration.CONFIG.getFileUploadMaxSize();
        
        log.info("File storage service initialized with upload directory: {}", fileStorageLocation);
        log.info("Allowed file types: {}", Arrays.toString(allowedFileTypes));
        log.info("Max file size: {} bytes", maxFileSize);
        
        try {
            Files.createDirectories(fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored.", ex);
        }
    }

    @Override
    public FileStorageRecord storeFile(MultipartFile file, String description, String username) throws IOException {
        // Normalize file name
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());

        // Check if the file's name contains invalid characters
        if (originalFilename.contains("..")) {
            throw new IOException("Filename contains invalid path sequence " + originalFilename);
        }

        // Check if file is empty
        if (file.isEmpty()) {
            throw new SteveException("Failed to store empty file");
        }
        
        // Check file size
        if (file.getSize() > maxFileSize) {
            throw new SteveException("File size exceeds maximum allowed size of " + maxFileSize + " bytes");
        }
        
        // Check file type
        if (!isFileTypeAllowed(originalFilename)) {
            throw new SteveException("File type not allowed. Allowed types: " + String.join(", ", allowedFileTypes));
        }
        
        // Generate a unique filename to prevent conflicts
        String fileExtension = FilenameUtils.getExtension(originalFilename);
        String uniqueFilename = UUID.randomUUID().toString() + "." + fileExtension;

        // Copy file to the target location
        Path targetLocation = this.fileStorageLocation.resolve(uniqueFilename);
        Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
        
        // Calculate MD5 hash
        String md5Hash = calculateMD5(file.getInputStream());

        // Create file record
        FileStorageRecord record = FileStorageRecord.builder()
                .fileName(uniqueFilename)
                .originalName(originalFilename)
                .fileSize(file.getSize())
                .contentType(file.getContentType())
                .uploadTime(DateTime.now())
                .uploadBy(username)
                .filePath(targetLocation.toString())
                .description(description)
                .md5Hash(md5Hash)
                .downloadCount(0)
                .maxDownloads(0) // Default to unlimited
                .disabled(false)
                .build();

        // Save to database
        record = fileStorageRepository.save(record);
        
        // Generate description file
        generateDescriptionFile(record, null);
        
        return record;
    }

    @Override
    public FileStorageRecord storeFile(FileStorageForm form, String username) throws IOException {
        FileStorageRecord record = storeFile(form.getFile(), form.getDescription(), username);
        
        // Update max downloads if specified
        if (form.getMaxDownloads() != null && form.getMaxDownloads() > 0) {
            record = updateMaxDownloads(record.getId(), form.getMaxDownloads());
        }
        
        // Generate description file with update content if provided
        if (form.getUpdateContent() != null && !form.getUpdateContent().isEmpty()) {
            generateDescriptionFile(record, form.getUpdateContent());
        }
        
        return record;
    }

    @Override
    public Resource loadFileAsResource(Long id) throws IOException {
        FileStorageRecord record = fileStorageRepository.getById(id);
        if (record == null) {
            throw new IOException("File not found with id: " + id);
        }
        
        // Check if file is disabled
        if (record.getDisabled()) {
            throw new IOException("File is disabled: " + record.getFileName());
        }
        
        // Check if max downloads reached
        if (record.getMaxDownloads() > 0 && record.getDownloadCount() >= record.getMaxDownloads()) {
            throw new IOException("Maximum download limit reached for file: " + record.getFileName());
        }
        
        return loadFileAsResource(record.getFileName());
    }

    @Override
    public Resource loadFileAsResource(String fileName) throws IOException {
        try {
            Path filePath = this.fileStorageLocation.resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            if(resource.exists()) {
                return resource;
            } else {
                throw new FileNotFoundException("File not found " + fileName);
            }
        } catch (MalformedURLException ex) {
            throw new FileNotFoundException("File not found " + fileName);
        }
    }
    
    @Override
    public String getOriginalFilename(Long id) {
        FileStorageRecord record = fileStorageRepository.getById(id);
        if (record == null) {
            throw new SteveException("File not found with id: " + id);
        }
        return record.getOriginalName();
    }
    
    @Override
    public void updateFileVersion(Long id, MultipartFile file, String version, String updateNotes) {
        try {
            // 检查文件是否存在
            FileStorageRecord record = fileStorageRepository.getById(id);
            if (record == null) {
                throw new SteveException("File not found with id: " + id);
            }
            
            // 保存新文件
            String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
            String fileExtension = getFileExtension(originalFilename);
            String newFileName = UUID.randomUUID().toString() + "." + fileExtension;
            
            // 检查文件类型是否允许
            if (!isFileTypeAllowed(originalFilename)) {
                throw new SteveException("File type not allowed. Allowed types: " + getAllowedFileTypes());
            }
            
            // 保存文件到磁盘
            Path targetLocation = this.fileStorageLocation.resolve(newFileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            
            // 计算MD5哈希值
            String md5Hash = calculateMD5(file.getInputStream());
            
            // 更新数据库记录
            fileStorageRepository.updateFileVersion(id, newFileName, version, updateNotes, md5Hash, file.getSize());
            
            // 删除旧文件
            if (!record.getFileName().equals(newFileName)) {
                Path oldFilePath = this.fileStorageLocation.resolve(record.getFileName()).normalize();
                Files.deleteIfExists(oldFilePath);
            }
            
            // 生成更新后的描述文件
            FileStorageRecord updatedRecord = fileStorageRepository.getById(id);
            generateDescriptionFile(updatedRecord, updateNotes);
            
        } catch (IOException ex) {
            throw new SteveException("Could not update file version", ex);
        }
    }
    
    @Override
    public void toggleFileStatus(Long id, boolean disabled) {
        FileStorageRecord record = fileStorageRepository.getById(id);
        if (record == null) {
            throw new SteveException("File not found with id: " + id);
        }
        fileStorageRepository.updateDisabledStatus(id, disabled);
    }

    @Override
    public Resource loadFileDescriptionAsResource(Long id) throws IOException {
        try {
            FileStorageRecord record = fileStorageRepository.getById(id);
            if (record == null) {
                throw new IOException("File not found with id: " + id);
            }
            
            // Get description file path
            Path descFilePath = getDescriptionFilePath(record);
            Resource resource = new UrlResource(descFilePath.toUri());

            if (resource.exists()) {
                return resource;
            } else {
                throw new IOException("Description file not found for: " + record.getFileName());
            }
        } catch (MalformedURLException ex) {
            throw new IOException("Description file not found", ex);
        }
    }

    @Override
    public List<FileStorageRecord> getAll() {
        return fileStorageRepository.getAll();
    }
    
    @Override
    public List<FileStorageRecord> getAll(int offset, int limit) {
        return fileStorageRepository.getAll(offset, limit);
    }

    @Override
    public FileStorageRecord getById(Long id) {
        return fileStorageRepository.getById(id);
    }

    @Override
    public boolean deleteFile(Long id) {
        FileStorageRecord record = fileStorageRepository.getById(id);
        if (record != null) {
            try {
                // Delete file from filesystem
                Path filePath = Paths.get(record.getFilePath());
                Files.deleteIfExists(filePath);
                
                // Delete description file if exists
                Path descFilePath = getDescriptionFilePath(record);
                Files.deleteIfExists(descFilePath);

                // Delete from database
                return fileStorageRepository.delete(id);
            } catch (IOException e) {
                log.error("Error deleting file", e);
                return false;
            }
        }
        return false;
    }

    @Override
    public boolean isFileTypeAllowed(String filename) {
        String extension = FilenameUtils.getExtension(filename).toLowerCase();
        for (String allowedType : allowedFileTypes) {
            if (allowedType.trim().equalsIgnoreCase(extension)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public String getAllowedFileTypes() {
        return String.join(", ", allowedFileTypes);
    }
    
    @Override
    public String calculateMD5(InputStream inputStream) throws IOException {
        return DigestUtils.md5Hex(inputStream);
    }
    
    @Override
    public void generateDescriptionFile(FileStorageRecord record, String updateContent) throws IOException {
        Path descFilePath = getDescriptionFilePath(record);
        
        try (BufferedWriter writer = Files.newBufferedWriter(descFilePath, StandardCharsets.UTF_8)) {
            // Write file information
            writer.write("File Information\n");
            writer.write("===============\n\n");
            writer.write("Filename: " + record.getOriginalName() + "\n");
            writer.write("Size: " + formatFileSize(record.getFileSize()) + "\n");
            writer.write("Content Type: " + record.getContentType() + "\n");
            writer.write("Upload Time: " + formatDateTime(record.getUploadTime()) + "\n");
            writer.write("Uploaded By: " + record.getUploadBy() + "\n");
            writer.write("MD5 Hash: " + record.getMd5Hash() + "\n");
            
            if (record.getMaxDownloads() > 0) {
                writer.write("Download Limit: " + record.getMaxDownloads() + "\n");
            } else {
                writer.write("Download Limit: Unlimited\n");
            }
            
            writer.write("\nDescription\n");
            writer.write("===========\n\n");
            writer.write(record.getDescription() != null ? record.getDescription() : "No description provided.");
            
            // Add update content if provided
            if (updateContent != null && !updateContent.isEmpty()) {
                writer.write("\n\nUpdate Information\n");
                writer.write("=================\n\n");
                writer.write(updateContent);
            }
        }
    }
    
    @Override
    public FileStorageRecord incrementDownloadCount(Long id) {
        return fileStorageRepository.incrementDownloadCount(id);
    }
    
    @Override
    public FileStorageRecord updateDisabledStatus(Long id, boolean disabled) {
        return fileStorageRepository.updateDisabledStatus(id, disabled);
    }
    
    @Override
    public FileStorageRecord updateMaxDownloads(Long id, int maxDownloads) {
        return fileStorageRepository.updateMaxDownloads(id, maxDownloads);
    }
    
    @Override
    public int getTotalCount() {
        return fileStorageRepository.getTotalCount();
    }

    private String getFileExtension(String filename) {
        if (filename.lastIndexOf(".") != -1 && filename.lastIndexOf(".") != 0) {
            return filename.substring(filename.lastIndexOf(".") + 1);
        } else {
            return "";
        }
    }
    
    private Path getDescriptionFilePath(FileStorageRecord record) {
        String filenameWithoutExt = record.getFileName().substring(0, record.getFileName().lastIndexOf('.'));
        String descFilename = filenameWithoutExt + ".txt";
        return this.fileStorageLocation.resolve(descFilename);
    }
    
    private String formatFileSize(long size) {
        final String[] units = new String[] { "B", "KB", "MB", "GB", "TB" };
        int digitGroups = (int) (Math.log10(size) / Math.log10(1024));
        return String.format("%.1f %s", size / Math.pow(1024, digitGroups), units[digitGroups]);
    }
    
    private String formatDateTime(Date date) {
        if (date == null) {
            return "N/A";
        }
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return sdf.format(date);
    }
    
    private String formatDateTime(DateTime dateTime) {
        if (dateTime == null) {
            return "N/A";
        }
        return dateTime.toString("yyyy-MM-dd HH:mm:ss");
    }
}
