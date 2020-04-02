import times
import strutils
import json
import httpclient
import db_sqlite

import
  jester

## This is a plugin for the nim web
## framework `Jester <https://github.com/dom96/jester>`__. It pulls location
## information from a database run by GeoJS using the IP address of the current
## web request and places it into a JSON document.
##
## The service is currently provided for free from https://www.geojs.io/
##
## HOW TO USE
## ==========
##
## 1. Install this library via nimble (``nimble install jestermmgeoip``).
##
## 3. Include the plugin ``location <- getGeoIP("sqlitedbname")`` at the top of your main ``routes``
##    or primary ``router``. This will enable the plugin for the whole web site.
##
## 4. In every route, the ``location`` JsonNode variable created by the plugin
##    is available.
##
## EXAMPLE
## =======
##
## .. code:: nim
##
##     import json
##     import jester
##     import jestergeoip
##     
##     proc namePage(loc: JsonNode): string =
##       if loc.hasKey("country_code"):
##         result = "Hello person in " & loc["country_code"].getStr
##       else:
##         result = "Hello stranger"
##     
##     routes:
##       plugin location <- getGeoIP("geojs.db")
##       get "/test":                  # get http://127.0.0.1/test
##         resp namePage(location)
##
## HOW IT WORKS
## ============
##
## When ever a request reaches the jester server, the sqlite db is checked
## for a legacy answer.
## If an old entry is found or no entry is found, a live API query is made and saved.
## The time-to-live for an entry is 30 days.
##
## If an error is encountered during an API lookup, the returned JsonNode will contain
## key of "error" and a value describing the failure.
##
## The answer is returned as a JsonNode object.
##
## For details about the JsonNode document, visit: https://www.geojs.io/docs/v1/endpoints/geo/
##

proc apiLookup(ip: string): JsonNode =
  let url = "https://get.geojs.io/v1/ip/geo/$1.json".format(ip)
  try:
    var client = newHttpClient(timeout=100) # 100ms
    let clientText = client.getContent(url)
    result = parseJson(clientText)
  except:
    result = newJObject()
    result["error"] = newJString(getCurrentExceptionMsg())


proc getGeoIP*(request: Request, response: ResponseData, sqliteDbFile: string): JsonNode =
  ## This is the psuedo-procedure to invoke to enable the library plugin.
  ##
  ## Once placed on the main router or ``routes``, the plugin is active on
  ## all page routes.
  ##
  ## It creates a new object variable that is available to all routes including
  ## any ``extend``-ed subrouters.
  # This is the "before" portion of the plugin. Do not run
  # this procedure directly, it is used by the plugin itself.
  #
  let ip = request.ip
  #
  # first, try to open db
  #
  let db = open(sqliteDbFile, "", "", "")
  if not db.tryExec(sql"""SELECT ip, date, json FROM cache LIMIT 1"""):
    echo "WARNING: attempting table creation in $1".format(sqliteDbFile)
    if not db.tryExec(sql"""CREATE TABLE cache (ip TEXT, date INT, json TEXT)"""):
      result = apiLookup(ip)
      echo "WARNING: failing to create `cache` table in sqlite db $1".format(sqliteDbFile)
      db.close()
      return
  #
  # now attempt cached lookup
  #
  let rightNow = getTime().toUnix
  let monthAgo = rightNow - (30 * 24 * 60 * 60)

  let row = db.getRow(sql"""SELECT date, json FROM cache WHERE ip = ?""", ip)
  var cacheTime: int64 = 0
  try:
    cacheTime = parseInt(row[0])
  except:
    discard
  # echo "DEBUG1 " & $row
  if row[0] == "":
    result = apiLookup(ip)
    # echo "DEBUG2a " & $result
    if result.hasKey("error"):
      echo "WARNING: GeoIP lookup failed due to: $1".format(result["error"])
      return
    let jsonText = $result
    if len(jsonText) < 900:
      try:
        db.exec(sql"""INSERT INTO cache (date, ip, json) VALUES (?, ?, ?)""", $rightNow, ip, jsonText)
      except:
        echo "WARNING: (m) sqlite error: $1".format(getCurrentExceptionMsg())
        return
    else:
      echo "WARNING: length of GeoIP lookup > 900"
  elif cacheTime < monthAgo:
    if not db.tryExec(sql"""DELETE FROM cache WHERE ip = ?""", ip):
      echo "WARNING: cache deletion failed on $1".format(ip)
    result = apiLookup(ip)
    # echo "DEBUG2b " & $result
    if result.hasKey("error"):
      echo "WARNING: GeoIP lookup failed due to: $1".format(result["error"])
      return
    let jsonText = $result
    if len(jsonText) < 900:
      try:
        db.exec(sql"""INSERT INTO cache (date, ip, json) VALUES (?, ?, ?)""", $rightNow, ip, jsonText)
      except:
        echo "WARNING: (o) sqlite error: $1".format(getCurrentExceptionMsg())
        return
    else:
      echo "WARNING: length of GeoIP lookup > 900"
  else:
    result = parseJson(row[1])
    # echo "DEBUG2c " & $result
  db.close()

