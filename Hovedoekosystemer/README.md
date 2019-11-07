# Kart over hovedøkosystemer

Følgende filer dokumenterer prosesseringen:
- [anonin2train.sh](anonin2train.sh): Et shell skript som slår sammen, NiN og ANO data og genererer tilfeldige punkter som treningsdata
- [actinia_pc_hovedoekosystem.json](actinia_pc_hovedoekosystem.json): en actinia prosesskjede som består av en rekkefølge av databehandlings prosesser. Actina prosess beskrivelser kan genereres fra GRASS GIS kommandoer ved å legge til `--json`

actinia prosesskjeden kan kjøres fra alle maskiner med internet-tilgang og en REST klient, 
dvs. programvaret som kan sende spørringer til actinias REST-API.

På Linux er [`curl`](manpages.ubuntu.com/manpages/man1/curl.1.html) standardmessig installert og eksemplene nedenfor bruker `curl`.
`curl` er også tilgjengelig på Windows, f.eks. gjennom OSGeo4W. 
Alternativer er bla [ATOM sin REST klient](https://atom.io/packages/rest-client) eller 
[Advanced REST client](https://install.advancedrestclient.com).

Prosesseringskjeden actinia_pc_hovedoekosystem.json kan kjøres med følgende kommando:

`curl -k -u "actinia-gdi:actinia-gdi" -X POST -H "content-type: application/json" https://actinia-test.falk.sigma2.no/api/v1/locations/epsg32632/mapsets/hovedoekosystemer/processing_async -d @actinia_pc_hovedoekosystem.json`

Svaret kommando ovenfor vil inneholde en identifikator for prosessen, f.eks.: `resource_id-0ad71e05-52a9-4391-b8ba-8f1626d6fc84`, 
fordi det kan ta tid for prosessen å avslutte.

For å kalle opp informasjon om prosess-status kan man bruke det følgende kommando (der siste delen må erstattes med den gjeldenden resurs IDen):
`curl -k -u "actinia-gdi:actinia-gdi" -X GET -i "http://actinia-test.falk.sigma2.no/api/v1/resources/actinia-gdi/resource_id-0ad71e05-52a9-4391-b8ba-8f1626d6fc84"`
