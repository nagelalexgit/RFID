
# coding: utf-8

# In[ ]:


#!/usr/bin/env python
# -*- coding: utf8 -*-

import RPi.GPIO as GPIO
import MFRC522
import signal
import time
import mysql
import sys

import mysql.connector as connector
import datetime

continue_reading = True

# Capture SIGINT for cleanup when the script is aborted
def end_read(signal,frame):
    global continue_reading
    print "Ctrl+C captured, ending read."
    continue_reading = False
    GPIO.cleanup()

def recordToDB():
    try:
        # connection to local PI DB
        myconn = connector.connect(user='root',passwpord='raspberry',host='localhost',database='eventDBv2')
    except:
        print("Connection fail !!!")
        pass
    else:
        cursor = myconn.cursor()
        # convert uid to sting
        uidasstring = ','.join(str(e) for e in uid)
        room_id = '3'
        cursor.execute("CALL recordToDb (%d,%s)" % (room_id, uidasstring))
        cursor.close()
        myconn.close()
        print("All OK!!!!")
           
def syncDB():
    syncAvalString = ("UPDATE availability set flag = true;")
    syncRecordsString = ("UPDATE records set flag = true;")
    try:
        # connection to local PI DB
        piDB = connector.connect(user='root', password='raspberry', host='localhost', database='eventDBv2')
    except:
        print("Connection fail !!!")
        pass
    else:
        piCur = piDB.cursor()
        piCur.execute("SELECT * from records where flag = false;")
        data = piCur.fetchall()
        piCur.execute("SELECT * from availability where flag = false;")
        data2 = piCur.fetchall()
        if data is not None:
            try:
                # connection to master db ip address is needed
                masterDB = connector.connect(user='root', password='raspberry', host='IP ADDRESS', database='masterDBv2')
            except:
                print("Connection fail !!!")
                pass
            else:
                masterCur = masterDB.cursor()
                for row in data:
                    syncRec = ("INSERT INTO records(roomID,uid,timecheck,depID,auth)VALUES ("+str(row[1])+",'"+str(row[2])+"','"+str(row[3])+"','"+str(row[4])+"',"+str(row[6])+");")
                    masterCur.execute(syncRec)
                    masterDB.commit()
                if data2 is not None:
                    for row in data2:
                        syncAval = ("INSERT INTO availability(roomID,hca,hsk,timecheck,roomStatus)VALUES ("+str(row[1])+",'"+str(row[2])+"','"+str(row[3])+"','"+str(row[4])+"',"+str(row[6])+");")
                        masterCur.execute(syncAval)
                        masterDB.commit()
                        masterCur.close()
                        masterDB.close()
                    
                piCur.execute(syncAvalString)
                piCur.execute(syncRecordsString)
                piDB.commit()

        piCur.close()
        piDB.close()
        print("All OK!!!!")

# Hook the SIGINT
signal.signal(signal.SIGINT, end_read)

# Create an object of the class MFRC522
MIFAREReader = MFRC522.MFRC522()

# Welcome message
print "Welcome to the MFRC522 data read example"
print "Press Ctrl-C to stop."

# This loop keeps checking for chips. If one is near it will get the UID and authenticate
while continue_reading:
    
    # Scan for cards    
    (status,TagType) = MIFAREReader.MFRC522_Request(MIFAREReader.PICC_REQIDL)

    # If a card is found
    if status == MIFAREReader.MI_OK:
        print "Card detected"
    
    # Get the UID of the card
    (status,uid) = MIFAREReader.MFRC522_Anticoll()

    # If we have the UID, continue
    if status == MIFAREReader.MI_OK:

        # Print UID
        # print "Card read UID: "+str(uid[0])+","+str(uid[1])+","+str(uid[2])+","+str(uid[3])
        print "Card read UID: "+(','.join(str(e) for e in uid))
        
        # This is the default key for authentication
        key = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]
        
        # Select the scanned tag
        MIFAREReader.MFRC522_SelectTag(uid)

        # Authenticate
        status = MIFAREReader.MFRC522_Auth(MIFAREReader.PICC_AUTHENT1A, 8, key, uid)
        
        # record to local PI DB script will not stop if no connection
        recordToDB()
        # sync to master DB script will not stop if no connection
        syncDB()
        
        
        # Check if authenticated
        if status == MIFAREReader.MI_OK:
            MIFAREReader.led1(True)
            MIFAREReader.MFRC522_Read(8)
            MIFAREReader.MFRC522_StopCrypto1()
            time.sleep(1)
            MIFAREReader.led1(False)
        else:
            MIFAREReader.led2(True)
            print "Authentication error"
            time.sleep(1)
            MIFAREReader.led2(False)


