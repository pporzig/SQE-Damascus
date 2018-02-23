#!/bin/bash

POSITIONAL=()

user="root"
password="$MYSQL_ROOT_PASSWORD"
host="$HOST"
database="$DATABASE"

set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "$database" ]; then
   database="SQE_DEV"
fi

if [ -z "$host" ]; then
   host="localhost"
fi

cwd=$(pwd)
echo Creating DB ${database}
mysql --host=${host} --user=${user} --password=${password} -e "CREATE DATABASE IF NOT EXISTS ${database} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"

echo Loading SQE DB Schema
mysql --host=${host} --user=${user} --password=${password} ${database} < /tmp/schema/SQE-Schema-current.sql &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep .1
done

echo Creating Default Users
mysql --host=${host} --user=${user} --password=${password} -e "INSERT INTO ${database}.user (user_id, user_name, pw, forename, surname, organization, email, registration_date) VALUES (1,'sqe_api','d60cd26b03a4607dc6c1db2514bbf20e59f751c98157c474ebfbeff3',NULL,NULL,NULL,NULL,'2017-08-20 18:59:50'), (5,'test','7872a74bcbf298a1e77d507cd95d4f8d96131cbbd4cdfc571e776c8a',NULL,NULL,NULL,NULL,'2017-07-28 17:18:15')"

for file in /tmp/tables/*.sql.gz; do
    printf "\rExtracting table: ${cwd}/${file}\n"
    gunzip $file &
    pid=$! # Process Id of the previous running command

    spin='-\|/'

    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r${spin:$i:1}"
      sleep .1
    done
done

for file in /tmp/geom_tables/*.sql.gz; do
    printf "\rExtracting geom-table: ${cwd}/${file}\n"
    gunzip $file &
    pid=$! # Process Id of the previous running command

    spin='-\|/'

    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r${spin:$i:1}"
      sleep .1
    done
done

for file in tmp/tables/*.sql; do
    table=${file%.sql}
    printf "\rLoading table: ${table##*/}\n"
    mysql --host=${host} --user=${user} --password=${password} --local-infile ${database} -e "SET FOREIGN_KEY_CHECKS=0;
    LOAD DATA LOCAL INFILE '$cwd/$file' INTO TABLE ${table##*/};
    SET FOREIGN_KEY_CHECKS=1;" &
    pid=$! # Process Id of the previous running command

    spin='-\|/'

    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r${spin:$i:1}"
      sleep .1
    done
done

## Load manually created tables with Geometry
printf "\rLoading table with geometry: artefact\n"
mysql --host=${host} --user=${user} --password=${password} --local-infile ${database} -e "SET FOREIGN_KEY_CHECKS=0;
LOAD DATA INFILE
'/tmp/geom_tables/artefact.sql'
INTO TABLE artefact (artefact_id, @var1, date_of_adding, commentary, sqe_image_id)
SET region_in_master_image = ST_GEOMFROMTEXT(@var1);
SET FOREIGN_KEY_CHECKS=1;" &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep .1
done

printf "\rLoading table with geometry: external_font_glyph\n"
mysql --host=${host} --user=${user} --password=${password} --local-infile ${database} -e "SET FOREIGN_KEY_CHECKS=0;
LOAD DATA INFILE
'/tmp/geom_tables/external_font_glyph.sql'
INTO TABLE external_font_glyph (external_font_glyph_id, external_font_id, unicode_char, @var1, width, height)
SET path = ST_GEOMFROMTEXT(@var1);
SET FOREIGN_KEY_CHECKS=1;" &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep .1
done

printf "\rLoading table with geometry: image_to_image_map\n"
mysql --host=${host} --user=${user} --password=${password} --local-infile ${database} -e "SET FOREIGN_KEY_CHECKS=0;
LOAD DATA INFILE
'/tmp/geom_tables/image_to_image_map.sql'
INTO TABLE image_to_image_map (image_to_image_map_id, image1_id, image2_id, @var1, @var2, rotation, map_type, validated, date_of_adding)
SET region_on_image1 = ST_GEOMFROMTEXT(@var1), region_on_image2 = ST_GEOMFROMTEXT(@var2);
SET FOREIGN_KEY_CHECKS=1;" &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep .1
done