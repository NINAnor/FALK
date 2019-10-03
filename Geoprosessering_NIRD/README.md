# Utvikling av en tilpasset Geo-prosesseringspakke for NIRD til økologiske analyser
Basert på kontainerne tilgjengelig i NIRD ble det skreddersydd to Geo-prosesserings og fjernmålings pakker som gir brukerne tilgang til de fleste og mest vanlige verktøyene innen dette feltet:

- GDAL / OGR
- QGIS
- GRASS GIS
- ESA Snap
- OTB
- diverse Python biblioteker (sentinelsat, scipy, numpy, scikit-learn)
- inkludert f.eks. pygbif for tilgang til økologiske data

Geo-prosesseringspakke er basert på
- [Jupyter Lab](./docker/jupyter/Dockerfile): Jupyter er et av de sentrale verktøyene i vitenskapelig databehandling og kan brukes med både Python, R, Julia mfl.
- [Ubuntu Linux Desktop via NoVNC](./docker/novnc/Dockerfile): Dette gir tilgang til en full Ubuntu Linux XFCE Desktop til mer grafisk interaksjon med infrastrukturen
