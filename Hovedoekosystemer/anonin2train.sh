#! /bin/bash

memory=4000

srcdir="/mnt/falk-ns9693k/data/Miljoedirektoratet"
workdir="/mnt/falk-ns9693k/data/projects/FALK"

# Input
ANO_2018_org="${srcdir}/nin_2018_ano_20181107.gdb"
NiN_2016_org="${srcdir}/NiN_2011-2016_dump_20190819.gdb"
NiN_2018_org="${srcdir}/Naturtyper_NiN_web_dump2019.gpkg"

# Bounding box
boundingbox=/data/scratch/boundingboxes.gpkg
bb_layer=boundingboxes
bb_where="gid=1"

# Output
fkb_gpkg="${workdir}/FKB_AR5.gpkg"
training_gpkg="${workdir}/Training_NiN.gpkg"

# tmp-data
NiN_2016_tmp="${workdir}/NiN_2016_tmp.gpkg"
NiN_2018_tmp="${workdir}/NiN_2018_tmp.gpkg"
ANO_2018_tmp="${workdir}/ANO_2018_tmp.gpkg"

# Klasser
AR5_klasser="${workdir}/terrestrial_major_types_group_AR5.csv"
NiN_klasser="${workdir}/terrestrial_major_types_group.csv"

training_where="hovedoekosystemkode IS NOT NULL AND (ningrunntypekode IS NOT NULL OR ninhovedgruppekode = 'M' OR ninhovedgruppekode = 'L') AND (usikkerhet != 1 OR usikkerhet IS NULL) AND (mosaikk != 1 OR mosaikk IS NULL)"
mapset="/data/grass/ETRS_33N/p_FALK"

# FKB
# Following line is used to generate FKB Geo package from DB in NINA
# ogr2ogr -f GPKG "$fkb_gpkg" -nln fkb -sql "SELECT DISTINCT ON (a.gid) a.* FROM \"Topography\".\"Norway_FKB_AR5_polygons\" AS a, (SELECT geom FROM falk.bb) AS b WHERE ST_Intersects(a.geom_valid, b.geom)" "PG:host=gisdata-db.nina.no dbname=gisdata user=stefan.blumentrath"

ogr2ogr -update -f GPKG "$fkb_gpkg" -nln fkb_klasser -oo AUTODETECT_TYPE=YES "$AR5_klasser" terrestrial_major_types_group_AR5

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
ogr2ogr -f GPKG "$ANO_2018_tmp" -nln tmp_ano_meta -sql "SELECT * FROM \"NiN_Naturtyper\" AS x LEFT JOIN \"o_NT\" AS y ON (x.naturtypeoid = y.naturtypeoid)" "${ANO_2018_org}"
ogr2ogr -update -append -f GPKG "$ANO_2018_tmp" -nln tmp_ano_geom -sql "SELECT * FROM \"NiN_Naturområder_5k\"" "${ANO_2018_org}"
ogr2ogr -update -append -f GPKG "$ANO_2018_tmp" -nln training_data -sql "SELECT geom
, g.ninid AS ninid
, CAST(NULL AS character(20)) AS md_naturtypekode
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
, CAST(NULL AS character(50)) AS tresjiktstetthet
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
, CAST(NULL AS character(20)) AS md_naturtypekode
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
, CAST(NULL AS character(50)) AS tresjiktstetthet
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
FROM \"Naturomraade\" AS a  LEFT JOIN \"Naturomraadetype\" AS b ON (a.\"ninID\" = b.\"ninID\")" "${NiN_2016_org}"

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
, CAST(CASE
WHEN \"NiNBeskrivelsesvariabler\" LIKE '%7RA-SJ_3%' THEN 'middels'
WHEN \"NiNBeskrivelsesvariabler\" LIKE '%7RA-SJ_4%' THEN 'høy'
WHEN \"NiNBeskrivelsesvariabler\" LIKE '%7RA-SJ_%' AND
     \"NiNBeskrivelsesvariabler\" NOT LIKE '%7RA-SJ_3%' AND
     \"NiNBeskrivelsesvariabler\" NOT LIKE '%7RA-SJ_4%' THEN 'lav'
END AS character(50)) AS tresjiktstetthet
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
FROM \"OGRGeoJSON\"" "${NiN_2018_org}"

