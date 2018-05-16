CREATE SCHEMA IF NOT EXISTS `masterDBv2` ;

USE masterDBv2;

DROP TABLE IF EXISTS `availability`;
DROP TABLE IF EXISTS `records`;
DROP TABLE IF EXISTS `emps`;
DROP TABLE IF EXISTS `deps`;
DROP TABLE IF EXISTS `rooms`;

CREATE table deps(
	depID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    dep_code varchar(10),
    description varchar(30)
);

CREATE table rooms(
	roomID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    description varchar(15)
);

CREATE table emps(
	empID INTEGER AUTO_INCREMENT PRIMARY KEY, 
    uid varchar(50), 
    depID INTEGER,
    CONSTRAINT FK_EmpDepID FOREIGN KEY (depID) REFERENCES deps(depID)
);

CREATE table records(
	recordID INTEGER AUTO_INCREMENT PRIMARY KEY, 
	roomID INTEGER, 
    uid varchar(50), 
    timecheck timestamp,
    depID INTEGER,
    auth bool,
    CONSTRAINT FK_RecordRoomID FOREIGN KEY (roomID) REFERENCES rooms(roomID)
);

CREATE table availability(
	ID INTEGER AUTO_INCREMENT PRIMARY KEY, 
	roomID INTEGER, 
    HCA bool,
    HK bool,
    timecheck timestamp,
    roomStatus bool,
    CONSTRAINT FK_AvRoomID FOREIGN KEY (roomID) REFERENCES rooms(roomID)
);

INSERT INTO deps(dep_code,description) VALUES('HCA','Health Care Assistant');
INSERT INTO deps(dep_code,description) VALUES('HK','Housekeeper');
INSERT INTO deps(dep_code,description) VALUES('OTR','Other');

INSERT INTO rooms(description) VALUES('130');
INSERT INTO rooms VALUES(999,'Unassigned');

INSERT INTO emps(uid,depID) VALUES('46,151,163,236,246',3);
INSERT INTO emps(uid,depID) VALUES('68,165,116,167,50',1);

INSERT INTO emps(uid,depID) VALUES('136,4,246,44,86',1);
INSERT INTO emps(uid,depID) VALUES('136,5,55,34,152',1);
INSERT INTO emps(uid,depID) VALUES('136,4,245,44,85',2);
INSERT INTO emps(uid,depID) VALUES('136,4,247,44,87',2);
INSERT INTO emps(uid,depID) VALUES('136,4,248,44,88',2);
