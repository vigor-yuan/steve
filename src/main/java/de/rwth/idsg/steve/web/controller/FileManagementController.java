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
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

/**
 * Controller for file upload and download operations
 *
 * @author CASCADE AI Assistant
 */
@Slf4j
@Controller
@RequestMapping(value = "/manager/files")
public class FileManagementController {

    @Autowired private FileStorageService fileStorageService;

    private static final String UPLOAD_PATH = "/upload";
    private static final String LIST_PATH = "";
    private static final String DOWNLOAD_PATH = "/download/{id}";
    private static final String DELETE_PATH = "/delete/{id}";

    @RequestMapping(value = LIST_PATH, method = RequestMethod.GET)
    public String getFileList(Model model) {
        model.addAttribute("fileList", fileStorageService.getAll());
        model.addAttribute("fileForm", new FileStorageForm());
        return "files";
    }

    @RequestMapping(value = UPLOAD_PATH, method = RequestMethod.POST)
    public String handleFileUpload(@ModelAttribute("fileForm") FileStorageForm form,
                                   Authentication authentication,
                                   RedirectAttributes redirectAttributes) {
        try {
            if (form.getFile() == null || form.getFile().isEmpty()) {
                redirectAttributes.addFlashAttribute("errorMessage", "Please select a file to upload");
                return "redirect:/manager/files";
            }

            // Check file type
            if (!fileStorageService.isFileTypeAllowed(form.getFile().getOriginalFilename())) {
                redirectAttributes.addFlashAttribute("errorMessage", 
                        "File type not allowed. Allowed types: " + 
                        fileStorageService.getAllowedFileTypes());
                return "redirect:/manager/files";
            }

            String username = authentication.getName();
            FileStorageRecord record = fileStorageService.storeFile(form, username);
            
            redirectAttributes.addFlashAttribute("successMessage", 
                    "File uploaded successfully: " + record.getOriginalName());
            
        } catch (IOException e) {
            log.error("Error uploading file", e);
            redirectAttributes.addFlashAttribute("errorMessage", "Failed to upload file: " + e.getMessage());
        }
        
        return "redirect:/manager/files";
    }

    @RequestMapping(value = DOWNLOAD_PATH, method = RequestMethod.GET)
    @ResponseBody
    public ResponseEntity<Resource> downloadFile(@PathVariable Long id, HttpServletRequest request) {
        try {
            // Load file as Resource
            Resource resource = fileStorageService.loadFileAsResource(id);
            FileStorageRecord record = fileStorageService.getById(id);

            // Try to determine file's content type
            String contentType = record.getContentType();
            if (contentType == null) {
                contentType = request.getServletContext().getMimeType(resource.getFile().getAbsolutePath());
            }
            if (contentType == null) {
                contentType = "application/octet-stream";
            }

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + record.getOriginalName() + "\"")
                    .body(resource);
                    
        } catch (IOException ex) {
            log.error("Error downloading file", ex);
            return ResponseEntity.notFound().build();
        }
    }

    @RequestMapping(value = DELETE_PATH, method = RequestMethod.POST)
    public String deleteFile(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        try {
            if (fileStorageService.deleteFile(id)) {
                redirectAttributes.addFlashAttribute("successMessage", "File deleted successfully");
            } else {
                redirectAttributes.addFlashAttribute("errorMessage", "Failed to delete file");
            }
        } catch (Exception e) {
            log.error("Error deleting file", e);
            redirectAttributes.addFlashAttribute("errorMessage", "Error deleting file: " + e.getMessage());
        }
        
        return "redirect:/manager/files";
    }
}