ogrinfo -sql "UPDATE training_data SET nivaa = substr(ninkartleggingsenhet, 1, instr(ninkartleggingsenhet, '_')-1)
, ninhovedgruppekode = substr(ninkartleggingsenhet, 4, 1)
, ninhovedtypekode = CAST(substr(ninkartleggingsenhet, 5, instr(ninkartleggingsenhet, '-') - 5) AS integer)
, ningrunntypekode = substr(ninkartleggingsenhet, instr(ninkartleggingsenhet, '-')+1)
WHERE ninkartleggingsenhet NOT LIKE '%,%';" "$NiN_2018_tmp"

ogr2ogr -f GPKG "$training_gpkg" -nln training_data "$ANO_2018_tmp" training_data
ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data "$NiN_2016_tmp" training_data
#ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data -sql "SELECT *, CAST('NiN Hovedbase 2011-2016' AS character(30)) AS datakilde FROM training_data" "$NiN_2016_tmp"
ogr2ogr -update -append -f GPKG "$training_gpkg" -nln training_data "$NiN_2018_tmp" training_data

# Add boundingbox
ogr2ogr -update -append -f GPKG "$training_gpkg" -nln "$bb_layer" -where "$bb_where" "$boundingbox" "$bb_layer"

# Add classes
ogr2ogr -update -f GPKG "$training_gpkg" -nln klasser -oo AUTODETECT_TYPE=YES "$NiN_klasser" terrestrial_major_types_group

# Mark polygons in boundingbox
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN in_bb integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET in_bb = 0;" "$training_gpkg"
# ogrinfo -dialect SQLite -sql "UPDATE training_data SET in_bb = 1 WHERE fid IN (SELECT DISTINCT a.fid FROM training_data AS a JOIN $bb_layer AS b WHERE ST_Intersects(a.geom, b.geom));" "$training_gpkg"

# Add quality check columns
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN is_spatialy_well_defined integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN is_homogenous integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN is_plausible_classified integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN is_suitable_training text;" "$training_gpkg"

# Add habitat type columns
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN ninhovedtypenumeriskkode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystem text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystemkode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystem_en text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtypekode integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtype text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtype_kommentar text;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN subtypekode_korrigert integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN hovedoekosystemkode_korrigert integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN needs_2nd_opinion integer;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN prioritet_check integer;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN area_m2 integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET area_m2 = CAST(round(ST_Area(geom)) AS integer);" "$training_gpkg"

ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_subtypekode_idx ON training_data (subtypekode);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_datakilde_idx ON training_data (datakilde);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_area_m2_idx ON training_data (area_m2);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_in_bb_idx ON training_data (in_bb);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_prioritet_check_idx ON training_data (prioritet_check);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_mosaikk_idx ON training_data (mosaikk);" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET ninhovedtypenumeriskkode = (SELECT ninhovedtypenumeriskkode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystem = (SELECT hovedoekosystem FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = (SELECT hovedoekosystemkode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystem_en = (SELECT hovedoekosystem_en FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtypekode = (SELECT subtypekode FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtype = (SELECT subtype FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET subtype_kommentar = (SELECT subtype_kommentar FROM klasser AS k WHERE (training_data.ninhovedgruppekode = k.ninhovedgruppekode AND training_data.ninhovedtypekode = k.ninhovedtypekode));" "$training_gpkg"

