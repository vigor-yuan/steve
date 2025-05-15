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
package de.rwth.idsg.steve.repository.impl;

import de.rwth.idsg.steve.repository.FileStorageRepository;
import de.rwth.idsg.steve.web.dto.FileStorageRecord;
import lombok.extern.slf4j.Slf4j;
import org.joda.time.DateTime;
import org.jooq.DSLContext;
import org.jooq.Record;
import org.jooq.RecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;

import static jooq.steve.db.tables.FileStorage.FILE_STORAGE;

/**
 * Implementation of FileStorageRepository
 *
 * @author CASCADE AI Assistant
 */
@Slf4j
@Repository
public class FileStorageRepositoryImpl implements FileStorageRepository {

    @Autowired private DSLContext ctx;

    @Override
    public FileStorageRecord save(FileStorageRecord record) {
        // If ID is null, insert new record
        if (record.getId() == null) {
            Record result = ctx.insertInto(FILE_STORAGE)
                    .set(FILE_STORAGE.FILE_NAME, record.getFileName())
                    .set(FILE_STORAGE.ORIGINAL_NAME, record.getOriginalName())
                    .set(FILE_STORAGE.FILE_SIZE, record.getFileSize())
                    .set(FILE_STORAGE.CONTENT_TYPE, record.getContentType())
                    .set(FILE_STORAGE.UPLOAD_TIME, record.getUploadTime())
                    .set(FILE_STORAGE.UPLOAD_BY, record.getUploadBy())
                    .set(FILE_STORAGE.FILE_PATH, record.getFilePath())
                    .set(FILE_STORAGE.DESCRIPTION, record.getDescription())
                    .set(FILE_STORAGE.MD5_HASH, record.getMd5Hash())
                    .set(FILE_STORAGE.DOWNLOAD_COUNT, record.getDownloadCount())
                    .set(FILE_STORAGE.MAX_DOWNLOADS, record.getMaxDownloads())
                    .set(FILE_STORAGE.DISABLED, record.getDisabled())
                    .set(FILE_STORAGE.MODIFY_DATE, record.getModifyDate() != null ? record.getModifyDate() : null)
                    .returning(FILE_STORAGE.ID)
                    .fetchOne();

            record.setId(result.getValue(FILE_STORAGE.ID));
            return record;
        } else {
            // Update existing record
            ctx.update(FILE_STORAGE)
                    .set(FILE_STORAGE.FILE_NAME, record.getFileName())
                    .set(FILE_STORAGE.ORIGINAL_NAME, record.getOriginalName())
                    .set(FILE_STORAGE.FILE_SIZE, record.getFileSize())
                    .set(FILE_STORAGE.CONTENT_TYPE, record.getContentType())
                    .set(FILE_STORAGE.UPLOAD_TIME, record.getUploadTime())
                    .set(FILE_STORAGE.UPLOAD_BY, record.getUploadBy())
                    .set(FILE_STORAGE.FILE_PATH, record.getFilePath())
                    .set(FILE_STORAGE.DESCRIPTION, record.getDescription())
                    .set(FILE_STORAGE.MD5_HASH, record.getMd5Hash())
                    .set(FILE_STORAGE.DOWNLOAD_COUNT, record.getDownloadCount())
                    .set(FILE_STORAGE.MAX_DOWNLOADS, record.getMaxDownloads())
                    .set(FILE_STORAGE.DISABLED, record.getDisabled())
                    .set(FILE_STORAGE.MODIFY_DATE, record.getModifyDate() != null ? record.getModifyDate() : null)
                    .where(FILE_STORAGE.ID.eq(record.getId()))
                    .execute();
            
            return record;
        }
    }

    @Override
    public List<FileStorageRecord> getAll() {
        return ctx.selectFrom(FILE_STORAGE)
                .orderBy(FILE_STORAGE.UPLOAD_TIME.desc())
                .fetch(fileRecordMapper);
    }
    
    @Override
    public List<FileStorageRecord> getAll(int offset, int limit) {
        return ctx.selectFrom(FILE_STORAGE)
                .orderBy(FILE_STORAGE.UPLOAD_TIME.desc())
                .limit(limit)
                .offset(offset)
                .fetch(fileRecordMapper);
    }

    @Override
    public FileStorageRecord getById(Long id) {
        return ctx.selectFrom(FILE_STORAGE)
                .where(FILE_STORAGE.ID.eq(id))
                .fetchOne(fileRecordMapper);
    }

    @Override
    public boolean delete(Long id) {
        return ctx.deleteFrom(FILE_STORAGE)
                .where(FILE_STORAGE.ID.eq(id))
                .execute() == 1;
    }
    
