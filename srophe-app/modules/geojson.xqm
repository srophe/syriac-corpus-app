xquery version "3.0";

module namespace geo="http://syriaca.org//geojson";
(:~
 : Module returns coordinates for leafletjs maps, or for API requests
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~
 : Module builds GEOJSON features element for each place returned
 : @param $geo coordinates string
 : @param $id  record id 
 : @param $rec-type place type
 : @param $title place title
:)
declare function geo:build-json($geo as xs:string,$id as xs:string, $rec-type as xs:string, $title as xs:string, $rec-rel as xs:string?) as element(features){
    <features json:array="true">
        <type>Feature</type>
        <geometry type="Point">
            <coordinates json:literal="true">{substring-after($geo,' ')}</coordinates>
            <coordinates json:literal="true">{substring-before($geo,' ')}</coordinates>
        </geometry>
        <properties>
            <uri>{concat('http://syriaca.org/place/',substring-after($id,'place-'))}</uri>
            <placeType>{if($rec-type='open-water') then 'openWater' else $rec-type}</placeType>
            {
              if($rec-rel != '') then 
                <placeRelation>{$rec-rel}</placeRelation>
              else ()  
            }
            <name>{$title} - {if($rec-type='open-water') then 'openWater' else $rec-type}</name>
        </properties>
    </features>
};

(:~
 : Module builds KML Placemark element for each place returned
 : @param $geo coordinates string
 : @param $id  record id 
 : @param $rec-type place type
 : @param $title place title
:)
declare function geo:build-kml($geo as xs:string,$id as xs:string, $rec-type as xs:string, $title as xs:string) as element(features){
    <kml xmlns="http://www.opengis.net/kml/2.2">
        <Placemark>
            <name>{$title} - {if($rec-type='open-water') then 'openWater' else $rec-type}</name>
            <description>{concat('http://syriaca.org/place/',substring-after($id,'place-'))}
            </description>
            <Point>
                <coordinates>{replace($geo,' ',',')}</coordinates>
            </Point>
        </Placemark>
    </kml>    
};

(:~
 : Build results set for geographic data, or passes in results from search 
 : @param $geo-search predefined results set passed from search.xqm
 : @param $type place type from predefined list: http://syriaca.org/documentation/place-types.html
 : @param $output indicates json or kml
:)
declare function geo:get-coordinates($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    let $geo-map :=
        if(not(empty($geo-search))) then 
            map{"geo-data" := $geo-search}
        else if(exists($type) and $type != '') then
            if(contains($type,',')) then
                map{"geo-data" :=  
                let $types := 
                    if(contains($type,',')) then 
                            concat('(',
                            string-join(for $type-string in tokenize($type,',')
                                        return concat("'",$type-string,"'"),',')
                            ,')')
                        else $type
                let $path := concat("collection('/db/apps/srophe/data/places/tei')//tei:place[@type = ",$types,"]") 
                let $person := util:eval($path) 
                let $place := $person/tei:placeName[1]
                return $place    
                }
            else  map{"geo-data" := collection($config:app-root || "/data/places/tei")//tei:geo[ancestor::tei:place[@type=$type]]} 
        else map{"geo-data" := collection($config:app-root || "/data/places/tei")//tei:geo} 
    for $place-name in map:get($geo-map, 'geo-data')
    let $id := string($place-name/ancestor::tei:place/@xml:id)
    let $rec-type := string($place-name/ancestor::tei:place/@type)
    let $title := $place-name/ancestor::tei:place/tei:placeName[@xml:lang = 'en'][1]/text()
    let $geo := $place-name/text()
    let $rel := string($place-name/ancestor::*:relation/@name)
    return
        if($output = 'kml') then geo:build-kml($geo,$id,$rec-type,$title)
        else geo:build-json($geo,$id,$rec-type,$title,$rel)
};

(:~
 : Build root element for KML output
 : @param $geo-search predefined results set passed from search.xqm
 : @param $type place type from predefined list: http://syriaca.org/documentation/place-types.html
 : @param $output indicates json or kml
:)
declare function geo:kml-wrapper($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
            {geo:get-coordinates($geo-search,$type,$output)}
        </Document>
    </kml>
};

(:~
 : Build root element for geojson output
 : @param $geo-search predefined results set passed from search.xqm
 : @param $type place type from predefined list: http://syriaca.org/documentation/place-types.html
 : @param $output indicates json or kml
:)
declare function geo:json-wrapper($geo-search as element()*, $type as xs:string*, $output as xs:string*) as element()*{
    <json type="FeatureCollection">
        {geo:get-coordinates($geo-search,$type,$output)}
    </json>
};

(:~
 : Transform results to json with xslt for inclusion in search page. 
 : @param $geo-search predefined results set passed from search.xqm
 : @param $type place type from predefined list: http://syriaca.org/documentation/place-types.html
 : @param $output indicates json or kml
:)
declare function geo:json-transform($geo-search as node()*, $type as xs:string*, $output as xs:string*){
    transform:transform(geo:json-wrapper($geo-search, $type, $output), doc('../resources/xsl/geojson.xsl'),() )  
};