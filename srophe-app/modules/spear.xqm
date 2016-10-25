(:~
 : Builds spear page  
 :)
xquery version "3.0";

module namespace spear="http://syriaca.org/spear";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace ev="http://syriaca.org/events" at "lib/events.xqm";
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~      
 : Parameters passed from the url 
 :)
declare variable $spear:id {request:get-parameter('id', '')}; 
declare variable $spear:view {request:get-parameter('view', 'place')};
declare variable $spear:date {request:get-parameter('date', '')};
declare variable $spear:fq {request:get-parameter('fq', '')};
declare variable $spear:sort {request:get-parameter('sort', 'all') cast as xs:string};

declare variable $spear:item-type {
if($spear:id != '') then 
    if(contains($spear:id, '/place')) then 'place-factoid'
    else if(contains($spear:id, '/person')) then 'person-factoid'
    else 'event-factoid'
else 'all-events'
};    

(:~
 : Build spear view
 : @param $id spear URI
 :)
declare %templates:wrap function spear:get-rec($node as node(), $model as map(*)){ 
let $id :=
        if(contains($app:id,$global:base-uri) or starts-with($app:id,'http://')) then $app:id
        else if(contains(request:get-uri(),$global:nav-base)) then replace(request:get-uri(),$global:nav-base, $global:base-uri)
        else if(contains(request:get-uri(),$global:base-uri)) then request:get-uri()
        else $app:id
let $id := if(ends-with($id,'.html')) then substring-before($id,'.html') else $id  
return     
    if(starts-with($id,'http://syriaca.org/spear/')) then  
           map {"data" :=  global:get-rec($id)}
    else map {"data" :=  
        <aggregate xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $rec in collection($global:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$app:id]]
                (:| 
                collection('/db/apps/srophe-data/data/spear/tei')//tei:div[descendant::*[matches(@active, concat($id,"(\W|$)"))]] |
                collection('/db/apps/srophe-data/data/spear/tei')//tei:div[descendant::*[matches(@passive, concat($id,"(\W|$)"))]] |
                collection('/db/apps/srophe-data/data/spear/tei')//tei:div[descendant::*[matches(@mutual, concat($id,"(\W|$)"))]]
                :)
                return ($rec)  
                }
        </aggregate>}
};

(:~
 : Checks for canonical record in Syriaca.org 
 : @param $spear:id 
:)
declare function spear:canonical-rec(){
    collection($global:data-root)//tei:idno[. = $spear:id]
};

(:~ 
 : Build page title
 : Uses connical record from syriaca.org as title, otherwise uses spear data
:)
declare %templates:wrap function spear:h1($node as node(), $model as map(*)){
    let $data := $model("data")
    let $rec-exists := spear:canonical-rec()  
    let $title :=  $rec-exists/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]
    let $id := <idno type='URI' xmlns="http://www.tei-c.org/ns/1.0">{$spear:id}</idno>
    return global:tei2html(
                <spear-title xmlns="http://www.tei-c.org/ns/1.0">
                    {$title, $id}
                </spear-title>)
};

declare function spear:data($node as node(), $model as map(*)){
if($spear:item-type = 'place-factoid') then
    spear:place-data($model("data"))
else if($spear:item-type = 'person-factoid') then
    spear:person-data($model("data"))
else $model("data")
};

declare function spear:place-data($data){
let $placeInfo := $data/tei:div[not(tei:listEvent)]
return 
    if(not(empty($placeInfo))) then
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Place Information</h4>
                 <!--
                 <div class="btn-group pull-right">
                     <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort<span class="caret"/></button>
                         <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                             <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="manuscript">Textual</a></li>
                             <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="date">Chronological</a></li>
                         </ul>
                     </div>
                 </div>
                 -->
             </div>
             <div class="panel-body">
                {global:tei2html(
                    <factoid xmlns="http://www.tei-c.org/ns/1.0">
                        {$placeInfo}
                    </factoid>)}
             </div>
        </div>

    else ()       
};                            
                       
