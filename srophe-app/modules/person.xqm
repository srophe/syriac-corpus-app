(:~
 : Builds persons page and persons page functions  
 :)
xquery version "3.0";

module namespace person="http://syriaca.org/person";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url  
 :)
declare variable $person:id {request:get-parameter('id', '')};

(:~ 
 : Simple get record function, retrieves tei record based on idno
 : @param $person:id syriaca.org uri 
:)
declare function person:get-rec($node as node(), $model as map(*)) {
if($person:id) then 
    let $id :=
        if(contains(request:get-uri(),$global:base-uri)) then $person:id
        else if(contains(request:get-uri(),'/persons/') or contains(request:get-uri(),'/person/') or contains(request:get-uri(),'/saints/')) then concat($global:base-uri,'/person/',$person:id) 
        else $person:id
    return map {"data" := collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI}
else map {"data" := 'Page data'} 
};

(: Dashboard functions 
count(distinct-values(for $contributors in collection('/db/apps/srophe-data/data/places/tei')//tei:respStmt/tei:name
return $contributors))
:)
declare %templates:wrap function person:dashboard($node as node(), $model as map(*), $collection-title, $data-dir){
let $data := 
    if($data-dir = 'saints') then collection(concat($global:data-root,'/persons/tei'))//tei:person[contains(@ana,"#syriaca-saint")]/ancestor::tei:TEI
    else if($data-dir = 'authors') then collection(concat($global:data-root,'/persons/tei'))//tei:person[contains(@ana,"#syriaca-author")]/ancestor::tei:TEI
    else collection(concat($global:data-root,'/persons/tei'))
return global:srophe-dashboard($data,$collection-title, $data-dir)

};

(:~
 : Traverse main nav and "fix" links based on values in config.xml 
:)
declare
    %templates:wrap
function person:fix-links($node as node(), $model as map(*)) {
    templates:process(global:fix-links($node/node()), $model)
};

(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : @param $person:id if id is present find TEI title, otherwise use title of sub-module
:)
declare %templates:wrap function person:app-title($node as node(), $model as map(*), $coll as xs:string?){
if($person:id) then
   substring-before(global:tei2html($model("data")/descendant::tei:title[1]/text())," — ")
else if($coll = 'persons') then 'The Syriac Biographical Dictionary'
else if($coll = 'q')then 'Gateway to the Syriac Saints'
else if($coll = 'saints') then 'Gateway to the Syriac Saints: Volume II: Qadishe'
else 'The Syriac Biographical Dictionary' 
};  

(:
 : Pass necessary element to h1 xslt template    
:)
declare %templates:wrap function person:h1($node as node(), $model as map(*)){
    let $title := $model("data")//tei:person
    let $title-nodes := 
            <srophe-title ana="{$title/@ana}" xmlns="http://www.tei-c.org/ns/1.0">
                {(
                    $title/descendant::tei:persName[@syriaca-tags='#syriaca-headword'],
                    $title/descendant::tei:birth,
                    $title/descendant::tei:death,
                    $title/descendant::tei:idno[contains(.,$global:base-uri)]
                )}
            </srophe-title>
    return global:tei2html($title-nodes)
};

declare %templates:wrap function person:names($node as node(), $model as map(*)){
    let $names := $model("data")//tei:person/tei:persName
    let $abstract := $model("data")//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $model("data")//tei:note[@type='abstract']
    let $sex := $model("data")//tei:sex
    let $nodes := 
        <person xmlns="http://www.tei-c.org/ns/1.0">
            {(
                $names,
                $abstract,
                $sex
            )}
        </person>
    return global:tei2html($nodes)
};


declare %templates:wrap function person:data($node as node(), $model as map(*)){
    let $rec := $model("data")//tei:person
    let $nodes := 
    <person xmlns="http://www.tei-c.org/ns/1.0" ana="{$rec/@ana/text()}">
            {
                for $data in $rec/child::*[not(self::tei:persName)][not(self::tei:bibl)][not(self::*[@type='abstract' or starts-with(@xml:id, 'abstract-en')])]
                return $data
            }
    </person>
    return global:tei2html($nodes)
};

declare %templates:wrap function person:timeline($node as node(), $model as map(*), $dates){
let $data := $model("data")
return
    if($dates = 'personal') then 
        if($data//tei:birth[@when or @notBefore or @notAfter] or 
        $data//tei:death[@when or @notBefore or @notAfter] or 
        $data//tei:state[@when or @notBefore or @notAfter or @to or @from] or 
        $data//tei:floruit[@when or @notBefore or @notAfter or @to or @from]) then
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
                                 for $date in $data//tei:birth[@when] | $data//tei:birth[@notBefore] | $data//tei:birth[@notAfter] | $data//tei:birth[@to] | $data//tei:birth[@from] 
                                 | $data//tei:death[@when] |$data//tei:death[@notBefore] |$data//tei:death[@notAfter] | $data//tei:death[@to] | $data//tei:death[@from] |
                                 $data//tei:floruit[@when] | $data//tei:floruit[@notBefore]| $data//tei:floruit[@notAfter] | $data//tei:floruit[@to] | $data//tei:floruit[@from]
                                 | $data//tei:state[@when] | $data//tei:state[@notBefore] | $data//tei:state[@notAfter] | $data//tei:state[@from] | $data//tei:state[@to]
                                 return 
                                    <li>{global:tei2html($date)}</li>
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
let $data := $model("data")
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
            global:tei2html(
                <person xmlns="http://www.tei-c.org/ns/1.0">
                    <related-items xmlns="http://www.tei-c.org/ns/1.0">
                        {person:get-related($data)}
                    </related-items>
                </person>)
            }
        </div>
        )
     else if(person:get-related($data/descendant::tei:relation/child::*)) then 
            global:tei2html(
                <person xmlns="http://www.tei-c.org/ns/1.0">
                    <related-items xmlns="http://www.tei-c.org/ns/1.0">
                        {person:get-related($data)}
                    </related-items>
                </person>)

     else ()
};


(:
 : Use OCLC API to return VIAF records 
 : limit to first 5 results
 : @param $rec
 : NOTE param should just be tei:idno as string
:)
declare %templates:wrap function person:worldcat($node as node(), $model as map(*)){
let $rec := $model("data")
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
                          let $rec := collection($global:data-root)//tei:idno[. = $rel-rec] 
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
    let $rec := $model("data")
    let $sources := 
    <person xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:person/tei:bibl}
    </person>
    return global:tei2html($sources)
};

(: 
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function person:citation($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $header := 
    <person xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </person>
    return global:tei2html($header)
};

(:~
 : Build links
:)
declare %templates:wrap function person:link-icons-list($node as node(), $model as map(*)){
let $data := $model("data")
let $links:=
    <person xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data//tei:person//tei:idno, $data//tei:person//tei:location}
        </see-also>
    </person>
return global:tei2html($links)
};
