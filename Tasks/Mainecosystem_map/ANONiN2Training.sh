#! /bin/bash

fkb_gpkg=/data/scratch/FKB_AR5.gpkg
training_gpkg=/data/scratch/Training_NiN.gpkg

NiN_2016_tmp=/data/scratch/NiN_2016_tmp.gpkg
NiN_2018_tmp=/data/scratch/NiN_2018_tmp.gpkg
ANO_2018_tmp=/data/scratch/ANO_2018_tmp.gpkg

AR5_klasser=/data/P-Prosjekter/15192119_falk-fjernmaling_landokologiske_grunnkart/Habitattypes/terrestrial_major_types_group_AR5.csv
NiN_klasser=/data/P-Prosjekter/15192119_falk-fjernmaling_landokologiske_grunnkart/Habitattypes/terrestrial_major_types_group.csv

mapset=/data/grass/ETRS_33N/p_FALK
# FKB
ogr2ogr -f GPKG "$fkb_gpkg" -nln fkb -sql "SELECT DISTINCT ON (a.gid) a.* FROM \"Topography\".\"Norway_FKB_AR5_polygons\" AS a, (SELECT geom FROM falk.bb) AS b WHERE ST_Intersects(a.geom_valid, b.geom)" "PG:host=gisdata-db.nina.no dbname=gisdata user=stefan.blumentrath"
ogr2ogr -update -append -f GPKG "$fkb_gpkg" -nln fkb_klasser -oo AUTODETECT_TYPE=YES "$AR5_klasser" terrestrial_major_types_group_AR5

ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN BETEGNELSE text;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN Mask integer;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN Training integer;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN usikkerhet_maskering integer;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN usikkerhet_training integer;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN hovedoekosystemkode integer;" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE fkb ADD COLUMN subtypekode integer;" "$fkb_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE fkb SET BETEGNELSE = (SELECT BETEGNELSE FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET Mask = (SELECT Mask FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET Training = (SELECT Training FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET usikkerhet_maskering = (SELECT usikkerhet_maskering FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET usikkerhet_training = (SELECT usikkerhet_training FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET hovedoekosystemkode = (SELECT hovedoekosystemkode FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE fkb SET subtypekode = (SELECT subtypekode FROM fkb_klasser AS k WHERE (fkb.arealressursArealtype = k.ARTYPE AND fkb.arealressursTreslag = k.ARTRESLAG AND fkb.arealressursSkogbonitet = ARSKOGBON AND fkb.arealressursGrunnforhold = ARGRUNNF));" "$fkb_gpkg"


# ANO
ogr2ogr -f GPKG "$ANO_2018_tmp" -nln tmp_ano_meta -sql "SELECT * FROM \"NiN_Naturtyper\" AS x LEFT JOIN \"o_NT\" AS y ON (x.naturtypeoid = y.naturtypeoid)" /data/P-Prosjekter/15192119_falk-fjernmaling_landokologiske_grunnkart/ANO/nin_2018_ano_20181107.gdb
ogr2ogr -update -append -f GPKG "$ANO_2018_tmp" -nln tmp_ano_geom -sql "SELECT * FROM \"NiN_Naturområder_5k\"" /data/P-Prosjekter/15192119_falk-fjernmaling_landokologiske_grunnkart/ANO/nin_2018_ano_20181107.gdb
ogr2ogr -update -append -f GPKG "$ANO_2018_tmp" -nln training_data -sql "SELECT geom
, g.ninid AS ninid
, CAST(NULL AS character(20)) AS md_aturtypekode
, CAST(NULL AS character(70)) AS md_naturtype
, m.hovedgruppekode AS ninhovedgruppekode
, m.hovedgruppebeskrivelse AS ninhovedgruppe
, m.hovedtypekode AS ninhovedtypekode
, m.hovedtypebeskrivelse AS ninhovedtype
, m.grunntypekode AS ningrunntypekode
, m.grunntypebeskrivelse AS ningrunntype
, CAST(NULL AS character(50)) AS ninkartleggingsenhet
, m.andel
, g.ektemosaikk AS mosaikk
, g.kartlagtdato AS kartleggingsdato
, g.kartleggingsmålestokk
, m.nivaa
, g.\"nøyaktighet\" AS noeyaktighet
, g.usikkerhet
, g.usikkerhetsbeskrivelse
, CAST(g.registreringsstatus AS character(50)) AS registreringsstatus
, g.prosjektid
, CAST(NULL AS character(50)) AS firma
, CAST(g.brukernavn AS character(50)) AS kartlegger
, CAST(NULL AS character(50)) AS omraadenavn
, g.merknad AS beskrivelse
, CAST(NULL AS character(80)) AS faktaark
, CAST('ANO Hovedbase 2018' AS character(30)) AS datakilde
FROM tmp_ano_geom AS g LEFT JOIN tmp_ano_meta AS m ON (g.naturomradeid = m.naturomradeid)" "$ANO_2018_tmp"

