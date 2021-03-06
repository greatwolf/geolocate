--[[
  geolocate.lua takes one or more files as input and
  outputs corresponding longitude/latitude GPS coordinates
  for each of those input files.
  
  The input file should contain bssid(access point's MAC) and 
  signal per line using this format:
  
    BSSID <number> : <6-byte MAC address> Signal : <signal strength percent>%
  
  Note that Google's geolocation API requires at least 2 sets of
  BSSID data to work.
  
  To have geolocate read from stdin use '-' as input filename.
  eg. In Windows, piping stdout from netsh into geolocate:
  
    netsh wlan show networks mode=bssid | geolocate.lua -
]]

local dump = require 'pl.pretty'.dump
local json = require 'dkjson'
local https = require 'ssl.https'
local luacom = require 'luacom'

local url = "https://www.googleapis.com/geolocation/v1/geolocate"
local api_key = "AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw" -- google's chrome apikey
local function calc_rssi (signal_percent)
  local dbmin, dbmax = -100, -40
  local dbrange = dbmax - dbmin
  return signal_percent / 100 * dbrange + dbmin
end

local function geomac_fromfile (filename)
  -- read from stdin if "-" is given as filename
  local infile = filename == "-" and io.stdin or io.open (filename)
  local data = assert (infile):read "*a"
  local result = {}
  local pat = "BSSID %d%s+: (%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)%s+Signal%s+: (%d%d?)%%"
  for macaddr, signal in data:gmatch (pat) do
    table.insert (result, {macAddress = macaddr, signalStrength = calc_rssi (signal)})
  end
  return result
end

local pagetemplate =
[[<!DOCTYPE html>
<title>Geolocation Map</title>
<meta charset="utf-8">
<style>
#mapcanvas
{
  width:800px;
  height:600px;
  border:0;
}
</style>
<section>
  <h1>Geolocation Map</h1>
  <article>
    <h2>Your location:</h2>
    <p>
    <iframe id="mapcanvas"
      src="https://maps.google.com/maps?q=%f,%f&output=embed">
    </iframe>
    </p>
  </article>
</section>
]]
local function make_geopage(filename, lat, long)
  local geofile = assert (io.open(filename, 'w'))
  geofile:write(pagetemplate:format(lat, long))
end

local function sh(cmd)
  luacom.CreateObject "wscript.shell":run(cmd, 1, false)
end

local resp = {}
for i, macFile in ipairs (arg) do
  local post_data = json.encode {wifiAccessPoints = geomac_fromfile (macFile)}

  local r, _, h, s = https.request
  {
    method = "POST",
    url = url .. "?key=" .. api_key,
    headers = { ["content-type"] = "application/json", ["content-length"] = #post_data },
    source = ltn12.source.string (post_data),
    sink = ltn12.sink.table (resp),
  }
  resp = assert (json.decode (table.concat (resp)))

  macFile = macFile == "-" and "stdin" or macFile
  print (string.format ("[%d] %s:", i, macFile))
  dump (resp)
  local filename = "geolocate_" .. macFile .. ".html"
  make_geopage (filename, resp.location.lat, resp.location.lng)
  sh(filename)
end
