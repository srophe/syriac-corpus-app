(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace person="http://syriaca.org//person";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace timeline="http://syriaca.org//timeline" at "lib/timeline.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $person:id {request:get-parameter('id', '')};

(:~
 : Value passed through app:page-title() 
:)
declare function person:html-title(){
    let $placeid := concat('place-',$place:id)
    let $title := collection($config:app-root || "/data/places/tei")/id($placeid)/ancestor::tei:TEI//tei:titleStmt/tei:title[@level='a'][1]
    return normalize-space($title)
};

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

(:
 : Pass necessary element to h1 xslt template 
:)
declare %templates:wrap function person:h1($node as node(), $model as map(*)){
    let $title := $model("persons-data")//tei:person
    let $title-nodes := 
            <srophe-title ana="{$title/@ana}" xmlns="http://www.tei-c.org/ns/1.0">
                {(
                    $title/descendant::tei:persName[@syriaca-tags='#syriaca-headword'],
                    $title/descendant::tei:birth,
                    $title/descendant::tei:death,
                    $title/descendant::tei:idno[contains(.,'syriaca.org')]
                )}
            </srophe-title>
    return app:tei2html($title-nodes)
};

declare %templates:wrap function person:names($node as node(), $model as map(*)){
    let $names := $model("persons-data")//tei:person/tei:persName
    let $abstract := $model("persons-data")//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $model("persons-data")//tei:note[@type='abstract']
    let $nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <person>
            {(
                $names,
                $abstract
            )}
        </person>
    </body>
    return app:tei2html($nodes)  
};

declare %templates:wrap function person:timeline($node as node(), $model as map(*), $dates){
let $data := $model("persons-data")
return
    if($dates = 'personal') then 
        if($data//tei:birth[@when or @notBefore or @notAfter] or $data//tei:death[@when or @notBefore or @notAfter] or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
                <div class="row">
                        <div class="col-md-9">
                            <div class="timeline">
                                <div>{timeline:timeline($data, 'Events Timeline')}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <h4>Dates</h4>
                            <ul class="list-unstyled">
                                {
                                 for $date in $data//tei:birth[@when] | $data//tei:birth[@notBefore] | $data//tei:birth[@notAfter] 
                                 | $data//tei:death[@when] |$data//tei:death[@notBefore] |$data//tei:death[@notAfter]| 
                                 $data//tei:floruit[@when] | $data//tei:floruit[@notBefore]| $data//tei:floruit[@notAfter] 
                                 | $data//tei:state[@when] | $data//tei:state[@notBefore] | $data//tei:state[@notAfter] | $data//tei:state[@from] | $data//tei:state[@to]
                                 return 
                                    <li>{app:tei2html($date)}</li>
                                }
                            </ul>
                        </div>
                    </div>
        else ()
     else if($dates = 'events') then
        <div class="timeline">
            <h3>Events</h3>
            <div>{timeline:timeline($data//tei:event, 'Events Timeline')}</div>
        </div>
     else ()
};

declare %templates:wrap function person:related-places($node as node(), $model as map(*)){
let $data := $model("persons-data")
let $geo-hits := person:get-related($data)//tei:geo
return 
    if(count($geo-hits) gt 0) then
        (
        <div>
            <h2>Related Places in the Syriac Gazetteer</h2>
            {geo:build-map($geo-hits,'','')}
        </div>,
        <div>
            {
            app:tei2html(
                <body xmlns="http://www.tei-c.org/ns/1.0">
                    <related-items xmlns="http://www.tei-c.org/ns/1.0">
                        {person:get-related($data)}
                    </related-items>
                </body>)
            }
        </div>
        )
     else if(person:get-related($data/descendant::tei:relation/child::*)) then 
            app:tei2html(
                <body xmlns="http://www.tei-c.org/ns/1.0">
                    <related-items xmlns="http://www.tei-c.org/ns/1.0">
                        {person:get-related($data)}
                    </related-items>
                </body>)

     else ()
};

(:
 : Use OCLC API to return VIAF records 
 : limit to first 5 results
 : @param $rec
 : NOTE param should just be tei:idno as string
:)
declare %templates:wrap function person:worldcat($node as node(), $model as map(*)){
let $rec := $model("persons-data")
return 
    if($rec//tei:idno[contains(.,'http://worldcat.org/identities/lccn-n')]) then 
       <div id="worldcat-refs" class="well">
            <h3>Catalog Search Results from WorldCat</h3>
            <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
            <div>
            {
                for $viaf-ref in $rec//tei:idno[contains(.,'http://worldcat.org/identities/lccn-n')]
                let $build-request :=
                         <http:request href="{$viaf-ref}" method="get"/>
                let $results :=  http:send-request($build-request)//by 
                let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
                return 
                  (<ul id="{$viaf-ref}" count="{$total-works}">
                        {
                        for $citation in $results/citation[position() lt 5]
                        return
                            <li>
                                <a href="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</a>
                            </li>
                        }
                  </ul>,
                  <span class="pull-right">
                        <a href="{$viaf-ref}">See all {$total-works} titles from WorldCat</a>
                  </span>)
                }  
            </div>    

        </div>
    else ()    
};

(:~
 : Get related items 
 : NOTE should be able to pass related items in as string?
:)
declare function person:get-related($rec as node()*){
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
 : Return bibls for use in sources
:)
declare %templates:wrap function person:sources($node as node(), $model as map(*)){
    let $rec := $model("persons-data")
    let $sources := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:person/tei:bibl}
    </body>
    return app:tei2html($sources)
};

(:
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function person:citation($node as node(), $model as map(*)){
    let $rec := $model("persons-data")
    let $header := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </body>
    return app:tei2html($header)
};

declare %templates:wrap function person:link-icons-list($node as node(), $model as map(*)){
let $data := $model("persons-data")
let $links:=
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data//tei:person//tei:idno, $data//tei:person//tei:location}
        </see-also>
    </body>
return app:tei2html($links)
};
