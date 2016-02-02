#!/bin/sh

ROUND=$1
FILE=$2
DIR=$(pwd)
DB='db.db'
_pushround=$DIR/pushround.py

sqlite3 $DB "CREATE TABLE IF NOT EXISTS conversations (
		         filename text,
		         time timestamp primary key,
		         size integer,
		         s_port integer,
		         d_port integer,
		         s_ip text,
		         d_ip text,
		         comment text,
		         flags integer,
		         service integer, 
		         round integer, 
		         length integer,
		         foreign key(round) references rounds(num), 
		         foreign key(service) references service(id));"

sqlite3 $DB "CREATE TABLE IF NOT EXISTS rounds (
		         num integer primary key unique, 
		         s_time timestamp unique);"

sqlite3 $DB "INSERT INTO rounds (num, s_time) VALUES (0, datetime('now'))"

sqlite3 $DB "CREATE TABLE IF NOT EXISTS services (
		         id integer primary key unique,
		         name text unique, 
		         port integer unique);"

sqlite3 $DB "CREATE TABLE IF NOT EXISTS alerts (
		         id integer primary key,
		         timePassed timestamp,
		         timeFound timestamp,
		         regex text,
		         seen integer default 0,
		         round integer,
		         foreign key(timePassed) references conversations(time),
		         foreign key(regex) references regexes(regex)
		         foreign key(round) references rounds(num)
		         CONSTRAINT unq UNIQUE (timePassed, regex));"

sqlite3 $DB "CREATE TABLE IF NOT EXISTS regexes (
		         regex text unique,
		         lastRound integer default 0);"


if [ -z $ROUND ]; then
	ROUND=$(sqlite3 $DB "SELECT MAX(num) FROM rounds")
	ROUND+=1
fi

if [ -z $FILE ]; then
	FILE=$DIR/"staging/*.pcap*"
fi

mkdir -p $DIR/conversations/$ROUND
mkdir -p $DIR/staging

tcpflow -o conversations/$ROUND -T %T_%C_%a-%b_%A-%B -l $FILE

$_pushround conversations/$ROUND/"report.xml"
