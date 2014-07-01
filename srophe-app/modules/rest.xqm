xquery version "3.0";

module namespace api="http://syriaca.org/api";

import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";
import module namespace config="http://syriaca.org//config" at "config.xqm";

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
function api:get-geo-json($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/json; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     geo:json-wrapper((), $type, $output) 
) 

};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as XML
  : Can change mime type to: application/vnd.google-earth.kmz, however this forces file download.
      %output:encoding("UTF-8")
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "kml")
    %output:media-type("application/xml")
    %output:method("xml")
function api:get-geo-kml($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     geo:kml-wrapper((), $type, $output) 
) 
};

(:~
  : Use resxq to format urls for tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/{$collection}/{$id}/tei")
    %output:media-type("text/xml")
    %output:method("xml")
function api:get-tei($collection as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     api:get-tei-rec($collection, $id)
     )
}; 

(:~
  : Use resxq to format urls for tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
  NEEDS lots of work on atom.xqm but should be able to move away from current setup
:)
declare 
    %rest:GET
    %rest:path("/{$collection}/{$id}/atom")
    %output:media-type("text/xml")
    %output:method("xml")
function api:get-rec-atom($collection as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     api:get-tei-rec($collection, $id)
     )
}; 


(:~
 : Returns tei record for syriaca.org subcollections
:)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()*{
    let $collection-name := if($collection = 'place') then 'places' else $collection
    let $path := ($config:app-root || '/data/' || $collection || '/tei/' || $id ||'.xml')
    return doc($path)
};