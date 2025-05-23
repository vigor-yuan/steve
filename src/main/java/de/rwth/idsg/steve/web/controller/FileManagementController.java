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
import de.rwth.idsg.steve.web.dto.FileStorageForm;
import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.Principal;
import java.util.List;

import de.rwth.idsg.steve.utils.FileDownloadLogger;

/**
 * Controller for file management
 *
 * @author CASCADE AI Assistant
 */
@Slf4j
@Controller
@RequestMapping("/manager/files")
public class FileManagementController {

    private static final int DEFAULT_PAGE_SIZE = 10;

    @Autowired private FileStorageService fileStorageService;
    @Autowired private FileDownloadLogger fileDownloadLogger;

    @GetMapping
    public String getFiles(Model model, 
                          @RequestParam(value = "page", defaultValue = "1") int page,
                          @RequestParam(value = "size", defaultValue = "10") int size) {
        // Validate page and size parameters
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = DEFAULT_PAGE_SIZE;
        
        int offset = (page - 1) * size;
        
        List<FileStorageRecord> files = fileStorageService.getAll(offset, size);
        int totalFiles = fileStorageService.getTotalCount();
        int totalPages = (int) Math.ceil((double) totalFiles / size);
        
        model.addAttribute("files", files);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", totalPages);
        model.addAttribute("pageSize", size);
        model.addAttribute("fileForm", new FileStorageForm());
        model.addAttribute("allowedFileTypes", fileStorageService.getAllowedFileTypes());
        return "files";
    }

    @PostMapping("/upload")
    public String uploadFile(@ModelAttribute("fileForm") FileStorageForm form,
                             org.springframework.validation.BindingResult result,
                             RedirectAttributes redirectAttributes,
                             java.security.Principal principal) {
        if (result.hasErrors()) {
            return "redirect:/manager/files";
        }
        
        try {
            // 检查 principal 是否为 null，如果为 null 则使用默认用户名
            String username = (principal != null) ? principal.getName() : "anonymous";
            
            // 检查文件是否已存在
            String originalFilename = form.getFile().getOriginalFilename();
            boolean fileExists = fileStorageService.fileExists(originalFilename);
            
            if (fileExists) {
                // 文件已存在，提示用户使用更新按钮
                FileStorageRecord existingFile = fileStorageService.getByOriginalName(originalFilename);
                redirectAttributes.addFlashAttribute("error", "文件 '" + originalFilename + "' 已存在。请使用更新按钮上传新版本。");
                return "redirect:/manager/files";
            }
            
            // 存储文件
            fileStorageService.storeFile(form, username);
            redirectAttributes.addFlashAttribute("success", "文件上传成功");
        } catch (Exception e) {
            log.error("文件上传失败", e);
            redirectAttributes.addFlashAttribute("error", "文件上传失败: " + e.getMessage());
        }
        
        return "redirect:/manager/files";
    }
    
    /**
     * 更新文件版本
     */
    @PostMapping("/update")
    public String updateFile(@RequestParam("id") Long id,
                           @RequestParam("file") MultipartFile file,
                           @RequestParam(value = "description", required = false) String description,
                           @RequestParam("version") String version,
                           @RequestParam("updateNotes") String updateNotes,
                           RedirectAttributes redirectAttributes,
                           java.security.Principal principal) {
        try {
            fileStorageService.updateFileVersion(id, file, description, version, updateNotes);
            redirectAttributes.addFlashAttribute("success", "文件版本更新成功");
        } catch (Exception e) {
            log.error("文件版本更新失败", e);
            redirectAttributes.addFlashAttribute("error", "文件版本更新失败: " + e.getMessage());
        }
        
        return "redirect:/manager/files";
    }
    
    /**
     * 切换文件禁用状态
     */
    @PostMapping("/disable/{id}")
    @ResponseBody
    public String toggleFileStatus(@PathVariable Long id, @RequestParam boolean disabled) {
        try {
            fileStorageService.toggleFileStatus(id, disabled);
            return "success";
        } catch (Exception e) {
            log.error("切换文件状态失败", e);
            return "error: " + e.getMessage();
        }
    }
    