ogrinfo -dialect SQLite -sql "ALTER TABLE training_data ADD COLUMN gid integer;" "$training_gpkg"
ogrinfo -dialect SQLite -sql "UPDATE training_data SET gid = CAST(fid AS integer);" "$training_gpkg"
ogrinfo -dialect SQLite -sql "CREATE INDEX IF NOT EXISTS training_gid_idx ON training_data (gid);" "$training_gpkg"


ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 6000,
hovedoekosystem = 'Ferskvann',
hovedoekosystem_en = 'Freshwater',
subtypekode = 6100,
subtype = 'Freshwater; open' WHERE ninhovedgruppekode = 'L' AND (ninhovedtypekode != 4 OR ninhovedtypekode IS NULL);" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 6000,
hovedoekosystem = 'Ferskvann',
hovedoekosystem_en = 'Freshwater',
subtypekode = 6200,
subtype = 'Freshwater; vegetated' WHERE ninhovedgruppekode = 'L' AND ninhovedtypekode = 4;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET hovedoekosystemkode = 7000,
hovedoekosystem = 'Hav',
hovedoekosystem_en = 'Oceans and Fjords',
subtypekode = 7000,
subtype = 'Ocean and fjords' WHERE ninhovedgruppekode = 'M';" "$training_gpkg"

ogrinfo -dialect SQLite -sql "UPDATE training_data SET prioritet_check = 0;" "$training_gpkg"

ogrinfo -dialect SQLite -sql "VACUUM FULL;" "$training_gpkg"

# Work around missing window function in SQLite < 3.25
codes=$(sqlite3 "$training_gpkg" "SELECT DISTINCT subtypekode FROM training_data WHERE subtypekode IS NOT NULL AND in_bb = 1 ORDER BY subtypekode;")
for c in $codes
do
  m_where="mosaikk = 0"
  for d in "ANO Hovedbase 2018" "NiN Hovedbase 2019" "NiN Hovedbase 2011-2016"
  do
    for n in $(sqlite3 "$training_gpkg" "SELECT DISTINCT noeyaktighet FROM training_data WHERE subtypekode = $c AND in_bb = 1 AND ${m_where} AND noeyaktighet > 2 ORDER BY noeyaktighet DESC;")
    do
      if [ "$n" ] ; then
        n_where="noeyaktighet = ${n}"
      else
        n_where="noeyaktighet IS NULL"
        echo $n_where
      fi
      for t in $(seq 1 $(sqlite3 "$training_gpkg" "SELECT COUNT(*) FROM training_data WHERE prioritet_check = 0 AND area_m2 > 0 AND subtypekode = $c AND datakilde = '$d' AND ${n_where} AND ${m_where} AND in_bb = 1;"))
      do
        echo "$c" "$t"
        #sqlite3 "$training_gpkg" "SELECT COUNT(*) FROM training_data AS t WHERE ninid IS NULL;"
        min_area=$(sqlite3 "$training_gpkg" "SELECT CAST(min(area_m2) AS integer) AS min_area FROM training_data WHERE prioritet_check = 0 AND area_m2 > 0 AND subtypekode = $c AND datakilde = '$d' AND ${n_where} AND ${m_where} AND in_bb = 1;")
        echo $min_area
        gid=$(sqlite3 "$training_gpkg" "SELECT gid FROM (SELECT gid FROM training_data AS t WHERE prioritet_check = 0 AND area_m2 > 0 AND subtypekode = $c AND datakilde = '$d' AND ${n_where} AND ${m_where} AND in_bb = 1 AND ${min_area} = area_m2 ORDER BY andel, kartleggingsdato LIMIT 1) AS x;")
        echo $gid
        rank=$(sqlite3 "$training_gpkg" "SELECT CAST(max(prioritet_check) + 1 AS integer) AS rank FROM training_data WHERE subtypekode = $c AND datakilde = '$d' AND ${n_where} AND ${m_where} AND in_bb = 1;")
        echo $rank
        ogrinfo -quiet -dialect SQLite -sql "UPDATE training_data SET prioritet_check = $rank WHERE gid = ${gid};" "$training_gpkg"
      done
    done
  done
done


if [ ! -d "$mapset" ] ; THEN
grass -c -e "$mapset"
fi

grass "$mapset"

