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
 : Build persons view
 : @param $id persons URI
 :)
declare %templates:wrap function spear:get-rec($node as node(), $model as map(*)){
    app:get-rec($node, $model, 'spear')
};

(:~
 : Traverse main nav and "fix" links based on values in config.xml 
:)
declare
    %templates:wrap
function spear:fix-links($node as node(), $model as map(*)) {
    templates:process(global:fix-links($node/node()), $model)
};

(: @depricated :)
declare function spear:build-doc-path(){ 
if($spear:id != '') then 
    if(starts-with($spear:id,'http://syriaca.org/spear/')) then
       collection($global:data-root || "/spear/tei")//tei:div[@uri = $spear:id]
    else if(starts-with($spear:id,'http://syriaca.org')) then  
        collection($global:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$spear:id]]
    else
        let $id := concat('http://syriaca.org/spear/',$spear:id)
        return
        collection($global:data-root || "/spear/tei")//tei:div[@uri = $id]
else if($spear:view = 'person') then collection($global:data-root || "/spear/tei")//tei:persName
else if($spear:view = 'place') then collection($global:data-root || "/spear/tei")//tei:placeName
else if($spear:view = 'event') then collection($global:data-root || "/spear/tei")//tei:div[tei:listEvent]
else if($spear:view = 'all') then collection($global:data-root || "/spear/tei")//tei:div
else util:eval(concat("collection('",$global:data-root,"/spear/tei')//tei:div"))
};


(: possibly depreicated:)
declare %templates:wrap function spear:get-event-data($node as node(), $model as map(*)){
let $events :=  collection($global:data-root || "/spear/tei")//tei:event[parent::tei:listEvent]
return 
     map {"data" := $events}
};

(: possibly depreicated:)
declare %templates:wrap function spear:build-event-timeline($node as node(), $model as map(*)){
let $events := $model("data")
return
    ev:build-timeline($events,'events')
};

declare %templates:wrap function spear:uri($node as node(), $model as map(*)){
    string($spear:id)
};

(:~
 : Builds TEI for output
:)
declare function spear:get-tei($id as xs:string){
    <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">
        {
            for $rec in collection($global:data-root || "/spear/tei")//tei:div[@uri = $spear:id]
            return $rec
        }
    </tei:TEI>
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
    let $data := $model("data")[1]
    let $rec-exists := spear:canonical-rec()  
    let $title :=  
        if($rec-exists) then $rec-exists/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]
        (:
        else if($data/tei:listPerson) then $data/tei:listPerson/descendant::tei:persName[1]
        else if($data/tei:placeName[1]) then $data/descendant::tei:placeName[1]
        else if(contains($spear:id,'/person/')) then $data/descendant::tei:persName[1]
        else if(contains($spear:id,'/place/')) then $data/descendant::tei:placeName[1]
        else if($data/tei:listEvent) then 'Event'
        :)
        else <title xmlns="http://www.tei-c.org/ns/1.0">Factoid</title>
    let $id := <idno type='URI' xmlns="http://www.tei-c.org/ns/1.0">{$spear:id}</idno>
    return global:tei2html(
                <srophe-title xmlns="http://www.tei-c.org/ns/1.0">
                    {$title, $id}
                </srophe-title>)
};

(:
 : Add related items to sidebar
 : NOTE, when there is a title to grab from spear, make all events from $title dynamic
:)
declare %templates:wrap function spear:related($node as node(), $model as map(*)){
    if(starts-with($spear:id,'http://syriaca.org/spear/')) then 
        spear:related-factiods($node,$model) 
    else (spear:related-rec($node, $model),<div class="well">{spear:related-factiods($node,$model)}</div> )
};

(:~
 : Find related factoids
:)
declare function spear:related-factiods($node as node(), $model as map(*)){
let $data := $model("data")
return
    (
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] or $data/descendant::tei:persName or $data/descendant::tei:placeName) then <h3>Related Factoids</h3> 
    else (),
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
        <div class="well"><h4>Related Person(s)</h4>
        <ul class="list-unstyled">{
            for $persons in $data/descendant::tei:persName
            let $id := $persons/@ref
            group by $person := $id
            return
                <li><a href="factoid.html?id={string($id[1])}">{$persons[1]}</a></li>
            }
        </ul></div>    
    else(),
    if($data/descendant::tei:placeName) then 
        <div class="well"><h4>Related Place(s)</h4>
        <ul class="list-unstyled">{
            for $place in $data/descendant::tei:placeName
            let $id := $place/@ref
            group by $place := $id
            return
                <li><a href="factoid.html?id={string($id[1])}">{$place[1]}</a></li>
              }  
         </ul>
         </div>
    else())        
};

(:~
 : Checks link to related record
:)
declare function spear:related-rec($node as node(), $model as map(*)){
    let $data := $model("data")[1]
    let $rec-exists := spear:canonical-rec()  
    let $type := string($rec-exists/ancestor::tei:place/@type)
    let $geo := $rec-exists/ancestor::tei:body//tei:geo
    let $abstract := $rec-exists/ancestor::tei:body//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $rec-exists/ancestor::tei:body//tei:note[@type='abstract']
    return
        if($rec-exists) then
            <div class="well">
             <h3>{if(contains($spear:id,'person')) then 'From Persons database' else 'From The Syriac Gazetteer' }</h3>
                {
                (if($geo) then 
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
                global:tei2html($abstract)
                )
                }
               <p><hr/>View full entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Persons database' else 'The Syriac Gazetteer' }</a></p>
            </div> 
        else ()    
};

