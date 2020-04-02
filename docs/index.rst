Introduction to jestergeoip
==============================================================================
ver 1.0.0

This is a plugin for the nim web
framework `Jester <https://github.com/dom96/jester>`__. It pulls location
information from a database run by GeoJS using the IP address of the current
web request and places it into a JSON document.

The service is currently provided for free from https://www.geojs.io/

HOW TO USE
==========

1. Install this library via nimble (``nimble install jestermmgeoip``).

3. Include the plugin ``location <- getGeoIP("sqlitedbname")`` at the top of your main ``routes``
   or primary ``router``. This will enable the plugin for the whole web site.

4. In every route, the ``location`` JsonNode variable created by the plugin
   is available.

EXAMPLE
=======

.. code:: nim

    import json
    import jester
    import jestergeoip

    proc namePage(loc: JsonNode): string =
      if loc.hasKey("country_code"):
        result = "Hello person in " & loc["country_code"].getStr
      else:
        result = "Hello stranger"

    routes:
      plugin location <- getGeoIP("geojs.db")
      get "/test":                  # get http://127.0.0.1/test
        resp namePage(location)

HOW IT WORKS
============

When ever a request reaches the jester server, the sqlite db is checked
for a legacy answer.
If an old entry is found or no entry is found, a live API query is made and saved.
The time-to-live for an entry is 30 days.

If an error is encountered during an API lookup, the returned JsonNode will contain
key of "error" and a value describing the failure.

The answer is returned as a JsonNode object.

For details about the JsonNode document, visit: https://www.geojs.io/docs/v1/endpoints/geo/




Table Of Contents
=================

1. `Introduction to jestergeoip <https://github.com/JohnAD/jestergeoip>`__
2. Appendices

    A. `jestergeoip Reference <jestergeoip-ref.rst>`__