# Get Bounding Box and set computatonal region
v.in.ogr --overwrite --verbose input="$boundingbox" layer="$bb_layer" output=boundingbox where="$bb_where"
g.region -p vector=boundingbox align=dem_10m_nosefi_land@PERMANENT


# Create MASK from FKB AR5 data
v.in.ogr --overwrite --verbose -r -t input="$fkb_gpkg" layer=fkb output=FKB_AR5_mask snap=0.01 where='"Mask" = 1'
v.category -t --overwrite --verbose input=FKB_AR5_mask type=boundary output=FKB_AR5_mask_boundary option=add
v.to.rast -d --overwrite --verbose input=FKB_AR5_mask_boundary type=line,boundary output=FKB_AR5_mask_boundary use=val memory=$memory
v.to.rast --overwrite --verbose input=FKB_AR5_mask type=boundary,centroid,area output=FKB_AR5_mask_area use=val memory=$memory
r.mapcalc --overwrite --verbose expression="FKB_AR5_mask=if(isnull(FKB_AR5_mask_area),if(isnull(FKB_AR5_mask_boundary),0,1),1)"
g.remove -f type=raster,vector pattern="FKB_AR5_mask_*"

# Import possible training data
v.in.ogr --overwrite --verbose -r input="$training_gpkg" layer=training_data output=NiN_ANO snap=0.01 where="$training_where"
v.db.addcolumn map=NiN_ANO columns="suitable_training integer"
v.db.update map=NiN_ANO column=suitable_training query_column=is_suitable_training
v.db.update map=NiN_ANO column=suitable_training value=9 where="is_suitable_training IS NULL"
v.db.update map=NiN_ANO column=suitable_training value=1 where="suitable_training = 2"

v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_hovedoekosystem use=attr attribute_column=hovedoekosystemkode label_column=hovedoekosystem memory=$memory
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_subtype use=attr attribute_column=subtypekode label_column=subtype memory=$memory

v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_suitability use=attr attribute_column=suitable_training memory=$memory
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_noeyaktighet use=attr attribute_column=noeyaktighet where="$training_where" memory=$memory
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_usikkerhet use=attr attribute_column=usikkerhet where="$training_where" memory=$memory
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_kartleggingsmalestokk use=attr attribute_column=kartleggingsmC_lestokk where="$training_where" memory=$memory
v.to.rast --overwrite --verbose input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_mosaikk use=attr attribute_column=mosaikk where="$training_where" memory=$memory

# Check pixel distribution
r.stats -cN input=Training_NiN_ANO_subtype,Training_NiN_ANO_suitability,Training_NiN_ANO_noeyaktighet,Training_NiN_ANO_mosaikk
r.stats -cN input=Training_NiN_ANO_hovedoekosystem,Training_NiN_ANO_suitability,Training_NiN_ANO_noeyaktighet,Training_NiN_ANO_mosaikk