declare %templates:wrap function spear:names($node as node(), $model as map(*)){
if($spear:item-type = 'person-factoid' and $model("data")//tei:listPerson/tei:person/tei:persName) then 
    <div id="persnames" class="well">
    {
    for $persName in $model("data")//tei:listPerson/tei:person/tei:persName
    return 
        if($persName/text() or $persName/child::*) then
            <span dir="ltr" class="label label-default pers-label">{global:tei2html($persName)}</span>
        else ()   
    }
    </div>
else ()   
};

(:~
 : Test for timeline inclusion
:)
declare %templates:wrap function spear:timeline($node as node(), $model as map(*), $dates){
if($spear:item-type = 'event-factoid') then ()
else spear:build-timeline($node, $model, $dates)        
};

(:~ 
 : Include timeline and events list view in xql to adjust for event/person/place view
:)
declare function spear:build-timeline($node as node()*, $model as map(*), $dates){
let $data := $model("data")
    return
     if($dates = 'personal') then 
         if($data//tei:birth[@when or @notBefore or @notAfter] or $data//death[@when or @notBefore or @notAfter] or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
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
                                     <li>{global:tei2html($date)}</li>
                                 }
                             </ul>
                         </div>
                     </div>
         else ()
      else if($dates = 'events') then
         <div class="timeline">
             <div>{timeline:timeline($data//tei:event, 'Events Timeline')}</div>
         </div>
      else ()  
};

declare function spear:build-events-panel($node as node(), $model as map(*)){
<div class="panel panel-default">
    <div class="panel-heading clearfix">
        <h4 class="panel-title pull-left" style="padding-top: 7.5px;">
        {if($spear:view='event') then 'Events' else if($spear:id !='') then 'Events' else 'All Factoids'}
        </h4>
        <!-- Sort options for events list -->
        <div class="btn-group pull-right">
            <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort<span class="caret"/></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                    <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="manuscript">Textual</a></li>
                    <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="date">Chronological</a></li>
                </ul>
            </div>
        </div>
    </div>
    <div class="panel-body">
        {spear:events($node,$model)}
    </div>
</div>
};

declare %templates:wrap function spear:build-events-list($node as node(), $model as map(*)){
if($model("data")//tei:event) then 
    if($spear:item-type = 'event-factoid') then ()
    else spear:build-events-panel($node, $model)
else ()    
};

(:  
 : Pass all additional data to html page
  
:)
declare %templates:wrap function spear:data($node as node(), $model as map(*)){
let $data := $model("data")//tei:div[@uri]
return
    if($data//tei:listRelation) then 
        rel:build-relationships($model("data")//tei:listRelation,'')
    else 
        global:tei2html(
            <factoid xmlns="http://www.tei-c.org/ns/1.0" type="{$spear:item-type}">
                {$data}
            </factoid>)
         
};

declare %templates:wrap function spear:dates($node as node(), $model as map(*)){
let $data := $model("data")
return 
    if($data//tei:birth or $data//tei:death or $data//tei:floruit or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
        (
            <h4>Dates</h4>,
            <ul class="list-unstyled">
            {
                for $date in $data//tei:birth | $data//tei:death | $data//tei:floruit | $data//tei:state[@when or @notBefore or @notAfter or @to or @from]
                return 
                    <li>{global:tei2html($date)}</li>
                }
            </ul>
        )
    else ()
};
               
(:~
 : Build bibliography                    
:)
declare %templates:wrap function spear:bibl($node as node(), $model as map(*)){
let $sources := $model("data")
let $bibl := $sources/tei:div[@uri]/descendant::tei:bibl
let $sources :=
                <sources xmlns="http://www.tei-c.org/ns/1.0">
                    {
                    for $b in $bibl/descendant::tei:ptr/@target
                    return $sources//tei:back/descendant::tei:bibl[@xml:id = substring-after($b,'#')]
                    }
                </sources>
return global:tei2html(<spear-citation xmlns="http://www.tei-c.org/ns/1.0">{($bibl, $sources)}</spear-citation>)
};

declare %templates:wrap function spear:citation($node as node(), $model as map(*)){
let $citation := $model("data")[1]
return global:tei2html($citation)
}; 

declare function spear:events($node as node(), $model as map(*)){
<div id="events-list">
    {
    let $data := $model("data")
    return
    if($spear:sort = 'date') then
        <ul>
        {
            for $event in $data//tei:event
            let $date := substring($event/descendant-or-self::tei:date[1]/@syriaca-computed-start,1,2)
            group by $date
            order by $date ascending
            return
            <li>
                <h4>
                {
                    if(starts-with($date,'-')) then 'BC Dates'
                    else if($date != '') then concat(substring-after($date,'0'),'00') 
                    else 'Date Unknown'
                }
                </h4>
                <ul>
                    {
                        for $e in $event
                        return 
                         <li class="md-line-height">{global:tei2html($e)} 
                            {
                            if($spear:item-type != 'event-factoid') then 
                                <a href="factoid.html?id={string($e/ancestor::tei:div/@uri)}">
                                    See event page
                                    <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span>
                                </a>
                            else ()
                            }
                        </li>
                    }
                </ul>    
            </li>
         }
         </ul>
    else  
        <ul>
        {
            for $e in $data//tei:event
            (:for $e in $event//tei:desc:)
            return 
            <li class="md-line-height">{global:tei2html($e)} 
                {
                if($spear:item-type != 'event-factoid') then 
                    <a href="factoid.html?id={string($e/ancestor::tei:div/@uri)}">
                        See event page 
                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span>
                    </a>
                else ()
                }
            </li>
         }
        </ul>
         }
</div>
};
