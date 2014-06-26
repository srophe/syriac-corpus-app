xquery version "3.0";

module namespace geo="http://syriaca.org//geojson";

import module namespace config="http://syriaca.org//config" at "config.xqm";

import module namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare option exist:serialize "method=json media-type=text/javascript encoding=UTF-8";


declare function geo:build-json($geo as xs:string,$id as xs:string, $rec-type as xs:string, $title as xs:string) as element(features){
    <features json:array="true">
        <type>Feature</type>
        <geometry type="Point">
            <coordinates json:literal="true">{substring-after($geo,' ')}</coordinates>
            <coordinates json:literal="true">{substring-before($geo,' ')}</coordinates>
        </geometry>
        <properties>
            <uri>{concat('/place/',substring-after($id,'place-'),'.html')}</uri>
            <placeType>{if($rec-type='opne-water') then 'openWater' else $rec-type}</placeType>
            <name>{$title}</name>
        </properties>
    </features>
};

declare function geo:build-kml($geo as xs:string,$id as xs:string, $rec-type as xs:string, $title as xs:string) as element(features){
    <kml xmlns="http://www.opengis.net/kml/2.2">
        <Placemark>
            <name>{$title}</name>
            <description>{if($rec-type='open-water') then 'openWater' else $rec-type} {concat('/place/',substring-after($id,'place-'),'.html')}</description>
            <Point>
                <coordinates>{replace($geo,' ',',')}</coordinates>
            </Point>
        </Placemark>
    </kml>    
};

(:
have to add limit for search results, does not serialize as json. 
not sure what to do about this. 
add type 
param $q
param $type
param $output
:)
declare function geo:get-coordinates($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    let $geo-map :=
        if(not(empty($geo-search))) then 
            map{"geo-data" := $geo-search}
        else if(exists($type) and $type != '') then
            map{"geo-data" := collection($config:app-root || "/data/places/tei")//tei:geo[ancestor::tei:place[@type=$type]]}
        else map{"geo-data" := collection($config:app-root || "/data/places/tei")//tei:geo} 
    for $place-name in map:get($geo-map, 'geo-data')
    let $id := string($place-name/ancestor::tei:place/@xml:id)
    let $rec-type := string($place-name/ancestor::tei:place/@type)
    let $title := $place-name/ancestor::tei:place/tei:placeName[@xml:lang = 'en'][1]/text()
    let $geo := $place-name/text()
    return
        if($output = 'kml') then geo:build-kml($geo,$id,$rec-type,$title)
        else geo:build-json($geo,$id,$rec-type,$title)
};

declare function geo:kml-wrapper($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
            {geo:get-coordinates($geo-search,$type,$output)}
        </Document>
    </kml>
};

declare function geo:json-wrapper($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    <json type="FeatureCollection">
        {geo:get-coordinates($geo-search,$type,$output)}
    </json>
};

declare function geo:json-transform($geo-search as node()*, $type as xs:string*, $output as xs:string*){
    transform:transform(geo:json-wrapper($geo-search, $type, $output), doc('../resources/xsl/geojson.xsl'),() )  
};