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
package de.rwth.idsg.steve.utils;

import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 文件下载日志记录工具类
 * 用于记录文件下载的详细信息
 */
@Component
public class FileDownloadLogger {

    private static final Logger log = LogManager.getLogger("file-download-logger");
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 记录文件下载信息
     *
     * @param record 下载的文件记录
     * @param user 下载用户
     * @param remoteIp 用户IP地址
     */
    public void logDownload(FileStorageRecord record, Principal user, String remoteIp) {
        if (record == null) {
            return;
        }

        String username = (user != null) ? user.getName() : "anonymous";
        String timestamp = LocalDateTime.now().format(formatter);
        
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(timestamp).append("] ");
        sb.append("用户: ").append(username).append(", ");
        sb.append("IP: ").append(remoteIp).append(", ");
        sb.append("文件ID: ").append(record.getId()).append(", ");
        sb.append("文件名: ").append(record.getOriginalName()).append(", ");
        sb.append("版本: ").append(record.getVersion() != null ? record.getVersion() : "1.0").append(", ");
        sb.append("文件大小: ").append(formatFileSize(record.getFileSize())).append(", ");
        sb.append("下载次数: ").append(record.getDownloadCount() + 1);
        
        log.info(sb.toString());
    }
    
    /**
     * 格式化文件大小
     */
    private String formatFileSize(long size) {
        final String[] units = new String[] { "B", "KB", "MB", "GB", "TB" };
        int digitGroups = (int) (Math.log10(size) / Math.log10(1024));
        return String.format("%.1f %s", size / Math.pow(1024, digitGroups), units[digitGroups]);
    }
}
