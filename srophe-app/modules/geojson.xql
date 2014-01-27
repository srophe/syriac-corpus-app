xquery version "3.0";
(:~
 : Testing json output for leafletjs maps 
 :)
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";
declare option exist:serialize "method=json media-type=text/javascript encoding=UTF-8";

let $json := 
<json type="FeatureCollection">
    {
    let $geo-map := map{"geo-data" := collection($config:app-root || "/data/places/tei")//tei:geo} 
    for $place-name in map:get($geo-map, 'geo-data')
    let $id := string($place-name/ancestor::tei:place/@xml:id)
    let $type := string($place-name/ancestor::tei:place/@type)
    let $title := $place-name/ancestor::tei:place/tei:placeName[@xml:lang = 'en'][1]/text()
    let $geo := $place-name/text()
    return
        <features json:array="true">
            <type>Feature</type>
            <geometry type="Point">
                <coordinates json:literal="true">{substring-after($geo,' ')}</coordinates>
                <coordinates json:literal="true">{substring-before($geo,' ')}</coordinates>
            </geometry>
            <properties>
                <uri>{concat('http://syriaca.org/place/',substring-after($id,'place-'))}</uri>
                <type>{$type}</type>
                <name>{$title}</name>
            </properties>
        </features>
  }
</json>
return $json

  