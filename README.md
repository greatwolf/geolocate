# Geolocate

geolocate.lua takes one or more files as input and
outputs the corresponding longitude/latitude GPS coordinates
for each of those input files.

The input file should contain bssid(access point's MAC) and 
signal per line using this format:
```
BSSID <number> : <6-byte MAC address> Signal : <signal strength percent>%
```
Note that Google's geolocation API requires at least 2 sets of
BSSID data to work.

To have geolocate read from `stdin` use '-' as input filename.
For example, in Windows, the command below pipes the `stdout` from `netsh`
and feeds it into geolocate's `stdin`:

    netsh wlan show networks mode=bssid | geolocate.lua -

### Dependencies

The Lua script uses the following external lua libraries:

 - penlight's pretty `dump` module
 - dkjson for dealing with json messages
 - luasocket's http module for doing REST request
 - luasec's https module for handling ssl/tls communication.
 - luacom for displaying generated map page in browser w/o blocking
