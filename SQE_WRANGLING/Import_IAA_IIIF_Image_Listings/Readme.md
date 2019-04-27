# Import IAA/NLI IIIF Image List

## Manual Add Listings

This program is run with `node manual-add-listing.js -f manual-data/4Q259-additions.csv`.  This will insert a new entry into the edition_catalog, image_catalog, and image_to_edition_catalog based on the information provided.  You should run this before the automated listing import script.

## Import Image Listings (Automated)

The automated listing import program is run with `python3 import_iaa_iiif.py -i NLI-IAA-data/iaa-iiif-files-19_3_2019.txt -d SQE_DEV`.  It reads in in a simple .txt file containing a list of filenames provided by the NLI for images that are now available on their iiif server.  We connect to the iiif server to get the info.json file for the image, which provides its width and height (we don't do this yet because the NLI server is too slow). Then we parse the filename, look up the IAA plate and fragment in the SQE database.  Finally we write a new SQE_image entry from the filename.  This requires a fresh instance of the SQE database to be running locally.

The script provides two files for debugging: `import_failed.txt`, and `import_succeeded.txt`.

Note: The NLI iiif server HTTP address is hardcoded on line 90.

## Seed Proxy server

The SQE project uses a proxy server with caching.  Run the program `node seed-cache` to seed the SQE proxy server cache with images/json files for all images in the database.  The exact file information is set on line 50: `${urls[count].url}/full/800,/0/default.jpg`.  Currently it is set to seed the 800px wide versions of the images (you should also seed 150px wide versions, and probably also the info.json files).
