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
package de.rwth.idsg.steve.web.controller;

import de.rwth.idsg.steve.service.FileStorageService;
import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpRange;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

/**
 * 专门用于匿名文件下载的控制器
 * 这个控制器不需要身份验证即可访问
 */
@Slf4j
@Controller
@RequestMapping("/files")
public class AnonymousFileDownloadController {

    @Autowired
    private FileStorageService fileStorageService;

    /**
     * 通过文件名匿名下载文件
     * 支持GET和HEAD请求
     * GET请求返回完整文件内容
     * HEAD请求只返回文件元数据，不返回文件内容
     */
    @RequestMapping(value = "/download/name/{fileName}", method = {RequestMethod.GET, RequestMethod.HEAD})
    public ResponseEntity<Resource> downloadFileByName(@PathVariable String fileName, HttpServletRequest request) {
        try {
            log.info("Anonymous download attempt for file with name: {}", fileName);
            
            // 获取文件记录
            FileStorageRecord record = fileStorageService.getByOriginalName(fileName);
            if (record == null) {
                log.error("File record not found for name: {}", fileName);
                return ResponseEntity.notFound().build();
            }
            
            // 检查文件是否已禁用
            if (record.getDisabled()) {
                log.warn("Attempted to download disabled file with name: {}", fileName);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            
            // 检查下载次数是否达到上限
            if (record.getMaxDownloads() > 0 && record.getDownloadCount() >= record.getMaxDownloads()) {
                log.warn("Download limit reached for file with name: {}, max={}, current={}", 
                         fileName, record.getMaxDownloads(), record.getDownloadCount());
                
                // 自动禁用文件
                fileStorageService.toggleFileStatus(record.getId(), true);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            
            log.info("Found file record: fileName={}, originalName={}, filePath={}", 
                     record.getFileName(), record.getOriginalName(), record.getFilePath());
            
            // 创建一个临时文件副本，确保下载不会被文件更新或删除影响
            Path filePath = Paths.get(record.getFilePath());
            Path tempFilePath = null;
            Resource resource = null;
            
            try {
                // 检查原始文件是否存在可读
                if (!Files.exists(filePath) || !Files.isReadable(filePath)) {
                    log.error("Original file not found or not readable: {}", filePath);
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
                }
                
                // 创建临时文件副本，使用原始文件名加时间戳作为临时文件名
                String tempFileName = record.getFileName() + "-" + System.currentTimeMillis();
                tempFilePath = Files.createTempFile("download-", "-" + tempFileName);
                
                // 复制原始文件到临时文件
                Files.copy(filePath, tempFilePath, StandardCopyOption.REPLACE_EXISTING);
                
                // 从临时文件创建资源
                resource = new UrlResource(tempFilePath.toUri());
                
                // 添加文件删除钩子，在响应完成后删除临时文件
                request.setAttribute("tempFilePath", tempFilePath.toString());
                
                log.info("Created temporary file copy for anonymous download: original={}, temp={}, size={}", 
                         filePath, tempFilePath, resource.contentLength());
            } catch (IOException e) {
                log.error("Failed to create temporary file for download: {}", e.getMessage());
                // 如果创建临时文件失败，尝试直接使用原始文件
                log.warn("Falling back to direct file access for: {}", filePath);
                resource = new UrlResource(filePath.toUri());
                
                if (!resource.exists() || !resource.isReadable()) {
                    log.error("File not found or not readable: {}", filePath);
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
                }
            }
            
            // 只有在实际下载文件时才增加下载计数
            // 排除预加载、HEAD请求和Range请求
            if ("GET".equalsIgnoreCase(request.getMethod()) && request.getHeader("Range") == null) {
                fileStorageService.incrementDownloadCount(record.getId());
            }
            
            // 记录匿名下载日志
            String remoteIp = request.getRemoteAddr();
            log.info("Anonymous download: file={}, ip={}", record.getOriginalName(), remoteIp);
            
            // 获取文件的原始名称
            String originalFilename = record.getOriginalName();
            log.info("Original filename: {}", originalFilename);
            
            // 确定内容类型
            String contentType = record.getContentType() != null ? 
                                record.getContentType() : "application/octet-stream";
            
            // 返回文件下载响应
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + originalFilename + "\"")
                    .body(resource);
        } catch (IOException ex) {
            log.error("文件下载失败: {}", ex.getMessage(), ex);
            return ResponseEntity.status(org.springframework.http.HttpStatus.NOT_FOUND).body(null);
        } catch (Exception ex) {
            log.error("下载过程中发生未知错误: {}", ex.getMessage(), ex);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    /**
     * 通过文件名匿名下载描述文件
     * 支持GET和HEAD请求
     * GET请求返回完整描述文件内容
     * HEAD请求只返回描述文件元数据，不返回文件内容
     */
    @RequestMapping(value = "/download-description/name/{fileName}", method = {RequestMethod.GET, RequestMethod.HEAD})
    public ResponseEntity<Resource> downloadFileDescriptionByName(@PathVariable String fileName, HttpServletRequest request) {
        log.info("Anonymous download attempt for description file with name: {}", fileName);
        
        // 获取文件记录
        FileStorageRecord record = fileStorageService.getByOriginalName(fileName);
        if (record == null) {
            log.error("File record not found for name: {}", fileName);
            return ResponseEntity.notFound().build();
        }
        
        // 检查文件是否已禁用
        if (record.getDisabled()) {
            log.warn("Attempted to download description for disabled file with name: {}", fileName);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        
        // 检查下载次数是否达到上限
        if (record.getMaxDownloads() > 0 && record.getDownloadCount() >= record.getMaxDownloads()) {
            log.warn("Download limit reached for file with name: {}, max={}, current={}", 
                     fileName, record.getMaxDownloads(), record.getDownloadCount());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        
        try {
            // 获取描述文件资源
            Resource originalResource = fileStorageService.loadFileDescriptionAsResource(record.getId());
            if (!originalResource.exists() || !originalResource.isReadable()) {
                log.error("Description file not found or not readable for: {}", fileName);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            
            // 创建临时文件副本，确保下载不会被文件更新或删除影响
            Path tempFilePath = null;
            Resource resource = null;

            try {
                // 创建临时文件
                String tempFileName = "desc-" + fileName + "-" + System.currentTimeMillis() + ".txt";
                tempFilePath = Files.createTempFile("download-desc-", "-" + tempFileName);
                
                // 复制原始描述文件到临时文件
                try (InputStream in = originalResource.getInputStream()) {
                    Files.copy(in, tempFilePath, StandardCopyOption.REPLACE_EXISTING);
                }
                
                // 从临时文件创建资源
                resource = new UrlResource(tempFilePath.toUri());
                
                // 添加文件删除钩子，在响应完成后删除临时文件
                request.setAttribute("tempFilePath", tempFilePath.toString());
                
                log.info("Created temporary file copy for anonymous description download: temp={}, size={}", 
                         tempFilePath, resource.contentLength());
            } catch (IOException e) {
                log.error("Failed to create temporary file for description download: {}", e.getMessage());
                // 如果创建临时文件失败，尝试直接使用原始文件
                log.warn("Falling back to direct file access for description");
                resource = originalResource;
            }
            
            // 记录匿名描述文件下载日志
            String remoteIp = request.getRemoteAddr();
            log.info("Anonymous description file download: file={}, ip={}", fileName, remoteIp);
            
            String descriptionFileName = fileName + ".description.txt";
            
            return ResponseEntity.ok()
                    .contentType(MediaType.TEXT_PLAIN)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + descriptionFileName + "\"")
                    .body(resource);
        } catch (Exception ex) {
            log.error("Error loading description file for: {}, error: {}", fileName, ex.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
