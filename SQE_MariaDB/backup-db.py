# This leaves two folders full of files.
# Those files should all be gzipped and then
# the local instance of Data-files can be
# updated with the following bash command:
# for file in ./*; do if cmp -i 8 "$file" "/Users/path/to/Data-files/tables/$(basename "$file")"; then echo "$file is the same"; else cp -f "$file" "/path/to/Data-files/tables/$(basename "$file")"; fi; done
# That command should be run for the tables folder
# and for the geom_tables folder.

import mysql.connector
from mysql.connector.pooling import MySQLConnectionPool

dbconfig = {'host': "localhost",
            'port': "3307",
            'user': "root",
            'password': "none",
            'database': "SQE_DEV"
            }

cnxpool = MySQLConnectionPool(
    pool_name = "mypool",
    pool_size = 30,
    **dbconfig)

db = cnxpool.get_connection()
cursor = db.cursor()
sql = 'SHOW TABLES'
cursor.execute(sql)
result_set = cursor.fetchall()
path = '/tmp/backup/'
owner_tables = set()
non_owner_tables = set()
exclude_tables = {'user', 'user_sessions', 'sqe_session', 'artefact_shape', 'scroll_version',
                  'external_font_glyph', 'image_to_image_map', 'single_action', 'main_action',
                  'roi_shape'}
for result in result_set:
    if 'owner' in result[0]:
        owner_tables.add(result[0].replace("_owner", ""))
    else:
        non_owner_tables.add(result[0])
non_owner_tables = non_owner_tables - owner_tables

files = set()
for table in owner_tables:
    if table not in exclude_tables:
        print('Exporting table: %s' % table)
        query1 = 'SELECT ' + table + '.* INTO OUTFILE "' + path + 'tables/' + table + '.sql" FROM ' + table + ' JOIN ' \
                + table + '_owner USING(' + table + '_id) WHERE ' + table + '_owner.scroll_version_id < 1606'
        cursor.execute(query1)

    print('Exporting table: %s_owner' % table)
    query2 = 'SELECT * INTO OUTFILE "' + path + 'tables/' + table + '_owner.sql" FROM ' + table + '_owner WHERE ' \
             + table + '_owner.scroll_version_id < 1606'
    cursor.execute(query2)
    files.add(path + table + '.sql')
    files.add(path + table + '_owner.sql')
for table in non_owner_tables:
    if table not in exclude_tables:
        query3 = 'SELECT ' + table + '.* INTO OUTFILE "' + path + 'tables/' + table + '.sql" FROM ' + table
        cursor.execute(query3)
        files.add(path + table + '.sql')

# Custom commands for tables with geometry data:
# artefact, artefact_position, external_font_glyph, image_to_image_map
print('Exporting table: artefact_shape')
query4 = 'SELECT artefact_shape_id, artefact_id, id_of_sqe_image, ST_ASTEXT(artefact_shape.region_in_sqe_image) ' \
        'INTO OUTFILE "' + path + 'geom_tables/artefact_shape.sql" ' \
        'FROM artefact_shape ' \
        'JOIN artefact_shape_owner USING(artefact_shape_id) ' \
        'WHERE artefact_shape_owner.scroll_version_id < 1606'
cursor.execute(query4)

print('Exporting table: external_font_glyph')
query6 = 'SELECT external_font_glyph_id, external_font_id, unicode_char, ST_ASTEXT(path), width, height ' \
         'INTO OUTFILE "' + path + 'geom_tables/external_font_glyph.sql " ' \
         'FROM external_font_glyph '
cursor.execute(query6)

print('Exporting table: image_to_image_map')
query7 = 'SELECT image_to_image_map_id, image1_id, image2_id, ST_ASTEXT(region_on_image1), ' \
         'ST_ASTEXT(region_on_image2), rotation, map_type, validated, date_of_adding ' \
         'INTO OUTFILE "' + path + 'geom_tables/image_to_image_map.sql" ' \
         'FROM image_to_image_map '
cursor.execute(query7)

print('Exporting table: roi_shape')
query8 = 'SELECT roi_shape_id, ST_ASTEXT(roi_shape.path) ' \
        'INTO OUTFILE "' + path + 'geom_tables/roi_shape.sql" ' \
        'FROM roi_shape ' \
        'JOIN sign_char_roi USING(roi_shape_id) ' \
        'JOIN sign_char_roi_owner USING(sign_char_roi_id)' \
        'WHERE sign_char_roi_owner.scroll_version_id < 1606'
cursor.execute(query8)

print('Exporting table: scroll_version')
query9 = 'SELECT * INTO OUTFILE "' + path + 'tables/scroll_version.sql" ' \
            'FROM scroll_version WHERE scroll_version.user_id = 1'
cursor.execute(query9)

cursor.close()
db.close()
