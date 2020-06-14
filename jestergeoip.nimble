# Package

version      = "1.0.1"
author       = "John Dupuy"
description  = "A plugin for Jester that gets location data from an IP address using a GeoIP library service (currently GeoJS)."
license      = "MIT"
srcDir       = "src"
skipExt      = @["rst"]

# Dependencies

requires "nim >= 1.2.0", "jesterwithplugins >= 0.5.0"
