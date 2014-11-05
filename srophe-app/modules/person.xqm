(:~
 : Builds persons page and persons page functions 
 :)
xquery version "3.0";

module namespace person="http://syriaca.org//person";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $person:id {request:get-parameter('id', '')};

(:~
 : Retrieve persons record
 : Adds persons data to map function
 : @param $id persons id
 :)
declare function person:get-persons($node as node(), $model as map(*)){
    let $personsid := concat('person-',$person:id)
    for $recs in collection($config:app-root || "/data/persons/tei")/id($personsid)
    let $rec := $recs/ancestor::tei:TEI
    return map {"persons-data" := $rec}
};

(:~
 : Get related items 
 : NOTE should be able to pass related items in as string?
:)
declare function person:get-related($rec as node()*){
    <related-items xmlns="http://www.tei-c.org/ns/1.0">
        {
            for $related in $rec//tei:relation 
            let $item-uri := string($related/@passive)
            let $desc := $related/tei:desc
            return 
                for $rel-rec in tokenize($item-uri,' ')
                return
                    <relation uri="{$rel-rec}" xmlns="http://www.tei-c.org/ns/1.0">
                        {(for $att in $related/@*
                          return attribute {name($att)} {$att},
                          let $rec := collection($config:app-root || "/data")//tei:idno[. = $rel-rec] 
                          let $geo := if($rec/ancestor::tei:TEI//tei:geo) then $rec/ancestor::tei:TEI//tei:geo
                                      else ()
                          let $title := if($rec/ancestor::tei:place) then 
                                            <place xml:id="{$rec/ancestor::tei:place/@xml:id}" type="{$rec/ancestor::tei:place/@type}" xmlns="http://www.tei-c.org/ns/1.0">
                                                {($rec/ancestor::tei:place/tei:placeName[@syriaca-tags="#syriaca-headword"][1],$geo)}
                                            </place>
                                        else $rec/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
                          return 
                            <item uri="{$rel-rec}" xmlns="http://www.tei-c.org/ns/1.0">
                                {$title}
                            </item> 
                           ,
                           $desc
                       )}
                    </relation>
        }
     </related-items> 
};   

(:
 : Build map widget for realted places passed from person:get-related-places
 : @param $rec
 : Passes tei:geo data to geojson.xqm for correct geojson formatting.
 : Passed back into leafletjs js below. 
:)
declare function person:build-geojson($rec){
let $geo-hits := person:get-related($rec)//tei:geo
return    
        if(count($geo-hits) gt 0) then
            <div id="geojson" count="{count($geo-hits)}">
                {geo:json-transform($geo-hits,'','')}
            </div>
       else ()
};


(:
 : Use OCLC API to return VIAF records
 : limit to first 5 results
 : @param $rec
 : NOTE param should just be tei:idno as string
:)
declare function person:worldcat-ref($rec){
if($rec//tei:idno[contains(.,'http://worldcat.org/identities/lccn-n')]) then 
    <div id="worldcat-refs" class="well">
        {
            for $viaf-ref in $rec//tei:idno[contains(.,'http://worldcat.org/identities/lccn-n')]
            let $build-request :=
                     <http:request href="{$viaf-ref}" method="get"/>
            let $results :=  http:send-request($build-request)//by 
            let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
            return 
              <ul id="{$viaf-ref}" count="{$total-works}">
                    {
                    for $citation in $results/citation[position() lt 5]
                    return
                        <li ref="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</li>
                    }
              </ul>
        }  
    </div>    
else ()
};
(:~ 
 : Pull together persons page data   
 : Adds related persons and nested locations to full TEI document
 : Passes xml to persons page.xsl for html transformation
 NOTE : add try catch? for worldcat so it fails gracefully.
:) 
declare %templates:wrap function person:get-persons-data($node as node(), $model as map(*)){
   for $rec in $model("persons-data")
   let $buildRec :=
                <TEI
                    xml:lang="en"
                    xmlns:xi="http://www.w3.org/2001/XInclude"
                    xmlns:svg="http://www.w3.org/2000/svg"
                    xmlns:math="http://www.w3.org/1998/Math/MathML"
                    xmlns="http://www.tei-c.org/ns/1.0">
                    {
                       ($rec/child::*,person:get-related($rec),person:build-geojson($rec),person:worldcat-ref($rec))
                    }
                    </TEI>
    let $cache :='Change value to force page refresh 087s6'
    return
      (:$buildRec:)
       transform:transform($buildRec, doc('../resources/xsl/personspage.xsl'),() )
};
