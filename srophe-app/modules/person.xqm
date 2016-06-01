(:~    
 : Builds persons page and persons page functions  
 :)
xquery version "3.0";

module namespace person="http://syriaca.org/person";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace schema = "http://schema.org/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
(:~ 
 : Parameters passed from the url  
 :)
declare variable $person:id {request:get-parameter('id', '')};

(:~  
 : Simple get record function, retrieves tei record based on idno
 : @param $person:id syriaca.org uri 
:)
declare 
    %templates:wrap 
function person:get-rec($node as node(), $model as map(*),$collection as xs:string?) {
    app:get-rec($node, $model, $collection)
};

 
(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : @param $person:id if id is present find TEI title, otherwise use title of sub-module
:)
declare %templates:wrap function person:app-title($node as node(), $model as map(*), $coll as xs:string?){
  app:app-title($node, $model, $coll)
};  

(:
 : Pass necessary element to h1 xslt template     
:)
declare %templates:wrap function person:h1($node as node(), $model as map(*)){
    app:h1($node,$model)
};

declare %templates:wrap function person:names($node as node(), $model as map(*)){
try {
    let $names := $model("data")//tei:person/tei:persName
    let $abstract := $model("data")//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $model("data")//tei:note[@type='abstract']
    let $sex := $model("data")//tei:sex
    let $martyr := $model("data")//tei:state
    let $nodes := 
        <person xmlns="http://www.tei-c.org/ns/1.0">
            {(
                $names,
                $abstract,
                $martyr,
                $sex
            )}
        </person>
    return global:tei2html($nodes)
   } catch * { <error>No Data {$err:code}: {$err:description}</error>}
   
};

declare %templates:wrap function person:data($node as node(), $model as map(*)){
    try {
     let $rec := $model("data")//tei:person
     let $nodes := 
         <person xmlns="http://www.tei-c.org/ns/1.0" ana="{$rec/@ana/text()}">
                 {
                     for $data in $rec/child::*[not(self::tei:persName)][not(self::tei:bibl)]
                     [not(self::*[@type='abstract' or starts-with(@xml:id, 'abstract-en')])]
                     [not(self::tei:state)][not(self::tei:sex)]
                     return $data
                 }
         </person>
     return global:tei2html($nodes)        
    } catch * { <error>No Data {$err:code}: {$err:description}</error>}
};
    
declare %templates:wrap function person:timeline($node as node(), $model as map(*), $dates){
let $data := $model("data")
return
    if($dates = 'personal') then 
        if($data//tei:birth[@when or @notBefore or @notAfter] or 
        $data//tei:death[@when or @notBefore or @notAfter] or 
        $data//tei:state[@when or @notBefore or @notAfter or @to or @from] or 
        $data//tei:floruit[@when or @notBefore or @notAfter or @to or @from] or $data//tei:date[@when or @notBefore or @notAfter or @to or @from]) then
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
                                 for $date in $data//tei:birth[@when or @notBefore or @notAfter] | $data//tei:birth[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:death[@when or @notBefore or @notAfter] | $data//tei:death[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:state[@when or @notBefore or @notAfter or @to or @from] | $data//tei:state[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:floruit[@when or @notBefore or @notAfter or @to or @from] | $data//tei:floruit[tei:date[@when or @notBefore or @notAfter]] 
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
    if($rec//tei:idno[starts-with(.,'http://worldcat.org/identities/lccn-n')] or $rec//tei:idno[starts-with(.,'http://viaf.org/viaf')][not(contains(.,'sourceID'))]) then
            let $viaf-ref := if($rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')]) then 
                                        $rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')][1]/text()
                                     else $rec/descendant::tei:idno[@type='URI'][contains(.,'http://viaf.org/viaf')][not(contains(.,'sourceID/SRP'))][1]/text()
            let $uri := if(starts-with($viaf-ref,'http://viaf.org/viaf')) then 
                                    let $rdf := http:send-request(<http:request href="{concat($viaf-ref,'/rdf.xml')}" method="get"/>)[2]//schema:sameAs/child::*/@rdf:about[starts-with(.,'http://id.loc.gov/')]
                                    let $lcc := tokenize($rdf,'/')[last()]
                                    return concat('http://worldcat.org/identities/lccn-',$lcc)
                                else $viaf-ref
            let $build-request :=  <http:request href="{$uri}" method="get"/>
            return 
                try {
                    let $results :=  http:send-request($build-request)//by 
                    let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
                    return 
                        if(not(empty($results)) and  $total-works != '0') then 
                                <div id="worldcat-refs" class="well">
                                    <h3>{$total-works} Catalog Search Results from WorldCat</h3>
                                    <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
                                    <div>
                                         <ul id="{$viaf-ref}" count="{$total-works}">
                                            {
                                                for $citation in $results/citation[position() lt 5]
                                                return
                                                    <li><a href="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</a></li>
                                             }
                                         </ul>
                                         <span class="pull-right"><a href="{$uri}">See all {$total-works} titles from WorldCat</a></span>,<br/>
                                    </div>
                                </div>    
                                         
                        else ()
                } catch * {
                    <error>Caught error {$err:code}: {$err:description}</error>
                } 
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
 : Get relations 
 : NOTE need to untangle get-related and get-related places. 
:)
declare %templates:wrap function person:relations($node as node(), $model as map(*)){
if($model("data")//tei:relation) then 
    let $idno := replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei','')
    return rel:build-relationships($model("data")//tei:relation, $idno)
else ()
};

(:~
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
