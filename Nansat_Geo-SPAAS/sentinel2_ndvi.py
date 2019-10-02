#-------------------------------------------------------------------------------
# Name:        sentinel2_ndvi
# Purpose:      Calculating normalized difference vagtation index
#
# Author:      mohamed babiker
#
# Created:     01/07/2019
# Copyright:   (c) mohamed 2019
# Licence:      GNU General Public License v3 (GPLv3)
#-------------------------------------------------------------------------------
import time
start = time.time()
from nansat import Domain
from nansat import Nansat
import numpy


class S2NDVI(Nansat):
    '''
    A class for calculating normalized difference vegtation index NDVI
    '''


    def __init__(self, filename, domain=0):

        super().__init__(filename)
        if domain:
            self.reproject(domain)
        self.ndvi()



    # Define a function to calculate NDVI using band arrays for red, NIR bands

    def ndvi(self):

        B4 = self['B4']
        B8 = self['B8']
        NDVI = (B8 - B4)/(B8 + B4)
        self.add_band(array=NDVI, parameters={'name': 'NDVI', 'coordinate':'lat lon', 'grid_mapping': 'UTM_projection', 'long_name': 'normalized difference vegetation index', 'minmax' : '-1 1'})


    # define the export function and which bands to be exported , the basic band is NDVI but other bands can be added

    def export_ndvi(self, filename):
        bands = ['NDVI']
        self.export(filename, bands = bands)




# in put sentinel-2 file from the satellittdata.no

n1 = S2NDVI('http://nbstds.met.no/thredds/dodsC/NBS/S2B/2018/05/09/S2B_MSIL1C_20180509T105619_N0206_R094_T32VNR_20180509T112216.nc')

# output netcdf file name and the loction
n1.export_ndvi('../../../vagrant/shared/ndvi_20180509T105619.nc')