declare function spear:person-data($data){
let $personInfo := $data/tei:div[not(tei:listEvent)]
return 
    if(not(empty($personInfo))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Person Information</h4>
                 <!--
                 <div class="btn-group pull-right">
                     <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort<span class="caret"/></button>
                         <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                             <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="manuscript">Textual</a></li>
                             <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="date">Chronological</a></li>
                         </ul>
                     </div>
                 </div>
                 -->
             </div>
             <div class="panel-body">
                {global:tei2html(
                    <factoid xmlns="http://www.tei-c.org/ns/1.0">
                        {$personInfo}
                    </factoid>)}
             </div>
        </div>
    else ()
};

declare %templates:wrap function spear:relationships($node as node(), $model as map(*)){
let $relation := $model("data")//tei:listRelation
return 
    if(not(empty($relation))) then 
        rel:build-relationships($relation,'')
    else ()
};

(: NOTE: add footnotes to events panel :)
declare %templates:wrap function spear:events($node as node(), $model as map(*)){
  if($model("data")//tei:listEvent) then
    let $events := $model("data")//tei:listEvent/descendant::tei:event
    return
        (ev:build-timeline($events,'events'),
        ev:build-events-panel($events))
  else ()  
};

(:~
 : Checks link to related record
:)
declare function spear:srophe-related($node as node(), $model as map(*)){
    let $data := $model("data")
    let $rec-exists := spear:canonical-rec()  
    let $type := string($rec-exists/ancestor::tei:place/@type)
    let $geo := $rec-exists/ancestor::tei:body//tei:geo
    let $abstract := $rec-exists/ancestor::tei:body//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $rec-exists/ancestor::tei:body//tei:note[@type='abstract']
    return
        if($rec-exists) then
            <div class="panel panel-default">
                 <div class="panel-heading clearfix">
                     <h4 class="panel-title">{if(contains($spear:id,'person')) then 'From Persons database' else 'From The Syriac Gazetteer' }</h4>
                 </div>
                 <div class="panel-body">
                 {(if($geo) then 
                    <div>
                        <div>
                            {geo:build-map($geo,'','')}
                        </div>
                        <div>
                            <div id="type">
                                 <p><strong>Place Type: </strong>
                                     <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
                                 </p>
                             </div>
                             {
                                if($data//tei:location) then
                                    <div id="location">
                                        <h4>Location</h4>
                                        <ul>
                                        {
                                            for $location in $data//tei:location
                                            return global:tei2html($location)
                                        }
                                        </ul>
                                    </div>
                                else ()
                                }
                        </div>    
                    </div>
                else (),
                <div class="indent">
                    {global:tei2html(<factoid xmlns="http://www.tei-c.org/ns/1.0">{$abstract}</factoid>)}
                </div>    
                )}
               <p><hr/>View full entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Persons database' else 'The Syriac Gazetteer' }</a></p>
                 </div>
            </div> 
        else ()    
};

(:~     
 : Find related factoids
:)
declare function spear:related-factiods($node as node(), $model as map(*)){
let $data := $model("data")
return
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] or $data/descendant::tei:persName or $data/descendant::tei:placeName) then 
        <div class="panel panel-default">
            <div class="panel-heading clearfix">
                <h4 class="panel-title">Related Factoids</h4>
            </div>
            <div class="panel-body">
            {
            if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id]) then
        <div class="well">
        <h4>Additional Attestations</h4>
            <ul class="list-unstyled">
            {
                for $factoids in $data/ancestor::tei:body//tei:ref[@type='related-persons-places'][@target=$spear:id]
                let $id := string($factoids/@ref)
                return
                    <li><a href="factoid.html?id={$id}">{$factoids}</a></li>
            }
            </ul>
        
        </div>
    else(),
    if($data/descendant::tei:persName) then 
        let $persNames := distinct-values($data/descendant::tei:persName/@ref)
        let $count := count($persNames)
        return 
        <div>
            <h4>Related Person(s) {$count}</h4>
                <div class="facet-list show">
                <ul>
                {
                    for $r in subsequence($persNames,1,5)
                    return 
                        <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                }</ul>
                </div>
                {
                    if($count gt 5) then
                        (<div class="facet-list collapse" id="show-person">
                            <ul>
                            {
                            for $r in subsequence($persNames,5,$count + 1)
                            return 
                                  <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                            }
                            </ul>
                        </div>,
                        <a class="facet-label togglelink btn btn-info" 
                        data-toggle="collapse" data-target="#show-person" href="#show-person" 
                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                    else ()
                }
        </div>    
    else(),
    if($data/descendant::tei:placeName) then
        let $placeNames := distinct-values($data/descendant::tei:placeName/@ref)
        let $count := count($placeNames)
        return 
        <div>
            <h4>Related Places(s) {$count}</h4>
                <div class="facet-list show">
                 <ul>
                {
                    for $r in subsequence($placeNames,1,5)
                    return 
                        <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                }</ul>
                </div>
                {
                    if($count gt 5) then
                        (<div class="facet-list collapse" id="show-person">
                            <ul>
                            {
                            for $r in subsequence($placeNames,5,$count + 1)
                            return 
                                  <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                            }
                            </ul>
                        </div>,
                        <a class="facet-label togglelink btn btn-info" 
                        data-toggle="collapse" data-target="#show-person" href="#show-person" 
                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                    else ()
                }
        </div>
    else()
            }
            </div>
        </div>
    else ()        
};

declare function spear:get-title($uri){
let $doc := collection('/db/apps/srophe-data/data')/range:field-eq("uri", concat($uri,"/tei"))[1]
return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ',' ')
      else $uri 
};

(:~           
 : Build footnotes   
 : Better handling of footnotes, should only return 1 tei:back (currently returns on for each factoid)
:)
declare %templates:wrap function spear:bibl($node as node(), $model as map(*)){
let $data := $model("data")
let $bibl := $data/tei:div[@uri]/descendant::tei:bibl
let $sources :=
                <sources xmlns="http://www.tei-c.org/ns/1.0">
                    {
                    for $b in distinct-values($bibl/descendant::tei:ptr/@target)
                    let $id := substring-after($b,'#')
                    return 
                        if($data//tei:back) then 
                            for $bibl in $data//tei:back/descendant-or-self::tei:bibl[@xml:id = $id][1]
                            return $bibl
                        else 
                            for $bibl in collection($global:data-root || "/spear/tei")//tei:bibl[@xml:id = $id][1]
                            return $bibl
                        }
                </sources>
return global:tei2html(<spear-citation xmlns="http://www.tei-c.org/ns/1.0">{($bibl,$sources)}</spear-citation>)
};


(:
 : Home page timeline
:)

declare %templates:wrap function spear:get-event-data($node as node(), $model as map(*)){
let $events :=  collection($global:data-root || "/spear/tei")//tei:event[parent::tei:listEvent]
return 
     map {"data" := $events}
};
  
declare %templates:wrap function spear:build-event-timeline($node as node(), $model as map(*)){
let $events := $model("data")
return
    ev:build-timeline($events,'events')
};

