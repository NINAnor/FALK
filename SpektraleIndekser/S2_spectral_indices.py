#!/usr/bin/env python
# coding: utf-8

# Imports
import numpy as np
from grass_session import Session


# Read list of scenes and bands from i.sentinel.import output
register_output = '/mnt/falk-ns9693k/data/projects/FALK/reg_test.txt'
register = np.genfromtxt(register_output, delimiter='|', dtype=np.str)
register[:,0][0]

# Define mapset
mapset = 'S2_L2A_T32VNR_tcor'
# Define hadcoded map names
dem = 'dem_10m_nosefi_float@S2_L2A_T32VNR'
illu = 'illumination'

with Session(gisdb='/mnt/falk-ns9693k/data/NINA/grass', location='utm32n', mapset=mapset):
    import grass.script.core as gscript
    gscript.run_command('g.mapsets', operation='add', mapset='S2_L2A_T32VNR')
    for scene in register[:,0]:
        print(scene)
        if '_SCL_' in scene or '_60m' in scene:
            continue
        gscript.read_command('g.region', raster=scene)
        gscript.run_command('r.mapcalc', overwrite=True, verbose=True, expression='{0}_double={0}/10000.0'.format(scene))
        if '10m' not in scene:
            gscript.read_command('g.region', raster=dem)
            gscript.run_command('r.resamp.interp', method='bilinear',
                                input='{0}_double'.format(scene),
                                output='{0}_double'.format(scene.replace('20m','10m').replace('60m','10m')),
                                overwrite=True, verbose=True
                               )

with Session(gisdb='/mnt/falk-ns9693k/data/NINA/grass', location='utm32n', mapset=mapset):
    import grass.script.core as gscript
    print(gscript.read_command('g.region', raster=dem, flags='p'))
    for scene in set('_'.join(reg.split('_')[0:2]) for reg in register[:,0]):
        gscript.run_command('r.mask', flags='r')
        sunmask = gscript.parse_command('r.sunmask', overwrite=True, verbose=True,
                                        flags='sg', elevation=dem, timezone=0,
                                        year=scene[7:11], month=int(scene[11:13]),
                                        day=int(scene[13:15]), hour=int(scene[16:18]),
                                        minute=int(scene[18:20]), second=int(scene[20:22]))
        #gscript.run_command('r.sunhours', overwrite=True, verbose=True,
        #                    elevation=dem, azimuth=illu,
        #                    year=int(scene[7:11]), month=int(scene[11:13]), day=int(scene[13:15]),
        #                    hour=int(scene[16:18]), minute=int(scene[18:20]), second=int(scene[20:22]))
        z = 90. - float(sunmask['sunangleabovehorizon'])
        print(gscript.read_command('i.topo.corr', overwrite=True, verbose=True,
                            flags='i', basemap=dem, zenit=z, method='minnaert',
                            azimuth=float(sunmask['sunazimuth']), output=illu))
        maps = gscript.read_command('g.list', type='raster', pattern='{}*10m_double'.format(scene),
                                    exclude='*_SCL_*', separator=',', mapset='.').rstrip('\n') #.replace('@S2_L2A_T32VNR', '')
        mask_map = gscript.read_command('g.list', type='raster', pattern='{}*SCL_20m'.format(scene)).rstrip('\n')

        gscript.run_command('r.mask', overwrite=True, verbose=True,
                            raster=mask_map, maskcats='4 thru 7')
        print(maps)
        print(gscript.read_command('i.topo.corr', overwrite=True, verbose=True,
                            basemap=illu, zenith=z, flags='s',
                            input=maps, method='minnaert',
                            output='tcor'))

mapset = 'S2_L2A_T32VNR_VI'
with Session(gisdb='/mnt/falk-ns9693k/data/NINA/grass', location='utm32n', mapset=mapset):
    import grass.script.core as gscript
    print(gscript.read_command('g.region', raster=dem, flags='p'))
    gscript.run_command('g.mapsets', operation='add', mapset='S2_L2A_T32VNR_tcor')
    try:
        gscript.run_command('r.mask', flags='r')
    except:
        pass
    for scene in set('_'.join(reg.split('_')[0:2]) for reg in register[:,0]):
        # Compute NDWI
        gscript.run_command('i.vi', overwrite=True, verbose=True,
                            # red required until PR #179 is merged
                            red='tcor.{}_B04_10m_double'.format(scene),
                            green='tcor.{}_B03_10m_double'.format(scene),
                            nir='tcor.{}_B08_10m_double'.format(scene),
                            viname='ndwi', output='tcor.{}_NDWI_10m_double'.format(scene))
        # Compute NDVI
        gscript.run_command('i.vi', overwrite=True, verbose=True,
                            red='tcor.{}_B04_10m_double'.format(scene),
                            nir='tcor.{}_B08_10m_double'.format(scene),
                            viname='ndvi', output='tcor.{}_NDVI_10m_double'.format(scene))
        # Compute NDMI (currently not implemented in i.vi, therefore abusing ndvi here)
        gscript.run_command('i.vi', overwrite=True, verbose=True,
                            red='tcor.{}_B11_10m_double'.format(scene),
                            nir='tcor.{}_B08_10m_double'.format(scene),
                            viname='ndvi', output='tcor.{}_NDMI_10m_double'.format(scene))
        # Compute EVI
        gscript.run_command('i.vi', overwrite=True, verbose=True,
                            blue='tcor.{}_B02_10m_double'.format(scene),
                            red='tcor.{}_B04_10m_double'.format(scene),
                            nir='tcor.{}_B08_10m_double'.format(scene),
                            viname='evi', output='tcor.{}_EVI_10m_double'.format(scene))
        # Compute NDSI (currently not implemented in i.vi)
        gscript.run_command('r.mapcalc', overwrite=True, verbose=True,
                            expression='tcor.{0}_NDSI_10m_double=\
                            (tcor.{0}_B03_10m_double - tcor.{0}_B11_10m_double)/\
                            (tcor.{0}_B03_10m_double + tcor.{0}_B11_10m_double)'.format(scene))
        # Compute NDBI (currently not implemented in i.vi)
        gscript.run_command('r.mapcalc', overwrite=True, verbose=True,
                            expression='tcor.{0}_NDBI_10m_double=\
                            (tcor.{0}_B11_10m_double - tcor.{0}_B08_10m_double)/\
                            (tcor.{0}_B11_10m_double + tcor.{0}_B08_10m_double)'.format(scene))
        # Compute MNDWI (currently not implemented in i.vi)
        gscript.run_command('r.mapcalc', overwrite=True, verbose=True,
                            expression='tcor.{0}_MNDWI_10m_double=\
                            (tcor.{0}_B03_10m_double - tcor.{0}_B08_10m_double)/\
                            (tcor.{0}_B03_10m_double + tcor.{0}_B08_10m_double)'.format(scene))