v.overlay --overwrite --verbose ainput=NiN_ANO@p_FALK binput=FKB_AR5@p_FALK operator=and output=NiN_ANO_FKB
# Exclude data with high tree cannopy cover from training dataset for open areas
# Prioritize Training data
# Exclude all unsuitable
p1_where="suitable_training != 0 AND subtypekode_korrigert IS NULL AND ((hovedoekosystemkode != 3000 AND (tresjiktstetthet IS NULL OR tresjiktstetthet IN ('lav', 'ingen trær'))) OR hovedoekosystemkode = 3000) AND datakilde = 'ANO Hovedbase 2018'"
p2_where="suitable_training = 1 AND subtypekode_korrigert IS NULL AND (noeyaktighet IN (3, 4) OR hovedoekosystemkode = 4000) AND ((hovedoekosystemkode != 3000 AND (tresjiktstetthet IS NULL OR tresjiktstetthet IN ('lav', 'ingen trær'))) OR hovedoekosystemkode = 3000) AND datakilde = 'NiN Hovedbase 2019'"
p3_where="(suitable_training > 1 AND subtypekode_korrigert IS NULL AND (noeyaktighet IN (3, 4) OR hovedoekosystemkode = 4000) AND ((hovedoekosystemkode != 3000 AND (tresjiktstetthet IS NULL OR tresjiktstetthet IN ('lav', 'ingen trær'))) OR hovedoekosystemkode = 3000) AND datakilde = 'NiN Hovedbase 2019') OR (suitable_training = 1 AND (noeyaktighet IN (3, 4) OR hovedoekosystemkode = 4000) AND ((hovedoekosystemkode != 3000 AND (tresjiktstetthet IS NULL OR tresjiktstetthet IN ('lav', 'ingen trær'))) OR hovedoekosystemkode = 3000) AND datakilde = 'NiN Hovedbase 2011-2016')"
p4_where="(suitable_training > 1 AND subtypekode_korrigert IS NULL AND (noeyaktighet = 4 OR hovedoekosystemkode = 4000) AND ((hovedoekosystemkode != 3000 AND (tresjiktstetthet IS NULL OR tresjiktstetthet IN ('lav', 'ingen trær'))) OR hovedoekosystemkode = 3000) AND datakilde = 'NiN Hovedbase 2011-2016')"
v.to.rast --overwrite --q input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_p1 use=attr attribute_column=hovedoekosystemkode label_column=hovedoekosystem where="$p1_where" memory=$memory
v.to.rast --overwrite --q input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_p2 use=attr attribute_column=hovedoekosystemkode where="$p2_where" memory=$memory
v.to.rast --overwrite --q input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_p3 use=attr attribute_column=hovedoekosystemkode where="$p3_where" memory=$memory
v.to.rast --overwrite --q input=NiN_ANO type=point,line,centroid,area output=Training_NiN_ANO_p4 use=attr attribute_column=hovedoekosystemkode where="$p4_where" memory=$memory
r.stats -cN input=Training_NiN_ANO_p1,Training_NiN_ANO_p2,Training_NiN_ANO_p3,Training_NiN_ANO_p4
# 1. ANO
# 2. NiN 2018
# 3. NiN 2011 - 2016
# FKB for hav, ferskvann
# Overlay FKB and NiN???
output_prefix=training_random
npoints=1000
maps=hovedoekosystem # "hovedoekosystem subtype"
for map in $maps
do
echo "x|y|id|${map}|priority"> /tmp/training_points_$map

for p in 1 2 3 4
do
output=${output_prefix}_p$p
r.sample.category --overwrite --verbose input=Training_NiN_ANO_p${p} npoints=$npoints output=$output
v.db.addcolumn map=$output columns="priority integer"
v.db.update map=$output column=priority value=$p
v.out.ascii input=training_random_p$p type=point columns=training_nin_ano_p${p},priority format=point >> /tmp/training_points_$map
done
#samples=$(db.select sql="SELECT Training_NiN_ANO_p${p}, COUNT(*) FROM $output GROUP BY Training_NiN_ANO_p${p}")
v.in.ascii --overwrite --verbose input=/tmp/training_points_$map output=${output_prefix}_$map skip=1 columns="x integer,y integer,id integer,${map} integer,priority integer"
rm /tmp/training_points_$map
done
g.remove -i -f type="raster,vector" pattern="*_p*"

v.to.rast --overwrite --verbose input=FKB_AR5 type=point,line,centroid,area output=Training_FKB_hovedoekosystem use=attr attribute_column=hovedoekosystemkode label_column=hovedoekosystem where="hovedoekosystemkode IS NOT NULL" memory=30000
v.to.rast --overwrite --verbose input=FKB_AR5 type=point,line,centroid,area output=Training_FKB_subtype use=attr attribute_column=subtypekode label_column=subtype where="subtypekode IS NOT NULL" memory=30000
v.to.rast --overwrite --verbose input=FKB_AR5 type=boundary,centroid,area output=Training_FKB_mask use=attr attribute_column=Mask where="Mask IS NOT NULL" memory=30000
