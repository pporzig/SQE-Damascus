# Data-files
This repository houses datafiles and database dumps used in the SQE project
## Requirements
This package requires a running MariaDB instance (mysql may work as well) and the command line gzip tool (which most systems should already have).  It has been tested on Nix (Mac/Linux), but should work on windows as well with a bash shell.

## Installation
We have created a special install script to aid in the loading of the SQE database.  Install the package requirements, then clone this Github project to a local folder `cd` to that folder and run `import-db.sh -d <db username> -p <db password>`.  If the script does not run, you may need to make it executable `chmod +x import-db.sh`.

The script can take several switches:

* -u: your database username
* -p: your database password
* -d: the database you wish to load the data into (this defaults to "SQE")
* -h: the address of your database (this defaults to "localhost")

The script will fail on importing tables if you are trying to import them into a database that has those tables already populated with data.  This is intended for installation to a new database only, not for reloading data into an existing one.

## Package notes
Most of database parsing used to extract the database tables is handled automatically by our backup scripts.  The usage of a specialized backup system was necessitated by the large size of the database (a gzipped mysql dump exceeding the GitHub size quotas), and by the need to filter out private user data from our production database.  The system we are using to filter and export tables, however, does not play nicely with geometric data types, so we have handled those in a more manual fashion, which is why those tables appear in the /geom_tables folder.  Nevertheless, this distinction does not affect user installation.

## Running in Docker

Prerequisites is to have Docker installed on your machine.

Follow these steps, replacing the bits in square brackets `[]` with whatever values you'd like:

```bash
# clone this repository
git clone https://github.com/Scripta-Qumranica-Electronica/Data-files.git

# Cd into the directory
cd Data-files

# Build the image
docker build -t sqe-maria:latest .

# start the container
docker run --name [CONTAINER NAME] -e MYSQL_ROOT_PASSWORD=[ROOT PW] -d -p [YOUR MACHINE PORT]:3306 sqe-maria:latest

# import the data
docker exec -i [CONTAINER NAME] /tmp/import-docker.sh
```

At this point, you should be able to connect to the SQE DB locally at `localhost:[YOUR MACHINE PORT]` using using the root user and whatever password you input for `[YOUR MACHINE PORT]`.

# Legacy info (disregard)

## SQE-transitional-update-schema/data.sql.tar.gz
This is the latest update of the database schema and its data.  It will not work with the current master branch of the Scrollery Website.  The devel version that this works with will be pushed to master soon.

## SQE-SCHEMA_2017-12-23-13-30.tar.gz
This is the latest dump of the schema of the SQE database for our online platform.  Use this if you want to populate the database from scratch.

## SQE_2017-12-23-13-30.tar.gz
This is the latest dump of the SQE database for our online platform.  Use this if you are building a system for local development.

## SQE_A.sql
Deprecated, do not use.
This is a periodic dump of the SQE database.  It will be most useful to those working on development of Web based frontends.  It not currently fully populated.

## IAA-to-canonical-ref-index.json
This is a JSON representation of the Excel file for IAA plate and fragment correspondence to canonical references that Orit Rosengarten sent us from the IAA.  A few inconsistencies in that original Excel file have been cleaned up, but it is otherwise unaltered.
