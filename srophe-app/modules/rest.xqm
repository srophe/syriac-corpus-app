xquery version "3.0";

module namespace api="http://syriaca.org/api";

import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";
import module namespace feed="http://syriaca.org//atom" at "lib/atom.xqm";
import module namespace search="http://syriaca.org//search" at "search/search.xqm";
import module namespace common="http://syriaca.org//common" at "search/common.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

import module namespace config="http://syriaca.org//config" at "config.xqm";

import module namespace req="http://exquery.org/ns/request";

(: For output annotations  :)
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
    (:%output:method("json"):)
function api:get-geo-json($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/json; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     xqjson:serialize-json(geo:json-wrapper((), $type, $output))
) 

};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as KML
      %output:encoding("UTF-8")
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "kml")
    %output:media-type("application/vnd.google-earth.kmz")
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
  : Use resxq to format urls for a search API
  : Results are output as atom
  : @param $q simple kewyord string passed from uri 
  : @param $place limit search to tei:placeName
  : @param $person limit search to  tei:persName
  : @param $start where to start results list start
  : @param $perpage number of results per page
:)
declare
    %rest:GET
    %rest:path("/srophe/api/search")
    %rest:query-param("q", "{$q}", "") 
    %rest:query-param("place", "{$place}", "")
    %rest:query-param("person", "{$person}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("text/xml")
    %output:method("xml")
function api:search-api($q as xs:string*,$place as xs:string*,$person as xs:string*, $start as xs:integer*, $perpage as xs:integer*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
  </http:response> 
</rest:response>,
let $hits := util:eval(search:search-api($q,$place,$person))
let $total := count($hits)
return feed:build-atom-feed($hits, $start, $perpage, $q, $total)
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
  : NOTE this does means the above no longer works...
  : Use resxq to format urls for spear tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML

declare 
    %rest:GET
    %rest:path("/spear/{$type}/{$id}/tei")
    %output:media-type("text/xml")
    %output:method("xml")
function api:get-tei($type as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     api:get-spear-tei($type, $id)
     )
}; 
:)

(:~
  : Return atom feed for single record
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/{$collection}/{$id}/atom")
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-record($collection as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     feed:get-entry(api:get-tei-rec($collection, $id))
    )
}; 

(:~
  : Return atom feed for syrica.org subcollection
  : @param $collection syriaca.org subcollection 
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/srophe/api/{$collection}/atom")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($collection as xs:string, $start as xs:integer*, $perpage as xs:integer*){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     feed:build-feed($collection, $start, $perpage)
     )
}; 

(:~
  : Return atom feed for syriaca.org  
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/srophe/api/atom")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($start as xs:integer*, $perpage as xs:integer*){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
    let $feed := collection($config:app-root || '/data')//tei:TEI
    let $total := count($feed)
    return 
     feed:build-atom-feed($feed, $start, $perpage,'',$total)
     )
};


(:~
  : Return oai-pmh results for syriaca.org  
  : Serialized as XML Temprary testing oai_phm as a module pluged into restxq
:)
declare 
    %rest:GET
    %rest:path("/srophe/api/oai_pmh")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($start as xs:integer*, $perpage as xs:integer*){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
    let $feed := collection($config:app-root || '/data')//tei:TEI
    let $total := count($feed)
    return 
     feed:build-atom-feed($feed, $start, $perpage,'',$total)
     )
};

(:~
 : Returns tei record for syriaca.org subcollections
:)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()*{
    let $collection-name := 
        if($collection = 'place') then 'places'
        else if($collection = 'person') then 'persons'
        else $collection
    let $path := ($config:app-root || '/data/' || $collection-name || '/tei/' || $id ||'.xml')
    return
        if($collection='spear') then 
            let $spear-id := concat('http://syriaca.org/spear/',$id)
            return
             <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">
                {
                    for $rec in collection($config:app-root || '/data/spear/tei')//tei:div[@uri=$spear-id]
                    return $rec
                }
             </tei:TEI>
        else doc($path)/child::*
};