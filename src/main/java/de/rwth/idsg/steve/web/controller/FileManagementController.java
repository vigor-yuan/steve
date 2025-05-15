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
    public String uploadFile(@ModelAttribute("fileForm") FileStorageForm fileForm,
                             Authentication authentication,
                             RedirectAttributes redirectAttributes) {
        try {
            String username = authentication.getName();
            FileStorageRecord storedFile = fileStorageService.storeFile(fileForm, username);
            redirectAttributes.addFlashAttribute("success", "File uploaded successfully: " + storedFile.getOriginalName());
        } catch (IOException e) {
            log.error("Error uploading file", e);
            redirectAttributes.addFlashAttribute("error", "Failed to upload file: " + e.getMessage());
        }
        return "redirect:/manager/files";
    }

    @GetMapping("/download/{id}")
    public ResponseEntity<Resource> downloadFile(@PathVariable Long id, HttpServletRequest request) throws IOException {
        Resource resource = fileStorageService.loadFileAsResource(id);
        FileStorageRecord fileRecord = fileStorageService.getById(id);

        // Try to determine file's content type
        String contentType = fileRecord.getContentType();
        if (contentType == null) {
            contentType = request.getServletContext().getMimeType(resource.getFile().getAbsolutePath());
        }

        // Fallback to the default content type if type could not be determined
        if (contentType == null) {
            contentType = "application/octet-stream";
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileRecord.getOriginalName() + "\"")
                .body(resource);
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
        boolean deleted = fileStorageService.deleteFile(id);
        return deleted ? "success" : "error";
    }
    
    @PostMapping("/disable/{id}")
    @ResponseBody
    public String disableFile(@PathVariable Long id, @RequestParam boolean disabled) {
        try {
            fileStorageService.updateDisabledStatus(id, disabled);
            return "success";
        } catch (Exception e) {
            log.error("Error updating file disabled status", e);
            return "error";
        }
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
