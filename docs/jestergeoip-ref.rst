jestergeoip Reference
==============================================================================

The following are the references for jestergeoip.






Procs, Methods, Iterators
=========================


.. _getGeoIP.p:
getGeoIP
---------------------------------------------------------

    .. code:: nim

        proc getGeoIP*(request: Request, response: ResponseData, sqliteDbFile: string): JsonNode =

    source line: `75 <../src/jestergeoip.nim#L75>`__

    This is the psuedo-procedure to invoke to enable the library plugin.
    
    Once placed on the main router or ``routes``, the plugin is active on
    all page routes.
    
    It creates a new object variable that is available to all routes including
    any ``extend``-ed subrouters.







Table Of Contents
=================

1. `Introduction to jestergeoip <https://github.com/JohnAD/jestergeoip>`__
2. Appendices

    A. `jestergeoip Reference <jestergeoip-ref.rst>`__
