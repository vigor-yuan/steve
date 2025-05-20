-- Combined SQL migration file
-- Generated automatically by merge_sql_files.py
-- Contains all migrations from the SteVe project


-- ============================================================
-- Migration: V0_6_6__inital.sql
-- ============================================================

--
-- Table structure for table `chargebox`
--

CREATE TABLE `chargebox` (
  `chargeBoxId` varchar(30) NOT NULL,
  `endpoint_address` varchar(45) DEFAULT NULL,
  `ocppVersion` varchar(3) DEFAULT NULL,
  `chargePointVendor` varchar(20) DEFAULT NULL,
  `chargePointModel` varchar(20) DEFAULT NULL,
  `chargePointSerialNumber` varchar(25) DEFAULT NULL,
  `chargeBoxSerialNumber` varchar(25) DEFAULT NULL,
  `fwVersion` varchar(20) DEFAULT NULL,
  `fwUpdateStatus` varchar(25) DEFAULT NULL,
  `fwUpdateTimestamp` timestamp NULL DEFAULT NULL,
  `iccid` varchar(20) DEFAULT NULL,
  `imsi` varchar(20) DEFAULT NULL,
  `meterType` varchar(25) DEFAULT NULL,
  `meterSerialNumber` varchar(25) DEFAULT NULL,
  `diagnosticsStatus` varchar(20) DEFAULT NULL,
  `diagnosticsTimestamp` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`chargeBoxId`),
  UNIQUE KEY `chargeBoxId_UNIQUE` (`chargeBoxId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `idTag` varchar(15) NOT NULL,
  `parentIdTag` varchar(15) DEFAULT NULL,
  `expiryDate` timestamp NULL DEFAULT NULL,
  `inTransaction` tinyint(1) unsigned NOT NULL,
  `blocked` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`idTag`),
  UNIQUE KEY `idTag_UNIQUE` (`idTag`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `connector`
--

CREATE TABLE `connector` (
  `connector_pk` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `chargeBoxId` varchar(30) NOT NULL,
  `connectorId` int(11) NOT NULL,
  PRIMARY KEY (`connector_pk`),
  UNIQUE KEY `connector_pk_UNIQUE` (`connector_pk`),
  UNIQUE KEY `connector_cbid_cid_UNIQUE` (`chargeBoxId`,`connectorId`),
  CONSTRAINT `FK_chargeBoxId_c` FOREIGN KEY (`chargeBoxId`) REFERENCES `chargebox` (`chargeBoxId`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;


--
-- Table structure for table `connector_status`
--

CREATE TABLE `connector_status` (
  `connector_pk` int(11) unsigned NOT NULL,
  `statusTimestamp` timestamp NULL DEFAULT NULL,
  `status` varchar(25) DEFAULT NULL,
  `errorCode` varchar(25) DEFAULT NULL,
  `errorInfo` varchar(50) DEFAULT NULL,
  `vendorId` varchar(255) DEFAULT NULL,
  `vendorErrorCode` varchar(50) DEFAULT NULL,
  KEY `FK_cs_pk_idx` (`connector_pk`),
  CONSTRAINT `FK_cs_pk` FOREIGN KEY (`connector_pk`) REFERENCES `connector` (`connector_pk`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `dbVersion`
--

CREATE TABLE `dbVersion` (
  `version` varchar(10) NOT NULL,
  `upateTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `dbVersion`
--

INSERT INTO `dbVersion` (`version`) VALUES ('0.6.6');

--
-- Table structure for table `transaction`
--

CREATE TABLE `transaction` (
  `transaction_pk` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `connector_pk` int(11) unsigned NOT NULL,
  `idTag` varchar(15) NOT NULL,
  `startTimestamp` timestamp NULL DEFAULT NULL,
  `startValue` varchar(45) DEFAULT NULL,
  `stopTimestamp` timestamp NULL DEFAULT NULL,
  `stopValue` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`transaction_pk`),
  UNIQUE KEY `transaction_pk_UNIQUE` (`transaction_pk`),
  KEY `idTag_idx` (`idTag`),
  KEY `connector_pk_idx` (`connector_pk`),
  CONSTRAINT `FK_connector_pk_t` FOREIGN KEY (`connector_pk`) REFERENCES `connector` (`connector_pk`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_idTag_t` FOREIGN KEY (`idTag`) REFERENCES `user` (`idTag`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Triggers on table `transaction`
--

DELIMITER ;;
CREATE TRIGGER `transaction_AINS` AFTER INSERT ON transaction FOR EACH ROW
  UPDATE user SET user.inTransaction=1 WHERE user.idTag=NEW.idTag;;
DELIMITER ;

DELIMITER ;;
CREATE TRIGGER `transaction_AUPD` AFTER UPDATE ON transaction FOR EACH ROW
  UPDATE user SET user.inTransaction=0 WHERE user.idTag=NEW.idTag;;
DELIMITER ;

--
-- Table structure for table `connector_metervalue`
--

CREATE TABLE `connector_metervalue` (
  `connector_pk` int(11) unsigned NOT NULL,
  `transaction_pk` int(10) unsigned DEFAULT NULL,
  `valueTimestamp` timestamp NULL DEFAULT NULL,
  `value` varchar(45) DEFAULT NULL,
  `readingContext` varchar(20) DEFAULT NULL,
  `format` varchar(20) DEFAULT NULL,
  `measurand` varchar(40) DEFAULT NULL,
  `location` varchar(10) DEFAULT NULL,
  `unit` varchar(10) DEFAULT NULL,
  KEY `FK_cm_pk_idx` (`connector_pk`),
  KEY `FK_tid_cm_idx` (`transaction_pk`),
  CONSTRAINT `FK_pk_cm` FOREIGN KEY (`connector_pk`) REFERENCES `connector` (`connector_pk`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_tid_cm` FOREIGN KEY (`transaction_pk`) REFERENCES `transaction` (`transaction_pk`) ON DELETE SET NULL ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `reservation`
--

CREATE TABLE `reservation` (
  `reservation_pk` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `idTag` varchar(15) NOT NULL,
  `chargeBoxId` varchar(30) NOT NULL,
  `startDatetime` datetime DEFAULT NULL,
  `expiryDatetime` datetime DEFAULT NULL,
  PRIMARY KEY (`reservation_pk`),
  UNIQUE KEY `reservation_pk_UNIQUE` (`reservation_pk`),
  KEY `FK_idTag_r_idx` (`idTag`),
  KEY `FK_chargeBoxId_r_idx` (`chargeBoxId`),
  CONSTRAINT `FK_chargeBoxId_r` FOREIGN KEY (`chargeBoxId`) REFERENCES `chargebox` (`chargeBoxId`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_idTag_r` FOREIGN KEY (`idTag`) REFERENCES `user` (`idTag`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

--
-- Table structure for table `reservation_expired`
--

CREATE TABLE `reservation_expired` (
  `reservation_pk` int(10) unsigned NOT NULL,
  `idTag` varchar(15) NOT NULL,
  `chargeBoxId` varchar(30) NOT NULL,
  `startDatetime` datetime NOT NULL,
  `expiryDatetime` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Dumping events for database
--

DELIMITER ;;

CREATE EVENT `expire_reservations`
  ON SCHEDULE EVERY 1 DAY STARTS '2013-11-16 03:00:00' ON COMPLETION NOT PRESERVE ENABLE DO
  BEGIN
    INSERT INTO reservation_expired (SELECT * FROM reservation WHERE reservation.expiryDatetime <= NOW());
    DELETE FROM reservation WHERE reservation.expiryDatetime <= NOW();
  END;;

DELIMITER ;

-- ============================================================
-- Migration: V0_6_7__update.sql
-- ============================================================

ALTER TABLE `dbVersion` CHANGE COLUMN `upateTimestamp` `updateTimestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  ;

UPDATE `dbVersion` SET `version` = '0.6.7';

ALTER TABLE `chargebox` ADD COLUMN `lastHeartbeatTimestamp` TIMESTAMP NULL DEFAULT NULL  AFTER `diagnosticsTimestamp` ;

DROP EVENT IF EXISTS expire_reservations;
DELIMITER ;;
CREATE EVENT expire_reservations
  ON SCHEDULE EVERY 1 DAY STARTS '2013-11-16 03:00:00'
DO BEGIN
  INSERT INTO reservation_expired (SELECT * FROM reservation WHERE reservation.expiryDatetime <= NOW());
  DELETE FROM reservation WHERE reservation.expiryDatetime <= NOW();
END ;;

DELIMITER ;;
CREATE PROCEDURE `getStats`(
  OUT numChargeBoxes INT,
  OUT numUsers INT,
  OUT numReservs INT,
  OUT numTranses INT,
  OUT heartbeatToday INT,
  OUT heartbeatYester INT,
  OUT heartbeatEarl INT,
  OUT connAvail INT,
  OUT connOcc INT,
  OUT connFault INT,
  OUT connUnavail INT)
  BEGIN
    -- # of chargeboxes
    SELECT COUNT(chargeBoxId) INTO numChargeBoxes FROM chargebox;
    -- # of users
    SELECT COUNT(idTag) INTO numUsers FROM user;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO numReservs FROM reservation;
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO numTranses FROM transaction WHERE stopTimestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatToday FROM chargebox
    WHERE lastHeartbeatTimestamp >= CURDATE();
    -- # of yesterday's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatYester FROM chargebox
    WHERE lastHeartbeatTimestamp >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND lastHeartbeatTimestamp < CURDATE();
    -- # of earlier heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatEarl FROM chargebox
    WHERE lastHeartbeatTimestamp < DATE_SUB(CURDATE(), INTERVAL 1 DAY);

    -- # of latest AVAILABLE statuses
    SELECT COUNT(cs.status) INTO connAvail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'AVAILABLE' GROUP BY cs.status;

    -- # of latest OCCUPIED statuses
    SELECT COUNT(cs.status) INTO connOcc
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'OCCUPIED' GROUP BY cs.status;

    -- # of latest FAULTED statuses
    SELECT COUNT(cs.status) INTO connFault
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'FAULTED' GROUP BY cs.status;

    -- # of latest UNAVAILABLE statuses
    SELECT COUNT(cs.status) INTO connUnavail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'UNAVAILABLE' GROUP BY cs.status;

  END ;;

-- ============================================================
-- Migration: V0_6_8__update.sql
-- ============================================================

UPDATE `dbVersion` SET `version` = '0.6.8';

DROP PROCEDURE `getStats`;

DELIMITER ;;
CREATE PROCEDURE `getStats`(
  OUT numChargeBoxes INT,
  OUT numUsers INT,
  OUT numReservs INT,
  OUT numTranses INT,
  OUT heartbeatToday INT,
  OUT heartbeatYester INT,
  OUT heartbeatEarl INT,
  OUT connAvail INT,
  OUT connOcc INT,
  OUT connFault INT,
  OUT connUnavail INT)
  BEGIN
    -- # of chargeboxes
    SELECT COUNT(chargeBoxId) INTO numChargeBoxes FROM chargebox;
    -- # of users
    SELECT COUNT(idTag) INTO numUsers FROM user;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO numReservs FROM reservation;
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO numTranses FROM transaction WHERE stopTimestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatToday FROM chargebox
    WHERE lastHeartbeatTimestamp >= CURDATE();
    -- # of yesterday's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatYester FROM chargebox
    WHERE lastHeartbeatTimestamp >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND lastHeartbeatTimestamp < CURDATE();
    -- # of earlier heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatEarl FROM chargebox
    WHERE lastHeartbeatTimestamp < DATE_SUB(CURDATE(), INTERVAL 1 DAY);

    -- # of latest AVAILABLE statuses
    SELECT COUNT(cs.status) INTO connAvail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'AVAILABLE';

    -- # of latest OCCUPIED statuses
    SELECT COUNT(cs.status) INTO connOcc
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'OCCUPIED';

    -- # of latest FAULTED statuses
    SELECT COUNT(cs.status) INTO connFault
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'FAULTED';

    -- # of latest UNAVAILABLE statuses
    SELECT COUNT(cs.status) INTO connUnavail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'UNAVAILABLE';
  END ;;
DELIMITER ;

-- ============================================================
-- Migration: V0_6_9__update.sql
-- ============================================================

UPDATE `dbVersion` SET `version` = '0.6.9';

ALTER TABLE `user`
ADD CONSTRAINT `FK_user_parentIdTag`
  FOREIGN KEY (`parentIdTag`)
  REFERENCES `user` (`idTag`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================
-- Migration: V0_7_0__update.sql
-- ============================================================

UPDATE `dbVersion` SET `version` = '0.7.0';

DROP EVENT IF EXISTS `expire_reservations`;

DROP TABLE `reservation_expired`;

ALTER TABLE `reservation`
ADD COLUMN `status` VARCHAR(15) NOT NULL AFTER `expiryDatetime`,
ADD COLUMN `transaction_pk` INT(10) UNSIGNED DEFAULT NULL AFTER `reservation_pk`,
ADD UNIQUE INDEX `transaction_pk_UNIQUE` (`transaction_pk` ASC),
ADD CONSTRAINT `FK_transaction_pk_r`
FOREIGN KEY (`transaction_pk`)
REFERENCES `transaction` (`transaction_pk`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

DROP PROCEDURE `getStats`;

DELIMITER ;;
CREATE PROCEDURE `getStats`(
  OUT numChargeBoxes INT,
  OUT numUsers INT,
  OUT numReservs INT,
  OUT numTranses INT,
  OUT heartbeatToday INT,
  OUT heartbeatYester INT,
  OUT heartbeatEarl INT,
  OUT connAvail INT,
  OUT connOcc INT,
  OUT connFault INT,
  OUT connUnavail INT)
  BEGIN
    -- # of chargeboxes
    SELECT COUNT(chargeBoxId) INTO numChargeBoxes FROM chargebox;
    -- # of users
    SELECT COUNT(idTag) INTO numUsers FROM user;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO numReservs FROM reservation WHERE expiryDatetime > CURRENT_TIMESTAMP AND status = 'Accepted';
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO numTranses FROM transaction WHERE stopTimestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatToday FROM chargebox
    WHERE lastHeartbeatTimestamp >= CURDATE();
    -- # of yesterday's heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatYester FROM chargebox
    WHERE lastHeartbeatTimestamp >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND lastHeartbeatTimestamp < CURDATE();
    -- # of earlier heartbeats
    SELECT COUNT(lastHeartbeatTimestamp) INTO heartbeatEarl FROM chargebox
    WHERE lastHeartbeatTimestamp < DATE_SUB(CURDATE(), INTERVAL 1 DAY);

    -- # of latest AVAILABLE statuses
    SELECT COUNT(cs.status) INTO connAvail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'AVAILABLE';

    -- # of latest OCCUPIED statuses
    SELECT COUNT(cs.status) INTO connOcc
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'OCCUPIED';

    -- # of latest FAULTED statuses
    SELECT COUNT(cs.status) INTO connFault
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'FAULTED';

    -- # of latest UNAVAILABLE statuses
    SELECT COUNT(cs.status) INTO connUnavail
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(statusTimestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.statusTimestamp = t1.Max
    WHERE cs.status = 'UNAVAILABLE';
  END ;;
DELIMITER ;

-- ============================================================
-- Migration: V0_7_1__update.sql
-- ============================================================

DROP TABLE `dbVersion`;

-- ============================================================
-- Migration: V0_7_2__update.sql
-- ============================================================

ALTER TABLE `chargebox`
CHANGE COLUMN `ocppVersion` `ocppProtocol` VARCHAR(10) NULL DEFAULT NULL ;

--
-- Migrate existing charge points from old 'version' scheme to the newer 'protocol' scheme
--
UPDATE `chargebox` SET `ocppProtocol`='ocpp1.2S' WHERE `ocppProtocol`='1.2';
UPDATE `chargebox` SET `ocppProtocol`='ocpp1.5S' WHERE `ocppProtocol`='1.5';

-- ============================================================
-- Migration: V0_7_3__update.sql
-- ============================================================

ALTER TABLE `chargebox`
CHANGE COLUMN `fwVersion` `fwVersion` VARCHAR(50) NULL DEFAULT NULL ;

-- ============================================================
-- Migration: V0_7_6__update.sql
-- ============================================================

ALTER TABLE `user`
ADD COLUMN `note` TEXT NULL COMMENT '' AFTER `blocked`;

ALTER TABLE `chargebox`
ADD COLUMN `note` TEXT NULL COMMENT '' AFTER `lastHeartbeatTimestamp`;

-- ============================================================
-- Migration: V0_7_7__update.sql
-- ============================================================

ALTER TABLE `chargebox`
CHANGE COLUMN `chargeBoxId` `chargeBoxId` VARCHAR(255) NOT NULL COMMENT '' ,
CHANGE COLUMN `endpoint_address` `endpoint_address` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `ocppProtocol` `ocppProtocol` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `chargePointVendor` `chargePointVendor` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `chargePointModel` `chargePointModel` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `chargePointSerialNumber` `chargePointSerialNumber` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `chargeBoxSerialNumber` `chargeBoxSerialNumber` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `fwVersion` `fwVersion` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `fwUpdateStatus` `fwUpdateStatus` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `iccid` `iccid` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `imsi` `imsi` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `meterType` `meterType` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `meterSerialNumber` `meterSerialNumber` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `diagnosticsStatus` `diagnosticsStatus` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ;


ALTER TABLE `connector`
DROP FOREIGN KEY `FK_chargeBoxId_c`;
ALTER TABLE `connector`
CHANGE COLUMN `chargeBoxId` `chargeBoxId` VARCHAR(255) NOT NULL COMMENT '' ;
ALTER TABLE `connector`
ADD CONSTRAINT `FK_chargeBoxId_c`
FOREIGN KEY (`chargeBoxId`)
REFERENCES `chargebox` (`chargeBoxId`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;


ALTER TABLE `connector_metervalue`
CHANGE COLUMN `value` `value` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `readingContext` `readingContext` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `format` `format` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `measurand` `measurand` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `location` `location` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `unit` `unit` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ;


ALTER TABLE `connector_status`
CHANGE COLUMN `status` `status` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `errorCode` `errorCode` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `errorInfo` `errorInfo` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `vendorErrorCode` `vendorErrorCode` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ;


ALTER TABLE `reservation`
DROP FOREIGN KEY `FK_chargeBoxId_r`,
DROP FOREIGN KEY `FK_idTag_r`;
ALTER TABLE `reservation`
CHANGE COLUMN `idTag` `idTag` VARCHAR(255) NOT NULL COMMENT '' ,
CHANGE COLUMN `chargeBoxId` `chargeBoxId` VARCHAR(255) NOT NULL COMMENT '' ,
CHANGE COLUMN `status` `status` VARCHAR(255) NOT NULL COMMENT '' ;
ALTER TABLE `reservation`
ADD CONSTRAINT `FK_chargeBoxId_r`
FOREIGN KEY (`chargeBoxId`)
REFERENCES `chargebox` (`chargeBoxId`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION,
ADD CONSTRAINT `FK_idTag_r`
FOREIGN KEY (`idTag`)
REFERENCES `user` (`idTag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `transaction`
DROP FOREIGN KEY `FK_idTag_t`;
ALTER TABLE `transaction`
CHANGE COLUMN `idTag` `idTag` VARCHAR(255) NOT NULL COMMENT '' ,
CHANGE COLUMN `startValue` `startValue` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ,
CHANGE COLUMN `stopValue` `stopValue` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ;
ALTER TABLE `transaction`
ADD CONSTRAINT `FK_idTag_t`
FOREIGN KEY (`idTag`)
REFERENCES `user` (`idTag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `user`
DROP FOREIGN KEY `FK_user_parentIdTag`;
ALTER TABLE `user`
CHANGE COLUMN `idTag` `idTag` VARCHAR(255) NOT NULL COMMENT '' ,
CHANGE COLUMN `parentIdTag` `parentIdTag` VARCHAR(255) NULL DEFAULT NULL COMMENT '' ;
ALTER TABLE `user`
ADD CONSTRAINT `FK_user_parentIdTag`
FOREIGN KEY (`parentIdTag`)
REFERENCES `user` (`idTag`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================
-- Migration: V0_7_8__update.sql
-- ============================================================

CREATE TABLE `settings` (
    `appId` VARCHAR(40),
    `heartbeatIntervalInSeconds` INT,
    `hoursToExpire` INT,
    PRIMARY KEY (`appId`),
    UNIQUE KEY `settings_id_UNIQUE` (`appId`)
);

INSERT INTO `settings` (appId, heartbeatIntervalInSeconds, hoursToExpire)
VALUES ('U3RlY2tkb3NlblZlcndhbHR1bmc=', 14400, 1);

-- ============================================================
-- Migration: V0_7_9__update.sql
-- ============================================================

--
-- all timestamps have fractional seconds with the precision 6 now.
-- fractional seconds are unfortunately not default, for compatibility with previous MySQL versions
-- (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
--

ALTER TABLE `chargebox`
CHANGE COLUMN `fwUpdateTimestamp` `fwUpdateTimestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `diagnosticsTimestamp` `diagnosticsTimestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `lastHeartbeatTimestamp` `lastHeartbeatTimestamp` TIMESTAMP(6) NULL DEFAULT NULL;

ALTER TABLE `connector_metervalue`
CHANGE COLUMN `valueTimestamp` `valueTimestamp` TIMESTAMP(6) NULL DEFAULT NULL;

ALTER TABLE `connector_status`
CHANGE COLUMN `statusTimestamp` `statusTimestamp` TIMESTAMP(6) NULL DEFAULT NULL;

ALTER TABLE `transaction`
CHANGE COLUMN `startTimestamp` `startTimestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `stopTimestamp` `stopTimestamp` TIMESTAMP(6) NULL DEFAULT NULL;

ALTER TABLE `user`
CHANGE COLUMN `expiryDate` `expiryDate` TIMESTAMP(6) NULL DEFAULT NULL;

-- ============================================================
-- Migration: V0_8_0__update.sql
-- ============================================================

--
-- add some indexes
--

ALTER TABLE `chargebox` ADD INDEX `chargebox_op_ep_idx` (`ocppProtocol`, `endpoint_address`);

ALTER TABLE `connector_status` ADD INDEX `connector_status_cpk_st_idx` (`connector_pk`, `statusTimestamp`);

ALTER TABLE `user`
ADD INDEX `user_expiryDate_idx` (`expiryDate`),
ADD INDEX `user_inTransaction_idx` (`inTransaction`),
ADD INDEX `user_blocked_idx` (`blocked`);

ALTER TABLE `reservation`
ADD INDEX `reservation_start_idx` (`startDatetime`),
ADD INDEX `reservation_expiry_idx` (`expiryDatetime`),
ADD INDEX `reservation_status_idx` (`status`);

ALTER TABLE `transaction`
ADD INDEX `transaction_start_idx` (`startTimestamp`),
ADD INDEX `transaction_stop_idx` (`stopTimestamp`);

-- ============================================================
-- Migration: V0_8_1__update.sql
-- ============================================================

--
-- drop foreign keys that will be affected by the rename process
--

ALTER TABLE `connector` DROP FOREIGN KEY `FK_chargeBoxId_c`;
ALTER TABLE `reservation` DROP FOREIGN KEY `FK_chargeBoxId_r`;
ALTER TABLE `reservation` DROP FOREIGN KEY `FK_idTag_r`;
ALTER TABLE `transaction` DROP FOREIGN KEY `FK_idTag_t`;
ALTER TABLE `user` DROP FOREIGN KEY `FK_user_parentIdTag`;

-- -------------------------------------------------------------------------
-- START: change table and column names from "camel case" to "snake case"
-- -------------------------------------------------------------------------

--
-- table charge_box
--

RENAME TABLE `chargebox` TO `charge_box`;

ALTER TABLE `charge_box`
CHANGE COLUMN `chargeBoxId` `charge_box_id` VARCHAR(255) NOT NULL,
CHANGE COLUMN `ocppProtocol` `ocpp_protocol` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `chargePointVendor` `charge_point_vendor` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `chargePointModel` `charge_point_model` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `chargePointSerialNumber` `charge_point_serial_number` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `chargeBoxSerialNumber` `charge_box_serial_number` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `fwVersion` `fw_version` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `fwUpdateStatus` `fw_update_status` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `fwUpdateTimestamp` `fw_update_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `meterType` `meter_type` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `meterSerialNumber` `meter_serial_number` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `diagnosticsStatus` `diagnostics_status` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `diagnosticsTimestamp` `diagnostics_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `lastHeartbeatTimestamp` `last_heartbeat_timestamp` TIMESTAMP(6) NULL DEFAULT NULL;

--
-- table connector
--

ALTER TABLE `connector`
CHANGE COLUMN `chargeBoxId` `charge_box_id` VARCHAR(255) NOT NULL,
CHANGE COLUMN `connectorId` `connector_id` INT(11) NOT NULL;

--
-- table connector_meter_value
--

RENAME TABLE `connector_metervalue` TO `connector_meter_value`;

ALTER TABLE `connector_meter_value`
CHANGE COLUMN `valueTimestamp` `value_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `readingContext` `reading_context` VARCHAR(255) NULL DEFAULT NULL;

--
-- table connector_status
--

ALTER TABLE `connector_status`
CHANGE COLUMN `statusTimestamp` `status_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `errorCode` `error_code` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `errorInfo` `error_info` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `vendorId` `vendor_id` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `vendorErrorCode` `vendor_error_code` VARCHAR(255) NULL DEFAULT NULL;

--
-- table reservation
--

ALTER TABLE `reservation`
CHANGE COLUMN `idTag` `id_tag` VARCHAR(255) NOT NULL,
CHANGE COLUMN `chargeBoxId` `charge_box_id` VARCHAR(255) NOT NULL,
CHANGE COLUMN `startDatetime` `start_datetime` DATETIME NULL DEFAULT NULL,
CHANGE COLUMN `expiryDatetime` `expiry_datetime` DATETIME NULL DEFAULT NULL;

--
-- table settings
--

ALTER TABLE `settings`
CHANGE COLUMN `appId` `app_id` VARCHAR(40) NOT NULL,
CHANGE COLUMN `heartbeatIntervalInSeconds` `heartbeat_interval_in_seconds` INT(11) NULL DEFAULT NULL,
CHANGE COLUMN `hoursToExpire` `hours_to_expire` INT(11) NULL DEFAULT NULL;

--
-- table transaction
--

ALTER TABLE `transaction`
CHANGE COLUMN `idTag` `id_tag` VARCHAR(255) NOT NULL,
CHANGE COLUMN `startTimestamp` `start_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `startValue` `start_value` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `stopTimestamp` `stop_timestamp` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `stopValue` `stop_value` VARCHAR(255) NULL DEFAULT NULL;

--
-- table user
--

ALTER TABLE `user`
CHANGE COLUMN `idTag` `id_tag` VARCHAR(255) NOT NULL,
CHANGE COLUMN `parentIdTag` `parent_id_tag` VARCHAR(255) NULL DEFAULT NULL,
CHANGE COLUMN `expiryDate` `expiry_date` TIMESTAMP(6) NULL DEFAULT NULL,
CHANGE COLUMN `inTransaction` `in_transaction` TINYINT(1) UNSIGNED NOT NULL;

-- -------------------------------------------------------------------------
-- END: change table and column names from "camel case" to "snake case"
-- -------------------------------------------------------------------------

--
-- add foreign keys back
--

ALTER TABLE `connector`
ADD CONSTRAINT `FK_connector_charge_box_cbid`
FOREIGN KEY (`charge_box_id`)
REFERENCES `charge_box` (`charge_box_id`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `reservation`
ADD CONSTRAINT `FK_reservation_charge_box_cbid`
FOREIGN KEY (`charge_box_id`)
REFERENCES `charge_box` (`charge_box_id`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `reservation`
ADD CONSTRAINT `FK_reservation_user_id_tag`
FOREIGN KEY (`id_tag`)
REFERENCES `user` (`id_tag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `transaction`
ADD CONSTRAINT `FK_transaction_user_id_tag`
FOREIGN KEY (`id_tag`)
REFERENCES `user` (`id_tag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `user`
ADD CONSTRAINT `FK_user_parent_id_tag`
FOREIGN KEY (`parent_id_tag`)
REFERENCES `user` (`id_tag`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


--
-- update the triggers
--

DELIMITER $$
DROP TRIGGER IF EXISTS `transaction_AINS`$$
CREATE TRIGGER `transaction_AINS` AFTER INSERT ON `transaction` FOR EACH ROW
  UPDATE `user`
  SET `user`.`in_transaction` = 1
  WHERE `user`.`id_tag` = NEW.`id_tag`$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `transaction_AUPD`$$
CREATE TRIGGER `transaction_AUPD` AFTER UPDATE ON `transaction` FOR EACH ROW
  UPDATE `user`
  SET `user`.`in_transaction` = 0
  WHERE `user`.`id_tag` = NEW.`id_tag`$$
DELIMITER ;


--
-- use auto incremented integers as PKs
--

ALTER TABLE `charge_box`
DROP PRIMARY KEY,
ADD `charge_box_pk` INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

ALTER TABLE `user`
DROP PRIMARY KEY,
ADD `user_pk` INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- ============================================================
-- Migration: V0_8_2__update.sql
-- ============================================================

--
-- change names from "camel case" to "snake case"
--

DROP PROCEDURE `getStats`;

DELIMITER ;;
CREATE PROCEDURE `get_stats`(
  OUT num_charge_boxes INT,
  OUT num_users INT,
  OUT num_reservations INT,
  OUT num_transactions INT,
  OUT heartbeats_today INT,
  OUT heartbeats_yesterday INT,
  OUT heartbeats_earlier INT,
  OUT connectors_available INT,
  OUT connectors_occupied INT,
  OUT connectors_faulted INT,
  OUT connectors_unavailable INT)
  BEGIN
    -- # of chargeboxes
    SELECT COUNT(charge_box_id) INTO num_charge_boxes FROM charge_box;
    -- # of users
    SELECT COUNT(id_tag) INTO num_users FROM `user`;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO num_reservations FROM reservation WHERE expiry_datetime > CURRENT_TIMESTAMP AND `status` = 'Accepted';
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO num_transactions FROM `transaction` WHERE stop_timestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_today FROM charge_box
    WHERE last_heartbeat_timestamp >= CURDATE();
    -- # of yesterday's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_yesterday FROM charge_box
    WHERE last_heartbeat_timestamp >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND last_heartbeat_timestamp < CURDATE();
    -- # of earlier heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_earlier FROM charge_box
    WHERE last_heartbeat_timestamp < DATE_SUB(CURDATE(), INTERVAL 1 DAY);

    -- # of latest AVAILABLE statuses
    SELECT COUNT(cs.status) INTO connectors_available
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'AVAILABLE';

    -- # of latest OCCUPIED statuses
    SELECT COUNT(cs.status) INTO connectors_occupied
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'OCCUPIED';

    -- # of latest FAULTED statuses
    SELECT COUNT(cs.status) INTO connectors_faulted
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'FAULTED';

    -- # of latest UNAVAILABLE statuses
    SELECT COUNT(cs.status) INTO connectors_unavailable
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'UNAVAILABLE';
  END ;;
DELIMITER ;

-- ============================================================
-- Migration: V0_8_4__update.sql
-- ============================================================

--
-- drop foreign keys
--

ALTER TABLE `user` DROP FOREIGN KEY `FK_user_parent_id_tag`;
ALTER TABLE `reservation` DROP FOREIGN KEY `FK_reservation_user_id_tag`;
ALTER TABLE `transaction` DROP FOREIGN KEY `FK_transaction_user_id_tag`;

-- -------------------------------------------------------------------------
-- START: rename table "user" to "ocpp_tag"
-- -------------------------------------------------------------------------

RENAME TABLE `user` TO `ocpp_tag`;

ALTER TABLE `ocpp_tag`
CHANGE COLUMN `user_pk` `ocpp_tag_pk` INT(11) NOT NULL AUTO_INCREMENT COMMENT '';

-- -------------------------------------------------------------------------
-- END: rename table "user" to "ocpp_tag"
-- -------------------------------------------------------------------------

--
-- add foreign keys back
--

ALTER TABLE `ocpp_tag`
ADD CONSTRAINT `FK_ocpp_tag_parent_id_tag`
FOREIGN KEY (`parent_id_tag`)
REFERENCES `ocpp_tag` (`id_tag`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `reservation`
ADD CONSTRAINT `FK_reservation_ocpp_tag_id_tag`
FOREIGN KEY (`id_tag`)
REFERENCES `ocpp_tag` (`id_tag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE `transaction`
ADD CONSTRAINT `FK_transaction_ocpp_tag_id_tag`
FOREIGN KEY (`id_tag`)
REFERENCES `ocpp_tag` (`id_tag`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

--
-- update the triggers
--

DELIMITER $$
DROP TRIGGER IF EXISTS `transaction_AINS`$$
CREATE TRIGGER `transaction_AINS` AFTER INSERT ON `transaction` FOR EACH ROW
  UPDATE `ocpp_tag`
  SET `ocpp_tag`.`in_transaction` = 1
  WHERE `ocpp_tag`.`id_tag` = NEW.`id_tag`$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `transaction_AUPD`$$
CREATE TRIGGER `transaction_AUPD` AFTER UPDATE ON `transaction` FOR EACH ROW
  UPDATE `ocpp_tag`
  SET `ocpp_tag`.`in_transaction` = 0
  WHERE `ocpp_tag`.`id_tag` = NEW.`id_tag`$$
DELIMITER ;

-- ============================================================
-- Migration: V0_8_5__update.sql
-- ============================================================

CREATE TABLE address (
  address_pk INT NOT NULL AUTO_INCREMENT,
  street_and_house_number varchar(1000),
  zip_code varchar(255),
  city varchar(255),
  country varchar(255),
  PRIMARY KEY (address_pk)
);

CREATE TABLE user (
  user_pk INT NOT NULL AUTO_INCREMENT,
  ocpp_tag_pk INT DEFAULT NULL,
  address_pk INT DEFAULT NULL,
  first_name varchar(255) NULL,
  last_name varchar(255) NULL,
  birth_day DATE,
  sex CHAR(1),
  phone varchar(255) NULL,
  e_mail varchar(255) NULL,
  note TEXT NULL,
  PRIMARY KEY (user_pk)
);

ALTER TABLE `charge_box`
ADD description TEXT AFTER last_heartbeat_timestamp,
ADD location_latitude DECIMAL(11,8) NULL,
ADD location_longitude DECIMAL(11,8) NULL;

ALTER TABLE `charge_box`
ADD address_pk INT DEFAULT NULL,
ADD CONSTRAINT FK_charge_box_address_apk
FOREIGN KEY (address_pk) REFERENCES address (address_pk) ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE `user`
ADD CONSTRAINT `FK_user_ocpp_tag_otpk`
FOREIGN KEY (`ocpp_tag_pk`) REFERENCES `ocpp_tag` (`ocpp_tag_pk`) ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE `user`
ADD CONSTRAINT FK_user_address_apk
FOREIGN KEY (address_pk) REFERENCES address (address_pk) ON DELETE SET NULL ON UPDATE NO ACTION;

--
-- update the procedure
--

DROP PROCEDURE IF EXISTS `get_stats`;

DELIMITER ;;
CREATE PROCEDURE `get_stats`(
  OUT num_charge_boxes INT,
  OUT num_ocpp_tags INT,
  OUT num_users INT,
  OUT num_reservations INT,
  OUT num_transactions INT,
  OUT heartbeats_today INT,
  OUT heartbeats_yesterday INT,
  OUT heartbeats_earlier INT,
  OUT connectors_available INT,
  OUT connectors_occupied INT,
  OUT connectors_faulted INT,
  OUT connectors_unavailable INT)
  BEGIN
    -- we can compute these once, and reuse the instances in the following queries,
    -- instead of calculating them every time
    --
    DECLARE today DATE DEFAULT CURRENT_DATE();
    DECLARE yesterday DATE DEFAULT DATE_SUB(today, INTERVAL 1 DAY);

    -- # of chargeboxes
    SELECT COUNT(charge_box_id) INTO num_charge_boxes FROM charge_box;
    -- # of ocpp tags
    SELECT COUNT(ocpp_tag_pk) INTO num_ocpp_tags FROM ocpp_tag;
    -- # of users
    SELECT COUNT(user_pk) INTO num_users FROM `user`;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO num_reservations FROM reservation WHERE expiry_datetime > CURRENT_TIMESTAMP AND `status` = 'Accepted';
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO num_transactions FROM `transaction` WHERE stop_timestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_today FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) = today;
    -- # of yesterday's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_yesterday FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) = yesterday;
    -- # of earlier heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_earlier FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) < yesterday;

    -- # of latest AVAILABLE statuses
    SELECT COUNT(cs.status) INTO connectors_available
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'AVAILABLE';

    -- # of latest OCCUPIED statuses
    SELECT COUNT(cs.status) INTO connectors_occupied
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'OCCUPIED';

    -- # of latest FAULTED statuses
    SELECT COUNT(cs.status) INTO connectors_faulted
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'FAULTED';

    -- # of latest UNAVAILABLE statuses
    SELECT COUNT(cs.status) INTO connectors_unavailable
    FROM connector_status cs
      INNER JOIN (SELECT connector_pk, MAX(status_timestamp) AS Max FROM connector_status GROUP BY connector_pk)
        AS t1 ON cs.connector_pk = t1.connector_pk AND cs.status_timestamp = t1.Max
    WHERE cs.status = 'UNAVAILABLE';
  END ;;
DELIMITER ;

-- ============================================================
-- Migration: V0_8_6__update.sql
-- ============================================================

--
-- update the character set for existing installations.

-- mysql will refuse to change the character set of tables with foreign key relationships,
-- so we disable foreign key checks (we could also first drop FKs and after changes insert FKs again).
-- but then, to ensure data integrity, we should block other access to these tables. hence, the lock tables.
--
-- and also we cannot touch book keeping table "schema_version" of flyway,
-- since it will be in use during the migration.
--

LOCK TABLES
  address WRITE,
  charge_box WRITE,
  connector WRITE,
  connector_meter_value WRITE,
  connector_status WRITE,
  ocpp_tag WRITE,
  reservation WRITE,
  settings WRITE,
  `transaction` WRITE,
  `user` WRITE;

SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE charge_box CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE address CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE connector CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE connector_meter_value CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE connector_status CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE ocpp_tag CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE reservation CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE settings CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE `transaction` CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE `user` CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

UNLOCK TABLES;

REPAIR TABLE
  address,
  charge_box,
  connector,
  connector_meter_value,
  connector_status,
  ocpp_tag,
  reservation,
  settings,
  `transaction`,
  `user`;

OPTIMIZE TABLE
  address,
  charge_box,
  connector,
  connector_meter_value,
  connector_status,
  ocpp_tag,
  reservation,
  settings,
  `transaction`,
  `user`;

-- ============================================================
-- Migration: V0_8_7__update.sql
-- ============================================================

--
-- split "street_and_house_number" into "street" and "house_number"
--

ALTER TABLE `address`
CHANGE COLUMN `street_and_house_number` `street` VARCHAR(1000),
ADD house_number varchar(255) AFTER `street`;

-- ============================================================
-- Migration: V0_8_8__update.sql
-- ============================================================

ALTER TABLE `settings`
  ADD COLUMN `mail_enabled` BOOLEAN DEFAULT FALSE,

  ADD COLUMN `mail_host` VARCHAR(255) DEFAULT NULL,
  ADD COLUMN `mail_username` VARCHAR(255) DEFAULT NULL,
  ADD COLUMN `mail_password` VARCHAR(255) DEFAULT NULL,
  ADD COLUMN `mail_from` VARCHAR(255) DEFAULT NULL,
  ADD COLUMN `mail_protocol` VARCHAR(255) DEFAULT 'smtp',

  ADD COLUMN `mail_port` INT DEFAULT 25,

  ADD COLUMN `mail_recipients` TEXT COMMENT 'comma separated list of email addresses',
  ADD COLUMN `notification_features` TEXT COMMENT 'comma separated list';

-- ============================================================
-- Migration: V0_8_9__update.sql
-- ============================================================

--
-- the proc does not include status counts anymore, because we handle them separately
--

DROP PROCEDURE IF EXISTS `get_stats`;

DELIMITER ;;
CREATE PROCEDURE `get_stats`(
  OUT num_charge_boxes INT,
  OUT num_ocpp_tags INT,
  OUT num_users INT,
  OUT num_reservations INT,
  OUT num_transactions INT,
  OUT heartbeats_today INT,
  OUT heartbeats_yesterday INT,
  OUT heartbeats_earlier INT)
  BEGIN
    -- we can compute these once, and reuse the instances in the following queries,
    -- instead of calculating them every time
    --
    DECLARE today DATE DEFAULT CURRENT_DATE();
    DECLARE yesterday DATE DEFAULT DATE_SUB(today, INTERVAL 1 DAY);

    -- # of chargeboxes
    SELECT COUNT(charge_box_id) INTO num_charge_boxes FROM charge_box;
    -- # of ocpp tags
    SELECT COUNT(ocpp_tag_pk) INTO num_ocpp_tags FROM ocpp_tag;
    -- # of users
    SELECT COUNT(user_pk) INTO num_users FROM `user`;
    -- # of reservations
    SELECT COUNT(reservation_pk) INTO num_reservations FROM reservation WHERE expiry_datetime > CURRENT_TIMESTAMP AND `status` = 'Accepted';
    -- # of active transactions
    SELECT COUNT(transaction_pk) INTO num_transactions FROM `transaction` WHERE stop_timestamp IS NULL;

    -- # of today's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_today FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) = today;
    -- # of yesterday's heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_yesterday FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) = yesterday;
    -- # of earlier heartbeats
    SELECT COUNT(last_heartbeat_timestamp) INTO heartbeats_earlier FROM charge_box
    WHERE DATE(last_heartbeat_timestamp) < yesterday;

  END ;;
DELIMITER ;

-- ============================================================
-- Migration: V0_9_0__update.sql
-- ============================================================

--
-- store connector_pk in reservation table.
--

START TRANSACTION;

-- add column without constraints

ALTER TABLE `reservation`
ADD COLUMN `connector_pk` INT(11) UNSIGNED AFTER `reservation_pk`;


-- set connector_pk of existing reservations to connector 0 of the corresponding charge box.

UPDATE `reservation`
SET `connector_pk` = (
  SELECT `connector`.`connector_pk`
  FROM `connector`
  WHERE `connector`.`charge_box_id` = `reservation`.`charge_box_id` AND `connector`.`connector_id` = 0
);


-- now that all connector_pk columns have values set, add constraints

ALTER TABLE `reservation`
  MODIFY COLUMN `connector_pk` INT(11) UNSIGNED NOT NULL AFTER `reservation_pk`,
  ADD INDEX `FK_connector_pk_reserv_idx` (`connector_pk` ASC);

ALTER TABLE `reservation`
ADD CONSTRAINT `FK_connector_pk_reserv` FOREIGN KEY (`connector_pk`)
REFERENCES `connector` (`connector_pk`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;


-- charge_box_id column is redundant, remove it.

ALTER TABLE `reservation`
  DROP FOREIGN KEY `FK_reservation_charge_box_cbid`,
  DROP COLUMN `charge_box_id`,
  DROP INDEX `FK_chargeBoxId_r_idx` ;

COMMIT;

-- ============================================================
-- Migration: V0_9_1__update.sql
-- ============================================================

ALTER TABLE `connector_meter_value`
  ADD INDEX `cmv_value_timestamp_idx` (`value_timestamp` ASC)  COMMENT '';

-- ============================================================
-- Migration: V0_9_2__update.sql
-- ============================================================

ALTER TABLE `transaction`
  ADD COLUMN `stop_reason` VARCHAR(255) DEFAULT NULL AFTER `stop_value`;

ALTER TABLE `connector_meter_value`
  ADD COLUMN `phase` VARCHAR(255) DEFAULT NULL AFTER `unit`;

-- ============================================================
-- Migration: V0_9_3__update.sql
-- ============================================================

DROP TRIGGER IF EXISTS `transaction_AINS`;

DROP TRIGGER IF EXISTS `transaction_AUPD`;

-- ============================================================
-- Migration: V0_9_4__update.sql
-- ============================================================

DROP PROCEDURE `get_stats`;

-- ============================================================
-- Migration: V0_9_5__update.sql
-- ============================================================

ALTER TABLE `charge_box`
  ADD admin_address varchar(255) NULL,
  ADD insert_connector_status_after_transaction_msg BOOLEAN DEFAULT TRUE;

-- ============================================================
-- Migration: V0_9_6__update.sql
-- ============================================================

CREATE TABLE charging_profile (
  charging_profile_pk INT NOT NULL AUTO_INCREMENT,
  stack_level INT NOT NULL,
  charging_profile_purpose varchar(255) NOT NULL,
  charging_profile_kind varchar(255) NOT NULL,
  recurrency_kind varchar(255) NULL,
  valid_from TIMESTAMP(6) NULL,
  valid_to TIMESTAMP(6) NULL,

  duration_in_seconds INT NULL,
  start_schedule TIMESTAMP(6) NULL NULL,
  charging_rate_unit varchar(255) NOT NULL,
  min_charging_rate decimal(15, 1) NULL, -- according to ocpp, at most one digit fraction.

  description varchar(255) null,
  note TEXT null,

  PRIMARY KEY (charging_profile_pk)
);

CREATE TABLE charging_schedule_period (
  charging_profile_pk INT NOT NULL,
  start_period_in_seconds INT NOT NULL,
  power_limit_in_amperes decimal(15, 1) NOT NULL, -- according to ocpp, at most one digit fraction.
  number_phases INT NULL
);

CREATE TABLE connector_charging_profile (
  connector_pk INT(11) UNSIGNED NOT NULL,
  charging_profile_pk INT NOT NULL
);

ALTER TABLE `connector_charging_profile`
ADD UNIQUE `UQ_connector_charging_profile`(`connector_pk`, `charging_profile_pk`);

ALTER TABLE `charging_schedule_period`
ADD UNIQUE `UQ_charging_schedule_period`(`charging_profile_pk`, `start_period_in_seconds`);

ALTER TABLE `charging_schedule_period`
ADD CONSTRAINT `FK_charging_schedule_period_charging_profile_pk`
FOREIGN KEY (`charging_profile_pk`) REFERENCES `charging_profile` (`charging_profile_pk`) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE `connector_charging_profile`
ADD CONSTRAINT `FK_connector_charging_profile_charging_profile_pk`
FOREIGN KEY (`charging_profile_pk`) REFERENCES `charging_profile` (`charging_profile_pk`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `connector_charging_profile`
ADD CONSTRAINT `FK_connector_charging_profile_connector_pk`
FOREIGN KEY (`connector_pk`) REFERENCES `connector` (`connector_pk`) ON DELETE CASCADE ON UPDATE NO ACTION;

-- ============================================================
-- Migration: V0_9_7__update.sql
-- ============================================================

DROP INDEX user_inTransaction_idx ON ocpp_tag;

ALTER TABLE ocpp_tag DROP COLUMN in_transaction;

CREATE OR REPLACE VIEW ocpp_tag_activity AS
    SELECT
      ocpp_tag.*,
      COALESCE(tx_activity.active_transaction_count, 0) as 'active_transaction_count',
      CASE WHEN (active_transaction_count > 0) THEN TRUE ELSE FALSE END AS 'in_transaction'
    FROM ocpp_tag
    LEFT JOIN
    (SELECT id_tag, count(id_tag) as 'active_transaction_count'
      FROM transaction
      WHERE stop_timestamp IS NULL
      AND stop_value IS NULL
      GROUP BY id_tag) tx_activity
    ON ocpp_tag.id_tag = tx_activity.id_tag;

-- ============================================================
-- Migration: V0_9_8__update.sql
-- ============================================================

START TRANSACTION;

ALTER TABLE `transaction`
  ADD `event_timestamp` TIMESTAMP(6) AFTER `transaction_pk`;

-- for backwards compatibility and existing data
UPDATE `transaction` SET `event_timestamp` = `start_timestamp`;

-- now that the values are set, add constraints
ALTER TABLE `transaction`
  MODIFY COLUMN `event_timestamp` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) AFTER `transaction_pk`;

CREATE TABLE transaction_stop (
  transaction_pk INT(10) UNSIGNED NOT NULL,
  event_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  event_actor ENUM('station', 'manual'),
  stop_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  stop_value VARCHAR(255) NOT NULL,
  stop_reason VARCHAR(255),
  PRIMARY KEY(transaction_pk, event_timestamp)
);

ALTER TABLE `transaction_stop`
ADD CONSTRAINT `FK_transaction_stop_transaction_pk`
FOREIGN KEY (`transaction_pk`) REFERENCES `transaction` (`transaction_pk`) ON DELETE CASCADE ON UPDATE NO ACTION;

-- move data from transaction table to transaction_stop table
INSERT INTO `transaction_stop` (transaction_pk, event_timestamp, event_actor, stop_timestamp, stop_value, stop_reason)
SELECT t.transaction_pk, t.stop_timestamp, 'station', t.stop_timestamp, t.stop_value, t.stop_reason
  FROM `transaction` t
  WHERE t.stop_value IS NOT NULL AND t.stop_timestamp IS NOT NULL;

-- now that we moved the data, drop redundant columns
ALTER TABLE `transaction`
  DROP COLUMN `stop_timestamp`,
  DROP COLUMN `stop_value`,
  DROP COLUMN `stop_reason`,
  DROP INDEX `transaction_stop_idx`;

-- rename old table
RENAME TABLE `transaction` TO `transaction_start`;

-- reconstruct `transaction` as a view for database changes to be transparent to java app
-- select LATEST stop transaction events when joining
CREATE OR REPLACE VIEW `transaction` AS
 SELECT
  tx1.transaction_pk, tx1.connector_pk, tx1.id_tag, tx1.event_timestamp as 'start_event_timestamp', tx1.start_timestamp, tx1.start_value,
  tx2.event_actor as 'stop_event_actor', tx2.event_timestamp as 'stop_event_timestamp', tx2.stop_timestamp, tx2.stop_value, tx2.stop_reason
  FROM transaction_start tx1
  LEFT JOIN (
    SELECT s1.*
    FROM transaction_stop s1
    WHERE s1.event_timestamp = (SELECT MAX(event_timestamp) FROM transaction_stop s2 WHERE s1.transaction_pk = s2.transaction_pk)
    GROUP BY s1.transaction_pk, s1.event_timestamp) tx2
  ON tx1.transaction_pk = tx2.transaction_pk;

COMMIT;

-- ============================================================
-- Migration: V0_9_9__update.sql
-- ============================================================

START TRANSACTION;

ALTER TABLE `ocpp_tag`
  ADD `max_active_transaction_count` INTEGER NOT NULL DEFAULT 1 AFTER `expiry_date`;

UPDATE `ocpp_tag` SET `max_active_transaction_count` = 0 WHERE `blocked` = TRUE;

ALTER TABLE `ocpp_tag` DROP COLUMN `blocked`;

-- recreate this view, with derived "blocked" field to be transparent to java app
CREATE OR REPLACE VIEW ocpp_tag_activity AS
    SELECT
      ocpp_tag.*,
      COALESCE(tx_activity.active_transaction_count, 0) as 'active_transaction_count',
      CASE WHEN (active_transaction_count > 0) THEN TRUE ELSE FALSE END AS 'in_transaction',
      CASE WHEN (ocpp_tag.max_active_transaction_count = 0) THEN TRUE ELSE FALSE END AS 'blocked'
    FROM ocpp_tag
    LEFT JOIN
    (SELECT id_tag, count(id_tag) as 'active_transaction_count'
      FROM transaction
      WHERE stop_timestamp IS NULL
      AND stop_value IS NULL
      GROUP BY id_tag) tx_activity
    ON ocpp_tag.id_tag = tx_activity.id_tag;

COMMIT;

-- ============================================================
-- Migration: V1_0_0__update.sql
-- ============================================================

CREATE TABLE transaction_stop_failed (
  transaction_pk INT,
  event_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  event_actor ENUM('station', 'manual'),
  stop_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  stop_value VARCHAR(255),
  stop_reason VARCHAR(255),
  fail_reason TEXT
);

-- ============================================================
-- Migration: V1_0_1__update.sql
-- ============================================================

-- https://github.com/RWTH-i5-IDSG/steve/issues/212
ALTER TABLE `connector_meter_value` MODIFY `value` TEXT;

-- ============================================================
-- Migration: V1_0_2__update.sql
-- ============================================================

ALTER TABLE `charge_box`
    ADD COLUMN `registration_status` VARCHAR(255) NOT NULL DEFAULT 'Accepted' AFTER `ocpp_protocol`;

-- ============================================================
-- Migration: V1_0_3__update.sql
-- ============================================================

-- came with https://github.com/RWTH-i5-IDSG/steve/issues/310
ALTER TABLE `charging_schedule_period`
    CHANGE COLUMN `power_limit_in_amperes` `power_limit` DECIMAL(15, 1) NOT NULL;

-- ============================================================
-- Migration: V1_0_4__update.sql
-- ============================================================

-- Add file storage table for file upload/download feature

CREATE TABLE file_storage (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL COMMENT 'Stored file name on server',
    original_name VARCHAR(255) NOT NULL COMMENT 'Original file name',
    file_size BIGINT NOT NULL COMMENT 'File size in bytes',
    content_type VARCHAR(100) COMMENT 'MIME type of the file',
    upload_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Upload timestamp',
    upload_by VARCHAR(100) COMMENT 'Username who uploaded the file',
    file_path VARCHAR(500) NOT NULL COMMENT 'Path to the file on server',
    description TEXT COMMENT 'Optional file description'
) COMMENT 'Table for storing file metadata for upload/download feature';

-- Add index for faster search
CREATE INDEX idx_file_storage_name ON file_storage(original_name);
CREATE INDEX idx_file_storage_upload_time ON file_storage(upload_time);

-- ============================================================
-- Migration: V1_0_5__update.sql
-- ============================================================

-- Add MD5 and download count fields to file_storage table

ALTER TABLE file_storage 
ADD COLUMN md5_hash VARCHAR(32) COMMENT 'MD5 hash of the file',
ADD COLUMN download_count INT DEFAULT 0 COMMENT 'Number of times the file has been downloaded',
ADD COLUMN max_downloads INT DEFAULT 0 COMMENT 'Maximum allowed downloads (0 = unlimited)',
ADD COLUMN disabled BOOLEAN DEFAULT FALSE COMMENT 'Whether the file is disabled',
ADD COLUMN modify_date TIMESTAMP NULL COMMENT 'File modification date';

-- Add index for faster search by MD5
CREATE INDEX idx_file_storage_md5 ON file_storage(md5_hash);

-- ============================================================
-- Migration: V1_0_6__file_storage_update.sql
-- ============================================================

-- Add new columns to file_storage table
ALTER TABLE file_storage 
    ADD COLUMN version VARCHAR(50) COMMENT 'Version number of the file',
    ADD COLUMN update_notes TEXT COMMENT 'Update notes for this version',
    ADD COLUMN download_url VARCHAR(500) COMMENT 'Download URL for the file',
    ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update time';

