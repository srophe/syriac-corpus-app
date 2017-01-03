xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace rdfq="http://syriaca.org/rdfq" at "lib/tei2rdf.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cito = "http://purl.org/spar/cito";
declare namespace cnt = "http://www.w3.org/2011/content";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace geo = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace gn = "http://www.geonames.org/ontology#";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

let $rec := 
    for $r in collection('/db/apps/srophe-data')//tei:idno[. = 'http://syriaca.org/person/701/tei']
    return root($r)
return 
    transform:transform($rec//tei:TEI, doc('/db/apps/srophe/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="srophe-data/data"/>
        <param name="app-root" value="srophe"/>
        <param name="nav-base" value="http://syriaca.org/"/>
        <param name="base-uri" value="http://syriaca.org"/>
    </parameters>
    )
    