    @Override
    public FileStorageRecord incrementDownloadCount(Long id) {
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.DOWNLOAD_COUNT, FILE_STORAGE.DOWNLOAD_COUNT.add(1))
                .where(FILE_STORAGE.ID.eq(id))
                .execute();
        
        // Check if max downloads reached, auto-disable if needed
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.DISABLED, true)
                .where(FILE_STORAGE.ID.eq(id))
                .and(FILE_STORAGE.MAX_DOWNLOADS.gt(0))
                .and(FILE_STORAGE.DOWNLOAD_COUNT.ge(FILE_STORAGE.MAX_DOWNLOADS))
                .execute();
        
        return getById(id);
    }
    
    @Override
    public FileStorageRecord updateDisabledStatus(Long id, boolean disabled) {
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.DISABLED, disabled)
                .where(FILE_STORAGE.ID.eq(id))
                .execute();
        
        return getById(id);
    }
    
    @Override
    public FileStorageRecord updateMaxDownloads(Long id, int maxDownloads) {
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.MAX_DOWNLOADS, maxDownloads)
                .where(FILE_STORAGE.ID.eq(id))
                .execute();
        
        // Check if current download count exceeds new max, auto-disable if needed
        if (maxDownloads > 0) {
            ctx.update(FILE_STORAGE)
                    .set(FILE_STORAGE.DISABLED, true)
                    .where(FILE_STORAGE.ID.eq(id))
                    .and(FILE_STORAGE.DOWNLOAD_COUNT.ge(maxDownloads))
                    .execute();
        }
        
        return getById(id);
    }
    
    @Override
    public int getTotalCount() {
        return ctx.fetchCount(FILE_STORAGE);
    }
    
    @Override
    public String getFileName(Long id) {
        return ctx.select(FILE_STORAGE.FILE_NAME)
                .from(FILE_STORAGE)
                .where(FILE_STORAGE.ID.eq(id))
                .fetchOneInto(String.class);
    }
    
    @Override
    public FileStorageRecord updateFileVersion(Long id, String fileName, String version, String updateNotes, String md5Hash, long fileSize) {
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.FILE_NAME, fileName)
                .set(FILE_STORAGE.FILE_SIZE, fileSize)
                .set(FILE_STORAGE.MD5_HASH, md5Hash)
                .set(FILE_STORAGE.VERSION, version)
                .set(FILE_STORAGE.UPDATE_NOTES, updateNotes)
                .set(FILE_STORAGE.LAST_UPDATED, DateTime.now())
                .where(FILE_STORAGE.ID.eq(id))
                .execute();
        
        return getById(id);
    }
    
    @Override
    public FileStorageRecord updateFileInfo(Long id, String description, String version) {
        ctx.update(FILE_STORAGE)
                .set(FILE_STORAGE.DESCRIPTION, description)
                .set(FILE_STORAGE.VERSION, version)
                .set(FILE_STORAGE.LAST_UPDATED, DateTime.now())
                .where(FILE_STORAGE.ID.eq(id))
                .execute();
        
        return getById(id);
    }

    private static final RecordMapper<Record, FileStorageRecord> fileRecordMapper = record -> 
            FileStorageRecord.builder()
                    .id(record.getValue(FILE_STORAGE.ID))
                    .fileName(record.getValue(FILE_STORAGE.FILE_NAME))
                    .originalName(record.getValue(FILE_STORAGE.ORIGINAL_NAME))
                    .fileSize(record.getValue(FILE_STORAGE.FILE_SIZE))
                    .contentType(record.getValue(FILE_STORAGE.CONTENT_TYPE))
                    .uploadTime(new DateTime(record.getValue(FILE_STORAGE.UPLOAD_TIME)))
                    .uploadBy(record.getValue(FILE_STORAGE.UPLOAD_BY))
                    .filePath(record.getValue(FILE_STORAGE.FILE_PATH))
                    .description(record.getValue(FILE_STORAGE.DESCRIPTION))
                    .md5Hash(record.getValue(FILE_STORAGE.MD5_HASH))
                    .downloadCount(record.getValue(FILE_STORAGE.DOWNLOAD_COUNT))
                    .maxDownloads(record.getValue(FILE_STORAGE.MAX_DOWNLOADS))
                    .disabled(record.getValue(FILE_STORAGE.DISABLED))
                    .modifyDate(record.getValue(FILE_STORAGE.MODIFY_DATE) != null ? 
                            new DateTime(record.getValue(FILE_STORAGE.MODIFY_DATE)) : null)
                    .version(record.getValue(FILE_STORAGE.VERSION))
                    .updateNotes(record.getValue(FILE_STORAGE.UPDATE_NOTES))
                    .lastUpdated(record.getValue(FILE_STORAGE.LAST_UPDATED) != null ? 
                            new DateTime(record.getValue(FILE_STORAGE.LAST_UPDATED)) : null)
                    .build();
}