# NiN 2011-2016
ogr2ogr -f GPKG "$NiN_2016_tmp" -nln training_data -sql "SELECT SHAPE AS geom
, CAST(\"ninID\" AS character(15)) AS ninid
, CAST(NULL AS character(20)) AS md_aturtypekode
, CAST(NULL AS character(70)) AS md_naturtype
, ninHovedgruppe AS ninhovedgruppekode
, CAST(NULL AS character(100)) AS ninhovedgruppe
, ninHovedtype AS ninhovedtypekode
, CAST(NULL AS character(100)) AS ninhovedtype
, ninKartleggingsenhet AS ningrunntypekode
, CAST(NULL AS character(100)) AS ningrunntype
, CAST(NULL AS character(50)) AS ninkartleggingsenhet
, andel
, mosaikk
, \"kartlagtDato\" AS kartleggingsdato
, \"kartleggingsMaalestokk\" AS kartleggingsmaalestokk
, nivaa
, noeyaktighet
, CAST(NULL AS integer) AS usikkerhet
, CAST(NULL AS character(2000)) AS usikkerhetsbeskrivelse
, \"registreringsStatus\" AS registreringsstatus
, \"prosjektFKID\" AS prosjektid
, firma
, CAST(brukernavn AS character(25)) AS kartlegger
, CAST(NULL AS character(50)) AS omraadenavn
, b.beskrivelse AS beskrivelse
, CAST(NULL AS character(80)) AS faktaark
, CAST('NiN Hovedbase 2011-2016' AS character(30)) AS datakilde
FROM \"Naturomraade\" AS a  LEFT JOIN \"Naturomraadetype\" AS b ON (a.\"ninID\" = b.\"ninID\")" /data/R/GeoSpatialData/Habitats_biotopes/Norway_NiN_Miljodirektoratet/NiN_2011-2016_dump_20190819.gdb

# NiN 2018
ogr2ogr -f GPKG  "$NiN_2018_tmp" -nln training_data -dialect SQLite -sql "SELECT geom
, \"NiNID\" AS ninid
, \"Naturtypekode\" AS md_naturtypekode
, \"Naturtype\" AS md_naturtype
, CAST(NULL AS character(2)) AS ninhovedgruppekode
, \"Hovedøkosystem\" AS ninhovedgruppe
, CAST(NULL AS integer) AS ninhovedtypekode
, CAST(NULL AS character(100)) AS ninhovedtype
, CAST(NULL AS character(50)) AS ningrunntypekode
, CAST(NULL AS character(100)) AS ningrunntype
, \"NiNKartleggingsenheter\" AS ninkartleggingsenhet
, CAST(NULL AS integer) AS andel
, \"Mosaikk\" AS mosaikk
, CAST(datetime(\"Kartleggingsdato\" / 1000, 'unixepoch') AS date) AS kartleggingsdato
, CAST(NULL AS integer) AS kartleggingsmaalestokk
, CAST(NULL AS integer) AS nivaa
, \"Nøyaktighet\" AS noeyaktighet
, Usikkerhet AS usikkerhet
, Usikkerhetsbeskrivelse AS usikkerhetsbeskrivelse
, CAST(NULL AS integer) AS registreringsstatus
, \"Prosjektnavn\" AS prosjektid
, \"KartleggerFirma\" AS firma
, \"Kartlegger\" AS kartlegger
, \"Områdenavn\" AS omraadenavn
, CAST(NULL AS character(2000)) AS beskrivelse
, \"Faktaark\" AS faktaark
, CAST('NiN Hovedbase 2019' AS character(30)) AS datakilde
FROM \"OGRGeoJSON\"" /data/R/GeoSpatialData/Habitats_biotopes/Norway_NiN_Miljodirektoratet/Naturtyper_NiN_web_dump2019.gpkg

ogrinfo -sql "UPDATE training_data SET nivaa = substr(ninkartleggingsenhet, 1, instr(ninkartleggingsenhet, '_')-1)
, ninhovedgruppekode = substr(ninkartleggingsenhet, 4, 1)
, ninhovedtypekode = CAST(substr(ninkartleggingsenhet, 5, instr(ninkartleggingsenhet, '-') - 5) AS integer)
, ningrunntypekode = substr(ninkartleggingsenhet, instr(ninkartleggingsenhet, '-')+1)
WHERE ninkartleggingsenhet NOT LIKE '%,%';" "$NiN_2018_tmp"

ogr2ogr -f GPKG "$training_gpkg" -nln training_data "$ANO_2018_tmp" training_data
ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data "$NiN_2016_tmp" training_data
#ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data -sql "SELECT *, CAST('NiN Hovedbase 2011-2016' AS character(30)) AS datakilde FROM training_data" "$NiN_2016_tmp"
ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data "$NiN_2018_tmp" training_data

ogr2ogr -update -f GPKG "$training_gpkg" -nln klasser -oo AUTODETECT_TYPE=YES "$NiN_klasser" terrestrial_major_types_group


ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN ninhovedtypenumeriskkode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystem text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystemkode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystem_en text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtypekode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtype text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtype_kommentar text;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET ninhovedtypenumeriskkode = (SELECT ninhovedtypenumeriskkode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystem = (SELECT hovedoekosystem FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = (SELECT hovedoekosystemkode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystem_en = (SELECT hovedoekosystem_en FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtypekode = (SELECT subtypekode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtype = (SELECT subtype FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtype_kommentar = (SELECT subtype_kommentar FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 6000,
hovedoekosystem = 'Ferskvann',
hovedoekosystem_en = 'Freshwater',
subtypekode = 6100,
subtype = 'open' WHERE ninhovedgruppekode = 'L' AND (ninhovedtypekode != 4 OR ninhovedtypekode IS NULL);" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 6000,
hovedoekosystem = 'Ferskvann',
hovedoekosystem_en = 'Freshwater',
subtypekode = 6200,
subtype = 'vegetated' WHERE ninhovedgruppekode = 'L' AND ninhovedtypekode = 4;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 7000,
hovedoekosystem = 'Hav',
hovedoekosystem_en = 'Oceans and Fjords',
subtypekode = 7000,
subtype = 'open' WHERE ninhovedgruppekode = 'M';" "$training_gpkg"

if [ ! -d "$mapset" ] ; THEN
grass -c -e "$mapset"
fi

grass "$mapset"
v.in.ogr --overwrite --verbose input=/data/scratch/boundingboxes.gpkg layer=boundingboxes output=boundingbox where=gid=1
g.region -p vector=boundingbox align=dem_10m_nosefi_land@PERMANENT
v.in.ogr --overwrite --verbose -r input="$training_gpkg" layer=training_data output=NiN_ANO snap=0.01
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_hovedoekosystem use=attr attribute_column=hovedoekosystemkode label_column=hovedoekosystem where="hovedoekosystemkode IS NOT NULL AND (ningrunntypekode IS NOT NULL OR ninhovedgruppekode = 'M' OR ninhovedgruppekode = 'L')" memory=30000
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_subtype use=attr attribute_column=subtypekode label_column=subtype where="hovedoekosystemkode IS NOT NULL AND (ningrunntypekode IS NOT NULL OR ninhovedgruppekode = 'M' OR ninhovedgruppekode = 'L')" memory=30000

output_prefix=training_random
npoints=500
maps="hovedoekosystem subtype"
for map in $maps
do
output=${output_prefix}_$map
v.edit --quiet --overwrite --verbose map=$output tool=create
v.db.addtable map=$output columns="cat integer,value integer"
categories=$(r.stats --quiet Training_NiN_ANO_$map separator=';' -n -c)
    for cat in $categories
    do
        class_id=$(echo $cat | cut -f1 -d';')
        pixels=$(echo $cat | cut -f2 -d';')
        if [ $class_id -eq 0 ] ; then
            continue
        fi
        echo $class_id $pixels
        echo "$class_id = $class_id
* = NULL" | r.reclass --overwrite --quiet rules=- input=Training_NiN_ANO_$map output=tmp_Training_NiN_ANO_$map
        if [ $pixels -gt $npoints ] ; then
            r.random --overwrite --quiet -b input=tmp_Training_NiN_ANO_$map npoints=$npoints vector=tmp_rps
            v.db.renamecolumn --quiet map=tmp_rps column="value,value_double"
            v.db.addcolumn --quiet map=tmp_rps column="value integer"
            v.db.update --quiet map=tmp_rps column=value query_column=value_double
            v.db.dropcolumn map=tmp_rps column=value_double
            echo r.random
            v.info -c tmp_rps
        else
            r.to.vect --overwrite --quiet -b input=tmp_Training_NiN_ANO_$map output=tmp_rps type=point
            echo r.to.vect
            v.info -c tmp_rps
            v.db.dropcolumn --quiet map=tmp_rps column=label
        fi

        v.patch --overwrite -b -a -n -e input=tmp_rps output=${output}
    done
done

v.in.ogr --overwrite --verbose -r input="$fkb_gpkg" layer=fkb output=FKB_AR5 snap=0.01
v.to.rast --overwrite --verbose input=FKB_AR5 type=point,line,centroid,area output=Training_FKB_hovedoekosystem use=attr attribute_column=hovedoekosystemkode label_column=hovedoekosystem where="hovedoekosystemkode IS NOT NULL" memory=30000
v.to.rast --overwrite --verbose input=FKB_AR5 type=point,line,centroid,area output=Training_FKB_subtype use=attr attribute_column=subtypekode label_column=subtype where="subtypekode IS NOT NULL" memory=30000
v.to.rast --overwrite --verbose input=FKB_AR5 type=point,line,centroid,area output=Training_FKB_mask use=attr attribute_column=Mask where="Mask IS NOT NULL" memory=30000
