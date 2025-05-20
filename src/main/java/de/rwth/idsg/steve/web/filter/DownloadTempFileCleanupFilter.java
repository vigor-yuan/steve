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
package de.rwth.idsg.steve.web.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 过滤器，用于清理文件下载过程中创建的临时文件
 * 当下载请求完成后，会删除临时文件，确保不会占用磁盘空间
 */
@Slf4j
@Component
public class DownloadTempFileCleanupFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        log.debug("DownloadTempFileCleanupFilter processing request: {}", request.getRequestURI());
        
        try {
            // 继续处理请求
            filterChain.doFilter(request, response);
        } finally {
            // 请求处理完成后，检查是否有临时文件需要清理
            String tempFilePath = (String) request.getAttribute("tempFilePath");
            if (tempFilePath != null) {
                try {
                    Path path = Paths.get(tempFilePath);
                    if (Files.exists(path)) {
                        Files.delete(path);
                        log.info("Deleted temporary download file: {}", tempFilePath);
                    }
                } catch (IOException e) {
                    log.warn("Failed to delete temporary download file: {}, error: {}", tempFilePath, e.getMessage());
                }
            } else {
                log.debug("No temporary file to clean up for request: {}", request.getRequestURI());
            }
        }
    }
}