    /**
     * 获取文件下载URL
     */
    @GetMapping("/url/{id}")
    @ResponseBody
    public String getDownloadUrl(@PathVariable Long id, HttpServletRequest request) {
        try {
            String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
            return baseUrl + request.getContextPath() + "/manager/files/download/" + id;
        } catch (Exception e) {
            log.error("获取下载URL失败", e);
            return "error: " + e.getMessage();
        }
    }

    
    /**
     * 通过文件名下载文件
     */
    @GetMapping({"download/name/{fileName}", "/download/name/{fileName}"})
    public ResponseEntity<Resource> downloadFileByName(@PathVariable String fileName, Principal principal, HttpServletRequest request) {
        try {
            log.info("Attempting to download file with name: {}", fileName);
            
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
                
                log.info("Created temporary file copy for download: original={}, temp={}, size={}", 
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
            
            // 更新下载计数
            fileStorageService.incrementDownloadCount(record.getId());
            
            // 记录文件下载日志 - 处理匿名用户
            String remoteIp = request.getRemoteAddr();
            String username = (principal != null) ? principal.getName() : "anonymous";
            log.info("File download by user: {}, IP: {}, file: {}", username, remoteIp, fileName);
            
            // 如果是已登录用户，记录详细日志
            if (principal != null) {
                fileDownloadLogger.logDownload(record, principal, remoteIp);
            } else {
                // 匿名用户下载日志
                log.info("Anonymous download: file={}, ip={}", record.getOriginalName(), remoteIp);
            }
            
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
     * 通过文件ID下载描述文件 - 已废弃，请使用文件名下载
     */
    @Deprecated
    @GetMapping("/download-description/{id}")
    public ResponseEntity<Resource> downloadFileDescription(@PathVariable Long id) throws IOException {
        log.warn("请使用文件名下载描述功能替代ID下载描述功能");
        
        // 获取文件记录
        FileStorageRecord record = fileStorageService.getById(id);
        if (record == null) {
            throw new IOException("File not found with id: " + id);
        }
        
        // 重定向到文件名下载描述接口
        String redirectUrl = "/manager/files/download-description/name/" + record.getOriginalName();
        return ResponseEntity.status(HttpStatus.MOVED_PERMANENTLY)
                .header(HttpHeaders.LOCATION, redirectUrl)
                .build();
    }
    
    /**
     * 通过文件名下载描述文件
     */
    @GetMapping({"download-description/name/{fileName}", "/download-description/name/{fileName}"})
    public ResponseEntity<Resource> downloadFileDescriptionByName(@PathVariable String fileName, Principal principal, HttpServletRequest request) {
        log.info("Attempting to download description file for file with name: {}", fileName);
        
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
                
                log.info("Created temporary file copy for description download: temp={}, size={}", 
                         tempFilePath, resource.contentLength());
            } catch (IOException e) {
                log.error("Failed to create temporary file for description download: {}", e.getMessage());
                // 如果创建临时文件失败，尝试直接使用原始文件
                log.warn("Falling back to direct file access for description");
                resource = originalResource;
            }
            
            // 记录描述文件下载日志 - 处理匿名用户
            String remoteIp = request.getRemoteAddr();
            String username = (principal != null) ? principal.getName() : "anonymous";
            log.info("Description file download by user: {}, IP: {}, file: {}", username, remoteIp, fileName);
            
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

    @DeleteMapping("/{id}")
    @ResponseBody
    public String deleteFile(@PathVariable Long id) {
        try {
            fileStorageService.deleteFile(id);
            return "success";
        } catch (Exception e) {
            log.error("文件删除失败", e);
            return "error";
        }
    }
    
    /**
     * 处理模拟的DELETE请求，用于支持不能直接发送DELETE请求的客户端
     */
    @PostMapping("/{id}")
    @ResponseBody
    public String deleteFilePost(@PathVariable Long id, @RequestParam(name = "_method", required = false) String method) {
        if ("DELETE".equalsIgnoreCase(method)) {
            return deleteFile(id);
        }
        return "error: Unsupported method";
    }
    
    @PostMapping("/max-downloads/{id}")
    @ResponseBody
    public String updateMaxDownloads(@PathVariable Long id, @RequestParam int maxDownloads) {
        try {
            if (maxDownloads < 0) {
                return "error: Max downloads cannot be negative";
            }
            fileStorageService.updateMaxDownloads(id, maxDownloads);
            return "success";
        } catch (Exception e) {
            log.error("Error updating max downloads", e);
            return "error";
        }
    }

    @ExceptionHandler(IOException.class)
    public ResponseEntity<String> handleIOException(IOException ex) {
        return ResponseEntity.badRequest().body(ex.getMessage());
    }
}
