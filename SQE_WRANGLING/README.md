# Data Processing Utilities

This is a collection of low level utilities used to curate data for Scripta Qumranica Electronica.

Some of the scripts have their own readmes with further instructions.  Otherwise, look inside the script files themselves for information regarding usage.

## Dependencies

The dependencies for these utilities are many and varied due to the history of the project development.  You will need a working Node/NPM install including Yarn.  We also use Python3, so that should be installed (probably with pip3 for installing packages).  We also have a GO program, so you might as well install GO too.  If you are using these utilities, we assume you will know what these are and how to install them.

All (or most of) these scripts assume that you have the SQE database running on 127.0.0.1 at port 3307.  The easiest way to do this is to be running the Docker image of the latest database.  This can be found on Docker Hub at `qumranica / sqe-database:latest`, or you can just use the docker-compose file at the base of this repository to spin up a working instance: `docker-compose up -d`.

### NPM

Firstly, node dependencies can be installed by running `yarn` in the following folders:

* Import_IAA_IIIF_Image_Listings
* Reference_Matching
* Text_Extraction/sqe-text-extract
* Text_Extraction/sqe-text-to-image
* Import_IAA_Catalog_Listings
* Server_Diagnostics_and_Testing

### Python

The python programs here use python3.  You will need to install (with pip3?) the following dependencies:

* mysql.connector
* shapely
* tqdm

### Go

Yes, for some unknown reason we also use GO.  You should `go get` the following package(s):

* github.com/go-sql-driver/mysql
* gopkg.in/cheggaaa/pb.v1

## Loading Image Data

Many of the scripts here are used for importing image data into the SQE database.  This can be done from start to finish with the following procedure (you can clean from the database first with `node Server_Diagnostics_and_Testing/reset-image-data.js`):

1. Load the IAA reference data: `cd Import_IAA_Catalog_Listings`, `yarn load`.

2. Load the IAA/NLI iiif image listings: `cd ../Import_IAA_IIIF_Image_Listings`, `node manual-add-listing.js -f manual-data/4Q259-additions.csv`, `python3 import_iaa_iiif.py -i NLI-IAA-data/newlist22.11.18.csv -d SQE_DEV`.

3. Load the scroll links: `node ../Reference_Matching/link-scroll-ids.js`.

4. You probably should check the database now to make sure all refs are linked to a scroll_id:
```sql
SELECT DISTINCT	*
FROM edition_catalog
WHERE scroll_id IS NULL
```
>If you get no results, you may continue.  If you do get any results, you must fix the database before continueing (e.g., either by adding new scroll and scroll_data entries or manually adding the link from edition_catalog to the proper scroll_id).

5. Load the artefact masking data: `cd ../Import_TA_Artefact_Mask_Polygons`, `go run import-geojson.go` (This will take a pretty long time).

6. Automatically position the scroll artefacts: `python3 set-artefact-positions.py`.

Now you can try out the matching of QWB and IAA references with `cd ../Reference_Matching` then `node parse-sqe-cols.js`, `node parse-iaa-refs.js`, and `node match-refs.js` (or just use `yarn parse` to run all three programs at once).  Remember that this does not add anything to the database, but rather gives a CSV file, `QWB_IAA-cols.csv`, with the col_id and corresponding edition_catalog_id, which can be imported into the database and used as a lookup table.

## Text Extraction

Several handy utilities for working with text from the SQE database can be found in the `Text_Extraction` folder.  See the `Readme.md` there.

## Server Diagnostics

Any server diagnostics tools can be found in the folder `Server_Diagnostics_and_Testing` (see the Readme.md there for more information).  The only diagnostic tool there right now is one to test the response times of the IAA/NLI iiif server.

## Image Processing

The folder `Image_processing` contains two utilities: an old Perl script that will convert a folder full of JPG files to pyramidal TIFFs (see the notes in the script for dependencies); and a C+ program in the folder `Image-stitch` that uses OpenCV to stitch together tiled images.  Both of these are old and perhaps of little use to the project now.