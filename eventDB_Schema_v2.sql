CREATE SCHEMA IF NOT EXISTS `eventDBv2` ;

USE eventDBv2;

DROP TABLE IF EXISTS `availability`;
DROP TABLE IF EXISTS `records`;
DROP TABLE IF EXISTS `emps`;
DROP TABLE IF EXISTS `deps`;
DROP TABLE IF EXISTS `rooms`;

CREATE table deps(
	depID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    dep_code char(5),
    description char(30)
);

CREATE table rooms(
	roomID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    description char(20)
);

CREATE table emps(
	empID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    uid char(30), 
    depID INTEGER,
    CONSTRAINT FK_EmpDepID FOREIGN KEY (depID) REFERENCES deps(depID)
);

CREATE table records(
	recordID INTEGER AUTO_INCREMENT PRIMARY KEY, 
	roomID INTEGER, 
    uid char(30), 
    timecheck timestamp,
    depID INTEGER,
    flag bool, 
    auth bool,
    CONSTRAINT FK_RecordRoomID FOREIGN KEY (roomID) REFERENCES rooms(roomID)
);

CREATE table availability(
	ID INTEGER AUTO_INCREMENT PRIMARY KEY, 
	roomID INTEGER, 
    hca bool,
    hsk bool,
    timecheck timestamp,
    flag bool, 
    roomStatus bool,
    CONSTRAINT FK_AvRoomID FOREIGN KEY (roomID) REFERENCES rooms(roomID)
);


INSERT INTO deps(dep_code,description) VALUES('HCA','Hospital Career');
INSERT INTO deps(dep_code,description) VALUES('HK','House Keeper');

INSERT INTO rooms(description) VALUES('S001');
INSERT INTO rooms(description) VALUES('S002');
INSERT INTO rooms(description) VALUES('S003');

INSERT INTO emps(uid,depID) VALUES('46,151,163,236,246',1);
INSERT INTO emps(uid,depID) VALUES('68,165,116,167,50',1);

INSERT INTO emps(uid,depID) VALUES('136,4,246,44,86',1);
INSERT INTO emps(uid,depID) VALUES('136,5,55,34,152',1);
INSERT INTO emps(uid,depID) VALUES('136,4,245,44,85',2);
INSERT INTO emps(uid,depID) VALUES('136,4,247,44,87',2);
INSERT INTO emps(uid,depID) VALUES('136,4,248,44,88',2);

