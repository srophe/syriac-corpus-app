xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
import module namespace http="http://expath.org/ns/http-client";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(: http://syriaca.org/spear/119-13 :)

for $r in collection('/db/apps/srophe-data/data')//tei:div[@uri[. = request:get-parameter('id', '')]] 
return tei2rdf:rdf-output($r)
(:
for $r in collection('/db/apps/srophe-data/data')/tei:TEI[descendant::tei:idno[. = request:get-parameter('id', '')]] 
return tei2rdf:rdf-output($r)
:)