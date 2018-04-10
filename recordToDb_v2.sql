DELIMITER $$

USE `eventDBv2` $$

DROP PROCEDURE IF EXISTS `recordToDb`$$

CREATE PROCEDURE recordToDb
(IN _roomID INT, IN _uid char(30))
BEGIN
  DECLARE _timecheck timestamp;
  DECLARE _hca bool;
  DECLARE _hsk bool;
  DECLARE _flag bool;
  DECLARE _roomStatus bool;
  DECLARE _depID int;
  DECLARE _dep_code char(6);
  DECLARE _isRecordEXISTS bool;
  DECLARE _isAuthorized bool;
  DECLARE _isDepExists bool;
  DECLARE _dep1lastCheck timestamp;
  DECLARE _dep2lastCheck timestamp;
  DECLARE _dep1TimeOut int;
  DECLARE _dep2TimeOut int;
  DECLARE _timeOutLimit int;
  DECLARE _lastRecordTime timestamp;
  DECLARE _recordTimeOut int;
  
  SET _timecheck = (SELECT NOW());
  SET _flag = false;
  SET _depID = (SELECT depID FROM emps WHERE uid =_uid LIMIT 1);
  SET _roomStatus = false;
  SET _isRecordEXISTS  = (SELECT EXISTS(SELECT * FROM availability WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1));
  SET _isAuthorized  = false;
  SET _isDepExists = (SELECT EXISTS(SELECT * FROM deps WHERE depID =_depID));
  SET _timeOutLimit = 5; -- 5 miutes cooldown for db
  SET _lastRecordTime = (SELECT timecheck FROM records  WHERE uid = _uid ORDER BY recordID DESC LIMIT 1);
  IF _lastRecordTime is null then
	SET _lastRecordTime = (SELECT NOW() - INTERVAL 1 HOUR);
  END IF;
  SET _recordTimeOut = (SELECT TIMESTAMPDIFF(MINUTE,_lastRecordTime, _timecheck));
  
  SET _hsk = false;
  SET _roomStatus = false;
  SET _hca = false;
  
  IF _isDepExists = false AND _recordTimeOut >= _timeOutLimit then
	SET _depID = 0;
	INSERT INTO records(roomID,uid,timecheck,depID,flag,auth) VALUES(_roomID,_uid,_timecheck,_depID,_flag, _isAuthorized);
    commit;
  ELSEIF _isDepExists = true AND _recordTimeOut >= _timeOutLimit then
    
	SET _isAuthorized  = true;
    -- SET _dep_code = (SELECT dep_code FROM deps WHERE depID =_depID);
    INSERT INTO records(roomID,uid,timecheck,depID,flag,auth) VALUES(_roomID,_uid,_timecheck,_depID,_flag, _isAuthorized);
    commit;
	IF _isRecordEXISTS then
    
		SET _hsk = (SELECT hsk FROM availability WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
		SET _roomStatus = (SELECT roomStatus FROM availability  WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
		SET _hca = (SELECT hca FROM availability WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
        
        IF _depID = 1 THEN -- department HCA depid 1
			SET _dep1lastCheck = (SELECT timecheck FROM availability  WHERE hca = 1 ORDER BY ID DESC LIMIT 1);
            IF _dep1lastCheck is null then
				SET _dep1lastCheck = (SELECT NOW() - INTERVAL 1 HOUR);
            END IF;
            SET _dep1TimeOut = (SELECT TIMESTAMPDIFF(MINUTE, _dep1lastCheck, _timecheck));
			SET _hca = true; 
			IF _hsk = true THEN
				SET _roomStatus = true;
			END IF;
        
		ELSEIF _depID = 2 THEN -- department HSK depid 2
			SET _dep2lastCheck = (SELECT timecheck FROM availability  WHERE hsk = 1 ORDER BY ID DESC LIMIT 1);
            IF _dep2lastCheck is null then
				SET _dep2lastCheck = (SELECT NOW() - INTERVAL 1 HOUR);
            END IF;
            SET _dep2TimeOut = (SELECT TIMESTAMPDIFF(MINUTE, _dep2lastCheck, _timecheck));
			SET _hsk = true;
			IF _hca = true THEN
				SET _roomStatus = true;
			END IF;
		END IF;
        
        IF _depID = 1 AND _dep1TimeOut >= _timeOutLimit  then -- if more then 5 minutes
			INSERT INTO availability (roomID,hca,hsk,timecheck,flag,roomStatus) VALUES(_roomID,_hca,_hsk,_timecheck,_flag,_roomStatus);
            commit;
		ELSEIF _depID = 2 AND _dep2TimeOut >= _timeOutLimit then -- if more then 5 minutes
			INSERT INTO availability (roomID,hca,hsk,timecheck,flag,roomStatus) VALUES(_roomID,_hca,_hsk,_timecheck,_flag,_roomStatus);
            commit;
		END IF;
        
        IF _hsk = true AND _hca = true AND _roomStatus = true THEN -- reset room availability to default(unavailabile)
			SET _hsk = false;
			SET _hca = false;
			SET _roomStatus = false;
			SET _timecheck = (SELECT NOW());
			INSERT INTO availability (roomID,hca,hsk,timecheck,flag,roomStatus) VALUES(_roomID,_hca,_hsk,_timecheck,_flag,_roomStatus);
            commit;
		END IF;  
	ELSE 
		IF _depID = 1 THEN -- department HCA depid 1
			SET _hca = true;

		ELSEIF _depID = 2 THEN -- department HSK depid 2
			SET _hsk = true;
			
		END IF; 
        INSERT INTO availability (roomID,hca,hsk,timecheck,flag,roomStatus) VALUES(_roomID,_hca,_hsk,_timecheck,_flag,_roomStatus);
        commit;
    END IF; 
  END IF; 
END $$
DELIMITER ;