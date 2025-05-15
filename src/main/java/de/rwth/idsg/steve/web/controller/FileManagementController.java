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
import org.springframework.http.HttpHeaders;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.util.List;

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
            fileStorageService.storeFile(form, principal.getName());
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
                           @RequestParam("version") String version,
                           @RequestParam("updateNotes") String updateNotes,
                           RedirectAttributes redirectAttributes,
                           java.security.Principal principal) {
        try {
            fileStorageService.updateFileVersion(id, file, version, updateNotes);
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

    @GetMapping("/download/{id}")
    public ResponseEntity<Resource> downloadFile(@PathVariable Long id) {
        try {
            // 获取文件资源
            Resource resource = fileStorageService.loadFileAsResource(id);
            
            // 获取文件的原始名称
            String originalFilename = fileStorageService.getOriginalFilename(id);
            
            // 确定内容类型
            String contentType = "application/octet-stream";
            
            // 返回文件下载响应
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + originalFilename + "\"")
                    .body(resource);
        } catch (IOException ex) {
            log.error("文件下载失败", ex);
            return ResponseEntity.status(org.springframework.http.HttpStatus.NOT_FOUND).body(null);
        }
    }

    @GetMapping("/download-description/{id}")
    public ResponseEntity<Resource> downloadFileDescription(@PathVariable Long id) throws IOException {
        Resource resource = fileStorageService.loadFileDescriptionAsResource(id);
        FileStorageRecord fileRecord = fileStorageService.getById(id);
        
        String descriptionFileName = fileRecord.getOriginalName() + ".description.txt";

        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_PLAIN)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + descriptionFileName + "\"")
                .body(resource);
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
