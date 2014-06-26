xquery version "3.0";

module namespace api="http://syriaca.org/api";

import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

import module namespace req="http://exquery.org/ns/request";

(: For output annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";

(: For interacting with the TEI document :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as JSON
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "")
    %output:media-type("application/json")
    %output:method("json")
function api:get-geo-json($type, $output) {
     geo:json-wrapper((), $type, $output)
};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as XML
  : Can change mime type to: application/vnd.google-earth.kmz, however this forces file download. 
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "kml")
    %output:media-type("application/xml")
    %output:method("xml")
function api:get-geo-kml($type, $output) {
     geo:kml-wrapper((), $type, $output)
};

