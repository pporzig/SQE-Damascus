import mysql.connector
from mysql.connector.pooling import MySQLConnectionPool

dbconfig = {'host': "localhost",
            'user': "bronson",
            'password': "none",
            'database': "SQE"
            }

cnxpool = mysql.connector.pooling.MySQLConnectionPool(pool_name = "mypool",
                                                      pool_size = 30,
                                                      **dbconfig)

db = cnxpool.get_connection()
cursor = db.cursor()
sql = 'SHOW TABLES'
cursor.execute(sql)
result_set = cursor.fetchall()
path = '/Users/bronson/sqe-mysql-backup/'
owner_tables = set()
non_owner_tables = set()
exclude_tables = {'user', 'user_sessions', 'sqe_session', 'artefact', 'artefact_position', 'scroll_version',
                  'external_font_glyph', 'image_to_image_map', 'single_action', 'main_action'}
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
                + table + '_owner USING(' + table + '_id) WHERE ' + table + '_owner.scroll_version_id = 1'
        cursor.execute(query1)

    print('Exporting table: %s_owner' % table)
    query2 = 'SELECT * INTO OUTFILE "' + path + 'tables/' + table + '_owner.sql" FROM ' + table + '_owner WHERE ' \
             + table + '_owner.scroll_version_id = 1'
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
print('Exporting table: artefact')
query4 = 'SELECT artefact_id, ST_ASTEXT(artefact.region_in_master_image), owner_id, date_of_adding, commentary, sqe_image_id ' \
         'INTO OUTFILE "' + path + 'geom_tables/artefact.sql" ' \
         'FROM artefact ' \
         'JOIN artefact_owner USING(artefact_id) ' \
         'WHERE artefact_owner.scroll_version_id = 1'
cursor.execute(query4)

print('Exporting table: artefact_position')
query5 = 'SELECT artefact_position_id, artefact_id, ST_ASTEXT(position_in_scroll), z_index, ' \
         'rotation, ST_ASTEXT(artefact_in_scroll), scroll_id, commentary, date_of_adding ' \
         'INTO OUTFILE "' + path + 'geom_tables/artefact_position.sql" ' \
         'FROM artefact_position ' \
         'JOIN artefact_position_owner USING(artefact_position_id) ' \
         'WHERE artefact_position_owner.scroll_version_id = 1'
cursor.execute(query5)

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

print('Exporting table: scroll_version')
query8 = 'SELECT * INTO OUTFILE "' + path + 'tables/scroll_version.sql" ' \
            'FROM scroll_version WHERE scroll_version.version = 0'
cursor.execute(query8)

cursor.close()
db.close()
