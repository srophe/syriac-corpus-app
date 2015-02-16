xquery version "3.0";
(:~
 :  geojson output for leafletjs maps 
 :)
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";

declare variable $type {request:get-parameter('type', '')};
declare variable $output {request:get-parameter('output', '')};

(:~
 : Calls geojson functions in geojson.xqm
 : Used by ajax call from browse maps in mapjson.js

:)
let $cache := 'test 4486'
return 
geo:json-transform((), $type, $output)

  