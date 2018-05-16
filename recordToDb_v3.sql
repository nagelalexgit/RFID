DELIMITER $$

USE `eventDBv2` $$

DROP PROCEDURE IF EXISTS `recordToDb`$$

CREATE PROCEDURE recordToDb
(IN _roomDecription varchar(15), IN _uid varchar(50))
BEGIN
  DECLARE _timecheck timestamp;
  DECLARE __roomID int;
  DECLARE _HCA bool;
  DECLARE _HK bool;
  DECLARE _flag bool;
  DECLARE _roomStatus bool;
  DECLARE _depID int;
  DECLARE _dep_code varchar(6);
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
  DECLARE _roomID int;
  
  SET _roomID = (SELECT roomID FROM rooms WHERE description =_roomDecription LIMIT 1);
  IF _roomID is null then
	SET _roomID = 999;
  END IF;
  SET _timecheck = (SELECT NOW());
  SET _flag = false;
  SET _depID = (SELECT depID FROM emps WHERE uid =_uid LIMIT 1);
  SET _dep_code = (SELECT dep_code FROM deps WHERE depID =_depID LIMIT 1);
  SET _roomStatus = false;
  SET _isRecordEXISTS  = (SELECT EXISTS(SELECT * FROM availability WHERE roomID =_roomID AND roomID <> 100 ORDER BY ID DESC LIMIT 1));
  SET _isAuthorized  = false;
  SET _isDepExists = (SELECT EXISTS(SELECT * FROM deps WHERE depID =_depID));
  SET _timeOutLimit = 5; -- 5 miutes cooldown for db
  SET _lastRecordTime = (SELECT timecheck FROM records  WHERE uid = _uid ORDER BY recordID DESC LIMIT 1);
  IF _lastRecordTime is null then
	SET _lastRecordTime = (SELECT NOW() - INTERVAL 1 HOUR);
  END IF;
  SET _recordTimeOut = (SELECT TIMESTAMPDIFF(MINUTE,_lastRecordTime, _timecheck));
  
  SET _HK = false;
  SET _roomStatus = false;
  SET _HCA = false;
  
  IF (_isDepExists = false OR _dep_code = 'OTR')  AND _recordTimeOut >= _timeOutLimit then
	SET _depID = 0;
	INSERT INTO records(roomID,uid,timecheck,depID,flag,auth) VALUES(_roomID,_uid,_timecheck,_depID,_flag, _isAuthorized);
    commit;
    
  ELSEIF (_isDepExists = true OR _dep_code = 'HCA' OR _dep_code = 'HK') AND _recordTimeOut >= _timeOutLimit then    -- ?????????????????????????
	SET _isAuthorized  = true;
    -- SET _dep_code = (SELECT dep_code FROM deps WHERE depID =_depID);
    INSERT INTO records(roomID,uid,timecheck,depID,flag,auth) VALUES(_roomID,_uid,_timecheck,_depID,_flag, _isAuthorized);
    commit;
	IF _isRecordEXISTS then
    
		SET _HK = (SELECT HK FROM availability WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
		SET _roomStatus = (SELECT roomStatus FROM availability  WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
		SET _HCA = (SELECT HCA FROM availability WHERE roomID =_roomID ORDER BY ID DESC LIMIT 1);
        
        IF _dep_code = 'HCA' THEN -- department HCA depid 1
			SET _dep1lastCheck = (SELECT timecheck FROM availability  WHERE HCA = 1 ORDER BY ID DESC LIMIT 1);
            IF _dep1lastCheck is null then
				SET _dep1lastCheck = (SELECT NOW() - INTERVAL 1 HOUR);
            END IF;
            SET _dep1TimeOut = (SELECT TIMESTAMPDIFF(MINUTE, _dep1lastCheck, _timecheck));
			SET _HCA = true; 
			IF _HK = true THEN
				SET _roomStatus = true;
			END IF;
        
		ELSEIF _dep_code = 'HK' THEN -- department HK depid 2
			SET _dep2lastCheck = (SELECT timecheck FROM availability  WHERE HK = 1 ORDER BY ID DESC LIMIT 1);
            IF _dep2lastCheck is null then
				SET _dep2lastCheck = (SELECT NOW() - INTERVAL 1 HOUR);
            END IF;
            SET _dep2TimeOut = (SELECT TIMESTAMPDIFF(MINUTE, _dep2lastCheck, _timecheck));
			SET _HK = true;
			IF _HCA = true THEN
				SET _roomStatus = true;
			END IF;
		END IF;
        
        IF _dep_code = 'HCA' AND _dep1TimeOut >= _timeOutLimit  then -- if more then 5 minutes
			INSERT INTO availability (roomID,HCA,HK,timecheck,flag,roomStatus) VALUES(_roomID,_HCA,_HK,_timecheck,_flag,_roomStatus);
            commit;
		ELSEIF _dep_code = 'HK' AND _dep2TimeOut >= _timeOutLimit then -- if more then 5 minutes
			INSERT INTO availability (roomID,HCA,HK,timecheck,flag,roomStatus) VALUES(_roomID,_HCA,_HK,_timecheck,_flag,_roomStatus);
            commit;
		END IF;
        
        IF _HK = true AND _HCA = true AND _roomStatus = true THEN -- reset room availability to default(unavailabile)
			SET _HK = false;
			SET _HCA = false;
			SET _roomStatus = false;
			SET _timecheck = (SELECT NOW());
			INSERT INTO availability (roomID,HCA,HK,timecheck,flag,roomStatus) VALUES(_roomID,_HCA,_HK,_timecheck,_flag,_roomStatus);
            commit;
		END IF;  
	ELSE 
		IF _dep_code = 'HCA' THEN -- department HCA depid 1
			SET _HCA = true;

		ELSEIF _dep_code = 'HK' THEN -- department HK depid 2
			SET _HK = true;
			
		END IF; 
        INSERT INTO availability (roomID,HCA,HK,timecheck,flag,roomStatus) VALUES(_roomID,_HCA,_HK,_timecheck,_flag,_roomStatus);
        commit;
    END IF; 
  END IF; 
END $$
DELIMITER ;