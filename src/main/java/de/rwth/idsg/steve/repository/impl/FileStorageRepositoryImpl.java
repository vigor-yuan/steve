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
                    .set(FILE_STORAGE.UPLOAD_TIME, record.getUploadTime().toDate())
                    .set(FILE_STORAGE.UPLOAD_BY, record.getUploadBy())
                    .set(FILE_STORAGE.FILE_PATH, record.getFilePath())
                    .set(FILE_STORAGE.DESCRIPTION, record.getDescription())
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
                    .set(FILE_STORAGE.UPLOAD_TIME, record.getUploadTime().toDate())
                    .set(FILE_STORAGE.UPLOAD_BY, record.getUploadBy())
                    .set(FILE_STORAGE.FILE_PATH, record.getFilePath())
                    .set(FILE_STORAGE.DESCRIPTION, record.getDescription())
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
                    .build();
}
