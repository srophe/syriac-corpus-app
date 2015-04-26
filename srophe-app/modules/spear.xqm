(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace spear="http://syriaca.org//spear";

import module namespace facets="http://syriaca.org//facets" at "lib/facets.xqm";
import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";
import module namespace d3="http://syriaca.org//d3" at "d3.xqm";

import module namespace timeline="http://syriaca.org//timeline" at "lib/timeline.xqm";

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

declare function spear:build-doc-path(){ 
if($spear:id != '') then 
    if(starts-with($spear:id,'http://syriaca.org/spear/')) then
       collection($config:data-root || "/spear/tei")//tei:div[@uri = $spear:id]
    else collection($config:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$spear:id]]
else if($spear:view = 'person') then collection($config:data-root || "/spear/tei")//tei:persName
else if($spear:view = 'place') then collection($config:data-root || "/spear/tei")//tei:placeName
else if($spear:view = 'event') then collection($config:data-root || "/spear/tei")//tei:div[tei:listEvent]
else if($spear:view = 'all') then collection($config:data-root || "/spear/tei")//tei:div
else util:eval(concat("collection('",$config:data-root,"/spear/tei')//tei:div",facets:facet-filter()))
};

(:~
 : Holding place
 : Value passed through metadata:page-title() 
 : NOTE need to work out the logic here
:)
declare function spear:html-title(){
   'SPEAR'
};

(:~
 : Build persons view
 : @param $id persons URI
 :)
declare %templates:wrap function spear:get-spear-data($node as node(), $model as map(*)){
     map {"spear-data" := spear:build-doc-path()}
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
            for $rec in collection($config:data-root || "/spear/tei")//tei:div[@uri = $spear:id]
            return $rec
        }
    </tei:TEI>
};

(:~
 : Checks for canonical record in Syriaca.org 
 : @param $spear:id 
:)
declare function spear:canonical-rec(){
    collection($config:data-root)//tei:idno[. = $spear:id]
};

(:~
 : Build page title
 : Uses connical record from syriaca.org as title, otherwise uses spear data
:)
declare %templates:wrap function spear:h1($node as node(), $model as map(*)){
    let $data := $model("spear-data")[1]
    let $rec-exists := spear:canonical-rec()  
    let $title :=  
        if($rec-exists) then $rec-exists/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]
        else if($data/tei:listPerson) then $data/tei:listPerson/descendant::tei:persName[1]
        else if($data/tei:placeName[1]) then $data/descendant::tei:placeName[1]
        else if(contains($spear:id,'/person/')) then $data/descendant::tei:persName[1]
        else if(contains($spear:id,'/place/')) then $data/descendant::tei:placeName[1]
        else if($data/tei:listEvent) then 'Event'
        else $data/tei:listPerson/descendant::tei:persName[1] | $data/descendant::tei:placeName[1]
    let $id := <idno xmlns="http://www.tei-c.org/ns/1.0">{$spear:id}</idno>
    return app:tei2html(
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
        <div class="well">{spear:related-factiods($node,$model)}</div>    
    else (spear:related-rec($node, $model),<div class="well">{spear:related-factiods($node,$model)}</div> )
};

(:~
 : Find related factoids
:)
declare function spear:related-factiods($node as node(), $model as map(*)){
let $data := $model("spear-data")
return
    (
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] or $data/descendant::tei:persName or $data/descendant::tei:placeName) then <h3>Related Factoids</h3> 
    else (),
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id]) then
        (<h4>Additional Attestations</h4>,
            <ul class="list-unstyled">
            {
                for $factoids in $data/ancestor::tei:body//tei:ref[@type='related-persons-places'][@target=$spear:id]
                let $id := string($factoids/@ref)
                return
                    <li><a href="factoid.html?id={$id}">{$factoids}</a></li>
            }
            </ul>
        )
    else(),
    if($data/descendant::tei:persName) then 
        (<h4>Related Person(s)</h4>,
        <ul class="list-unstyled">{
            for $persons in $data/descendant::tei:persName
            let $id := $persons/@ref
            group by $person := $id
            return
                <li><a href="factoid.html?id={string($id[1])}">{$persons[1]}</a></li>
            }
        </ul>)     
    else(),
    if($data/descendant::tei:placeName) then 
        (<h4>Related Place(s)</h4>,
        <ul class="list-unstyled">{
            for $place in $data/descendant::tei:placeName
            let $id := $place/@ref
            group by $place := $id
            return
                <li><a href="factoid.html?id={string($id[1])}">{$place[1]}</a></li>
              }  
         </ul>
         )
    else())        
};

