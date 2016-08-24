Geolocate
=========

geolocate.lua takes one or more files as input and
outputs the corresponding longitude/latitude GPS coordinates
for each of those input files.

The input file should contain bssid(access point's MAC) and 
signal per line using this format:

  BSSID <number> : <6-byte MAC address> Signal : <signal strength percent>%

Note that Google's geolocation API requires at least 2 sets of
BSSID data to work.

To have geolocate read from stdin use '-' as input filename.
eg. In Windows, piping stdout from netsh into geolocate:

    netsh wlan show networks mode=bssid | geolocate.lua -
