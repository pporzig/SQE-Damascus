#!/usr/bin/python3

# This reads in a simple .txt file containing a list of filenames.
# The IAA's iiif server code address is hardcoded on line 90. 
# We grab the info.json file for the image and get width and height. 
# Then we parse the filename, look up the plate and fragment in the DB. 
# Finally we write a new SQE_image entry from the filename.
import sys, getopt
import urllib.request, json
import mysql.connector
import re
from mysql.connector.pooling import MySQLConnectionPool

def main(argv):
    inputfile = ''
    database = ''
    try:
        opts, args = getopt.getopt(argv,"hi:d:",["ifile=","db="])
    except getopt.GetoptError:
        print('import_iaa_iiif.py -i <inputfile> -d <database_name>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('import_iaa_iiif.py -i <inputfile> -d <database_name>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-d", "--db"):
            database = arg
    print('Input file is', inputfile)
    print('Database is', database.rstrip(' '))

    dbconfig = {'host': "localhost",
                'port': "3307",
                'user': "root",
                'password': "none",
                'database': database
                }

    cnxpool = MySQLConnectionPool(
        pool_name = "mypool",
        pool_size = 30,
        **dbconfig)

    db = cnxpool.get_connection()
    cursor = db.cursor()
    unprocessed = []
    exclude = ['1094','1095','1096','1097','1098','1099','1100','1101','1102','1103','1104','1106','1107','998']
    lines = [line.rstrip('\n') for line in open(inputfile)]
    for line in lines:
        print(line)
        m = re.search(r'P([\*]{0,1}\d{1,5})(\_\d|[a-zA-Z]{0,1}).*Fg(\d{1,5}).*-(R|V)-.*(LR445|LR924|ML445|ML924|_026|_028)', line)
        if m is not None and len(m.groups(0)) == 5:
            plate = str(m.group(1)) + m.group(2).replace('_', '/')
            fragment = str(m.group(3)).lstrip('0')
            side = '0'
            if ('R' in str(m.group(4))):
                side = '0'
            else:
                side = '1'
            wvStart = '0'
            wvEnd = '0'
            type = '1'
            master = '0'
            if ('445' in str(m.group(5))):
                wvStart = '445'
                wvEnd = '704'
                type = '0'
                master = '1'
            elif ('26' in str(m.group(5))):
                wvStart = '924'
                wvEnd = '924'
                type = '2'
            elif ('28' in str(m.group(5))):
                wvStart = '924'
                wvEnd = '924'
                type = '3'
            elif ('924' in str(m.group(5))):
                wvStart = '924'
                wvEnd = '924'
            sql = 'SELECT image_catalog_id, edition_catalog_id FROM image_catalog '\
                'JOIN image_to_edition_catalog USING(image_catalog_id) '\
                'WHERE institution = "IAA" '\
                'AND catalog_number_1 = "' + plate + '" '\
                'AND catalog_number_2 = "' + fragment + '" '\
                'AND catalog_side = ' + side + ';'
            cursor.execute(sql)
            result_set = cursor.fetchall()
            print(plate, fragment, side, result_set)
            # I should perhaps have an else clause following 
            # this conditional that sticks images without edition 
            # cataloguing data into 4Q9999 or something like that.
            if (cursor.rowcount != 0):
                imageCatalogId = str(result_set[0][0])
                editionCatalogId = str(result_set[0][1])
                print(plate, fragment, side, wvStart, wvEnd, type, imageCatalogId, editionCatalogId)
                if any(x not in plate for x in exclude):
                    sql = 'INSERT IGNORE INTO SQE_image '\
                    '(image_urls_id, filename, native_width, native_height, dpi, type, wavelength_start, wavelength_end, is_master, image_catalog_id, edition_catalog_id) '\
                    'VALUES(2,"' + line + '",7216,5412,1215,' + type +',' + wvStart + ',' + wvEnd + ',' + master + ',' + imageCatalogId + ',' + editionCatalogId + ');'
                    cursor.execute(sql)
                    db.commit()
                    print('New id:', cursor.lastrowid)
        else:
            unprocessed.append(line)
    cursor.close()
    db.close()
    print(unprocessed)


if __name__ == "__main__":
   main(sys.argv[1:])