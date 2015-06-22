xquery version "3.0";

module namespace api="http://syriaca.org/api";

import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";
import module namespace feed="http://syriaca.org//atom" at "lib/atom.xqm";
import module namespace common="http://syriaca.org//common" at "search/common.xqm";
(:import module namespace templates="http://exist-db.org/xquery/templates";:)
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

import module namespace config="http://syriaca.org//config" at "config.xqm";

(: For output annotations  :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";

(: For interacting with the TEI document :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

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
    %rest:query-param("output", "{$output}", "json")
    %output:media-type("application/json")
    (:%output:method("json"):)
function api:get-geo-json($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/json; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     api:get-geojson-node($type,$output)
) 

};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as KML
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
     api:get-geojson-node($type,$output) 
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
let $keyword-string := 
    if(exists($q) and $q != '') then concat("[ft:query(.,'",common:clean-string($q),"',common:options())]")
    else ()    
let $place-name := 
    if(exists($place) and $place != '') then concat("[ft:query(descendant::tei:placeName,'",common:clean-string($place),"',common:options())]")
    else ()
let $pers-name := 
    if(exists($person) and $person != '') then concat("[ft:query(descendant::tei:persName,'",common:clean-string($person),"',common:options())]")
    else ()
let $query-string := concat("collection('",$config:data-root,"')//tei:body",$keyword-string,$pers-name,$place-name)
let $hits := util:eval($query-string)
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
    let $feed := collection(xs:anyURI($config:data-root || $collection ))//tei:TEI
    let $total := count($feed)
    return
     feed:build-atom-feed($feed, $start, $perpage,'',$total)
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
    let $feed := collection(xs:anyURI($config:data-root))//tei:TEI
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
    let $path := (xs:anyURI($config:data-root) || '/' || $collection-name || '/tei/' || $id ||'.xml')
    return 
        if($collection='spear') then 
            let $spear-id := concat('http://syriaca.org/spear/',$id)
            return
             <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">
                {
                    for $rec in collection(xs:anyURI($config:data-root) || '/spear/tei')//tei:div[@uri=$spear-id]
                    return $rec
                }
             </tei:TEI>
        else doc($path)/child::*
};

(:~
 : Build selects coordinates
:)
declare function api:get-geojson-node($type,$output){
let $geo-map :=
    if($type) then
        if(contains($type,',')) then 
            let $types := 
                if(contains($type,',')) then  string-join(for $type-string in tokenize($type,',') return concat('"',$type-string,'"'),',')
                else $type
            let $path := concat("collection('",$config:data-root,"/places/tei')//tei:place[@type = (",$types,")]//tei:geo") 
            for $recs in util:eval($path) 
            return $recs 
        else collection($config:data-root || "/places/tei")//tei:place[@type=$type]//tei:geo
    else collection($config:data-root || "/places/tei")//tei:geo
return
    if($output = 'json') then xqjson:serialize-json(geo:json-wrapper(($geo-map), $type, $output))
    else geo:kml-wrapper(($geo-map), $type, $output)
};