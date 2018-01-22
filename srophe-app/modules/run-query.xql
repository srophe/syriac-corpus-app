xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


xrest:register-module(xs:anyURI('/db/apps/srophe/modules/rest.xqm'))