xquery version "3.0";

(:~
 : Provides html metadata. Passes data to page.html via config.xqm
 :)
module namespace geo="http://syriaca.org//geojson";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";

declare function geo:build-geojson($node as node()*, $model as map(*)){
let $json := 
    <json type="FeatureCollection">
       {
       let $geo-map := $model("hits") 
       for $place-name in $geo-map
       let $id := string($place-name/ancestor-or-self::tei:place/@xml:id)
       let $type := string($place-name/ancestor-or-self::tei:place/@type)
       let $title := $place-name/ancestor-or-self::tei:place/tei:placeName[@xml:lang = 'en'][1]/text()
       let $geo := $place-name//tei:geo/text()
       where $place-name//tei:geo
       return
           <features json:array="true">
               <type>Feature</type>
               <geometry type="Point">
                   <coordinates json:literal="true">{substring-after($geo,' ')}</coordinates>
                   <coordinates json:literal="true">{substring-before($geo,' ')}</coordinates>
               </geometry>
               <properties>
                   <uri>{concat('/place/',substring-after($id,'place-'),'.html')}</uri>
                   <type>{$type}</type>
                   <name>{$title}</name>
               </properties>
           </features>
     }
   </json>
 return transform:transform($json, doc('../resources/xsl/geojson.xsl'),() )  
};