(:~
 : Checks link to related record
:)
declare function spear:related-rec($node as node(), $model as map(*)){
    let $data := $model("spear-data")[1]
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
                                            return app:tei2html($location)
                                        }
                                        </ul>
                                    </div>
                                else ()
                                }
                        </div>    
                    </div>
                else (),
                app:tei2html($abstract)
                )
                }
               <p><hr/>View full entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Persons database' else 'The Syriac Gazetteer' }</a></p>
            </div> 
        else ()    
};

declare %templates:wrap function spear:names($node as node(), $model as map(*)){
if($spear:item-type = 'person-factoid' and $model("spear-data")//tei:listPerson/tei:person/tei:persName) then 
    <div id="persnames" class="well">
    {
    for $persName in $model("spear-data")//tei:listPerson/tei:person/tei:persName
    return 
        if($persName/text() or $persName/child::*) then
            <span dir="ltr" class="label label-default pers-label">{app:tei2html($persName)}</span>
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
declare function spear:build-timeline($node as node(), $model as map(*), $dates){
let $data := $model("spear-data")
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
                                     <li>{app:tei2html($date)}</li>
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
if($model("spear-data")//tei:event) then 
    if($spear:item-type = 'event-factoid') then ()
    else spear:build-events-panel($node, $model)
else ()    
};

(:  
 : Pass all additional data to html page
  
:)
declare %templates:wrap function spear:data($node as node(), $model as map(*)){
let $data := $model("spear-data")
return
app:tei2html(
    <factoid xmlns="http://www.tei-c.org/ns/1.0" type="{$spear:item-type}">
        {
         if($spear:item-type = 'event-factoid') then $data
        else $data[not(tei:listEvent)]}
    </factoid>)
};

declare %templates:wrap function spear:dates($node as node(), $model as map(*)){
let $data := $model("spear-data")
return 
    if($data//tei:birth or $data//tei:death or $data//tei:floruit or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
        (
            <h4>Dates</h4>,
            <ul class="list-unstyled">
            {
                for $date in $data//tei:birth | $data//tei:death | $data//tei:floruit | $data//tei:state[@when or @notBefore or @notAfter or @to or @from]
                return 
                    <li>{app:tei2html($date)}</li>
                }
            </ul>
        )
    else ()
};

(:~
 : Build bibliography 
:)
declare %templates:wrap function spear:bibl($node as node(), $model as map(*)){
let $sources := $model("spear-data")[1]
let $bibl := $sources/descendant::tei:bibl
let $back-info := $sources/ancestor::tei:text/tei:back
return app:tei2html(<body xmlns="http://www.tei-c.org/ns/1.0">{($bibl, $back-info)}</body>)
};

declare %templates:wrap function spear:citation($node as node(), $model as map(*)){
let $citation := $model("spear-data")[1]
return app:tei2html($citation)
}; 

declare function spear:events($node as node(), $model as map(*)){
(:add if spear:date then sort, else no sort
<span class="anchor"/>
:)
<div id="events-list">
    {
    let $data := $model("spear-data")
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
                         <li class="md-line-height">{app:tei2html($e)} 
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
            <li class="md-line-height">{app:tei2html($e)} 
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

declare %templates:wrap function spear:link-icons-list($node as node(), $model as map(*)){
let $data := $model("spear-data")
let $links:=
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data//tei:person//tei:idno, $data//tei:person//tei:location}
        </see-also>
   </body>
return app:tei2html($links)
};

declare %templates:wrap function spear:get-visualizations($node as node(), $model as map(*)){
let $relationships := $model("spear-data")
return
  d3:relationships($relationships)  
};

(:
 : Browse modules for spear
:)
(:
 : GROUP by pers/place sort events like event page (include event page code here, with a sort by source doc)
     for $facet in $nodes
    group by $facet-grp := $facet/@ref
    order by count($facet) descending
:)
declare %templates:wrap function spear:browse-facets($node as node(), $model as map(*)) {
    <div style="margin:1em;">
         <h4>Narrow by</h4>
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title
            return facets:facets($facets)
         }
    </div>
};

(:
 : SPEAR Browse options
:)
declare %templates:wrap function spear:browse-spear($node as node(), $model as map(*)){
if($spear:view = 'person') then 
<div class="row">
    <div class="col-md-3">
        <div style="margin:1em;">
         <h4>Narrow by Source Text</h4>
         <span class="facets applied">
                {
                    if($facets:fq) then facets:selected-facet-display()
                    else ()            
                }
         </span>
         <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title
            return 
            <li>{facets:title($facets)}</li>
         }
         </ul>
        </div>
    </div>
    <div class="col-md-9">
        <h3>{$spear:sort}</h3>
        <ul class="left-padding top-padding">
            {
                for $data in $model('spear-data')
                let $id := normalize-space($data[1]/@ref)
                let $connical := collection($config:data-root)//tei:idno[. = $id]
                let $name := if($connical) then $connical/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"][@xml:lang='en'][1]
                             else tokenize($id,'/')[last()]
                group by $person := $name
                order by $person
                return 
                    if($spear:sort = 'all' or empty($spear:sort)) then 
                        for $pers-data in $person[1] 
                        return 
                        <li>
                            <a href="factoid.html?id={$id}">{$data[1]}</a>
                        </li>
                    else
                        for $pers-data in $person[1]
                        where contains(spear:get-sort(), substring($name,1,1)) 
                        return 
                        <li>
                            <a href="factoid.html?id={$id}">{$data[1]}</a>
                        </li>            
            }
        </ul>
    </div>
</div>
else if($spear:view = 'event') then
<div class="row">
    <div class="col-md-3">
        <div style="margin:1em;">
         <h4>Narrow by Source Text</h4>
         <span class="facets applied">
                {
                    if($facets:fq) then facets:selected-facet-display()
                    else ()            
                }
         </span>
         <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title
            return 
            <li>{facets:title($facets)}</li>
         }
         </ul>
        </div>
    </div>
    <div class="col-md-9 top-padding">
        <div>
            {(spear:build-timeline($node,$model,'events'),spear:build-events-panel($node,$model))}
        </div>
    </div>
</div>
else if($spear:view = 'keywords') then
<div class="row">
    <div class="col-md-3">
        <div style="margin:1em;">
         <h4>Narrow by Keyword</h4>
         <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes//tei:event
            return 
            <li>{facets:keyword($facets)}</li>
         }
         </ul>
        </div>
    </div>
    <div class="col-md-9 top-padding">
       <div class="top-padding" >
       {if($spear:fq != '') then 
        (<strong>Keywords</strong>,facets:selected-facet-display(),<hr/>)
        else ()
       } 
       <div>
        {
            for $data in $model('spear-data')
            let $id := $data/@uri
            return 
            <li class="md-line-height">
                {$data/child::*[not(self::tei:bibl)]}  <a href="factoid.html?id={string($data/@uri)}">See event page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span></a>
            </li>
        }
        </div>
        </div>
    </div>
</div>
else if($spear:view = 'sources') then
<div class="row">
    <div class="col-md-3">
        <div style="margin:1em;">
         <h4>Narrow by Source Text</h4>
         <span class="facets applied">
                {
                    if($facets:fq) then facets:selected-facet-display()
                    else ()            
                }
         </span>
         <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title
            return 
            <li>{facets:title($facets)}</li>
         }
         </ul>
        </div>
    </div>
    <div class="col-md-9 top-padding">
        <div class="top-padding" >
        {
            for $data in $model('spear-data')
            let $id := $data/@uri
            return 
            <li class="md-line-height">
                {$data/child::*[not(self::tei:bibl)]}  <a href="factoid.html?id={string($data/@uri)}">See event page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span></a>
            </li>
        }
        </div>
    </div>
</div>
else if($spear:view = 'advanced') then
<div>
 <h4>Advanced browse options: <a href="search.html?q=">see advanced search</a></h4>
</div>
else
<div class="row">
    <div class="col-md-3">
        <div style="margin:1em;">
         <h4>Narrow by Source Text</h4>
         <span class="facets applied">
                {
                    if($facets:fq) then facets:selected-facet-display()
                    else ()            
                }
         </span>
         <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
         {
            let $facet-nodes := $model('spear-data')
            let $facets := $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title
            return 
            <li>{facets:title($facets)}</li>
         }
         </ul>
        </div>
    </div>
    <div class="col-md-9">
        <h3>{$spear:sort}</h3>
        <ul class="left-padding top-padding">
            {
                for $data in $model('spear-data')
                let $id := normalize-space($data[1]/@ref)
                let $connical := collection($config:data-root)//tei:idno[. = $id]
                let $name := if($connical) then $connical/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"][@xml:lang='en'][1]
                             else tokenize($id,'/')[last()]
                group by $place := $name
                order by $place
                return 
                    if($spear:sort = 'all' or empty($spear:sort)) then 
                        for $place-data in $place[1] 
                        return 
                            <li>
                                <a href="factoid.html?id={$id}">{$place-data}</a>
                            </li>   
                    else
                        for $place-data in $place[1]
                        where contains(spear:get-sort(), substring($name,1,1)) 
                        return 
                            <li>
                                <a href="factoid.html?id={$id}">{$place-data}</a>
                            </li>
            }
        </ul>
    </div>
</div>

};

declare function spear:get-sort(){
    if(exists($spear:sort) and $spear:sort != '') then
        if($spear:sort = 'A') then 'A a ẵ Ẵ ằ Ằ ā Ā'
        else if($spear:sort = 'D') then 'D d đ Đ'
        else if($spear:sort = 'S') then 'S s š Š ṣ Ṣ'
        else if($spear:sort = 'E') then 'E e ễ Ễ'
        else if($spear:sort = 'U') then 'U u ū Ū'
        else if($spear:sort = 'H') then 'H h ḥ Ḥ'
        else if($spear:sort = 'T') then 'T t ṭ Ṭ'
        else if($spear:sort = 'I') then 'I i ī Ī'
        else if($spear:sort = 'O') then 'O Ō o Œ œ'
        else $spear:sort
    else 'A a ẵ Ẵ ằ Ằ ā Ā'
};

declare function spear:browse-abc-list($node as node(), $model as map(*)){
if(($spear:view = 'person') or ($spear:view='place')) then
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
            <li><a href="?view={$spear:view}&amp;sort=all">All</a></li>
            {
                let $vals := $model('spear-data')/upper-case(substring(normalize-space(.),1,1))
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    if(contains($vals,$letter)) then 
                    <li><a href="?view={$spear:view}&amp;sort={$letter}">{$letter}</a></li>
                    else <li>{$letter}</li>
            }
        </ul>
    </div>
else ()        
};

declare function spear:browse-tabs($node as node(), $model as map(*)){
    <ul class="nav nav-tabs" id="nametabs">
        <li>{if(not($spear:view)) then 
                attribute class {'active'} 
             else if($spear:view = 'place') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=place&amp;sort=all">Places</a>
        </li>
        <li>{if($spear:view = 'person') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=person&amp;sort=all">Persons</a>
        </li>
        <li>{if($spear:view = 'event') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=event">Events</a>
        </li>
        <li>{if($spear:view = 'keywords') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=keywords">Keywords</a>
        </li>
        <li>{if($spear:view = 'sources') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=sources">Sources</a>
        </li>
        <li>{if($spear:view = 'advanced') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=advanced">Advanced Browse</a>
        </li>
    </ul>
};

(:Places, Persons, Events, Keywords, Sources, Advanced Browse
declare function spear:get-visualizations($node as node(), $model as map(*)){
let $data := let $data := $model("spear-data")
return d3:relationships($data)
};
:)