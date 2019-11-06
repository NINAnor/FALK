# FALK specific documentation and code for [Nansat](https://nansat.readthedocs.io/en/latest/) and [Geo-SPAAS](https://github.com/nansencenter/django-geo-spaas)

[sentinel2_ndvi.ipynb](sentinel2_ndvi.ipynb): An example for for computing NDVI from Sentinel2-data obtained from NBS with nansat in https://osgeo-notebook.falk.sigma2.no 
[sentinel2_ndvi.py](sentinel2_ndvi.py): A python module for computing NDVI from Sentinel2-data obtained from NBS with nansat.

[Nansat introduction.ipynb](https://github.com/NINAnor/FALK/blob/master/Nansat_Geo-SPAAS/Nansat%20introduction.ipynb): is simple introduction to nansat, in the following steps:
Open a raster file in tif format using nansat,
Read information about the data (METADATA) that include the number of bands etc.
Reading the actual data,
Checking what kind of data, we have, 
Make a figure and plot from the data to know from where it was taken.

[Prepare a nice figure with nansat](https://github.com/NINAnor/FALK/blob/master/Nansat_Geo-SPAAS/Nansat%20Use%20Case%2001.ipynb): in this notebook figure will be prepared to be used in presentation or papers following these steps: get location of the data to be used (nansat test data). Import all tools for the NANSAT package. read the satellite data with nansat. Define the grid of the region of interest, then reproject and resample the data according to that. Write the bands of interest to a figure e.g png. Display png in Ipython.

[Colocate different data with Nansat](https://github.com/NINAnor/FALK/blob/master/Nansat_Geo-SPAAS/Nansat_use_case2.ipynb): in this notebook different dates of MODIS/Aqua chlorophyll data from the north sea were used. The data are stored in local folder (download the data first). Read the data using nansat (data is in HDF format). Define the domain and the area of interest. Reproject both images and get matrix reprojected chorophyll, and mask using the MOD44 file. Plot the two images to see the difference. Use numpy to replace negative values (clouds) by NAN. Find the difference between the two images by subtraction. Plot the result image and also make a graph from the result. 
