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
    else if(contains($spear:id, '/keyword')) then 'keyword-factoid'
    else if(contains($spear:id, '/spear')) then 'source-factoid'
    else 'event-factoid'
else 'all-events'
};    

(:~
 : Build spear view
 : @param $id spear URI
 :)       
declare %templates:wrap function spear:get-rec($node as node(), $model as map(*), $view as xs:string?){ 
let $id :=
        if(contains($app:id,$global:base-uri) or starts-with($app:id,'http://')) then $app:id
        else if(contains(request:get-uri(),$global:nav-base)) then replace(request:get-uri(),$global:nav-base, $global:base-uri)
        else if(contains(request:get-uri(),$global:base-uri)) then request:get-uri()
        else $app:id
let $id := if(ends-with($id,'.html')) then substring-before($id,'.html') else $id  
return 
    if($view = 'aggregate') then
        map {"data" :=  
        <aggregate xmlns="http://www.tei-c.org/ns/1.0" id="{$id}">
            {
                if($spear:item-type = 'source-factoid') then 
                    for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = concat($id,'/tei')]/ancestor::tei:TEI
                    return $rec                  
                else
                    for $rec in collection($global:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$app:id or @target=$app:id]]                
                    return ($rec)  
            }
        </aggregate>}
    else  map {"data" :=  global:get-rec($id)}
    
};

(:~   
 : Checks for canonical record in Syriaca.org 
 : @param $spear:id 
:)
declare function spear:canonical-rec(){
    collection($global:data-root)//tei:idno[. = $spear:id]
};

declare function spear:title(){
global:tei2html(
    <spear-headwords xmlns="http://www.tei-c.org/ns/1.0">
        {spear:canonical-rec()/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]}
    </spear-headwords>)
};

(:~    
 : Build page title
 : Uses connical record from syriaca.org as title, otherwise uses spear data
:)
declare %templates:wrap function spear:h1($node as node(), $model as map(*)){
let $data := $model("data")
let $id := <idno type='URI' xmlns="http://www.tei-c.org/ns/1.0">{$spear:id}</idno>
return 
        if($spear:item-type = 'source-factoid') then 
            global:tei2html(
                <aggregate-source xmlns="http://www.tei-c.org/ns/1.0">
                    {$data/descendant::tei:titleStmt,$id}
                </aggregate-source>)
        else if($spear:item-type = 'keyword-factoid') then 
            global:tei2html(
                <keyword-title xmlns="http://www.tei-c.org/ns/1.0">
                    {$id}
                </keyword-title>)                
        else if($spear:item-type = ('person-factoid','place-factoid')) then 
            let $rec-exists := spear:canonical-rec()  
            let $title :=  $rec-exists/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]
            return 
            global:tei2html(
                <aggregate-title xmlns="http://www.tei-c.org/ns/1.0">
                    {$title, $id}
                </aggregate-title>)
        else             
            global:tei2html(
                <factoid-title xmlns="http://www.tei-c.org/ns/1.0">
                    {$id}
                </factoid-title>)







};
     
declare function spear:data($node as node(), $model as map(*), $view as xs:string?){
if($spear:item-type = 'place-factoid') then 
    (spear:relationships-aggregate($node,$model),
    spear:events($node,$model))
else if($spear:item-type = 'person-factoid') then
    (
    spear:person-data($model("data")),
    spear:relationships-aggregate($node,$model),
    spear:events($node,$model)
    )
else if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
    spear:source-data($model("data"))
else if($spear:item-type = 'keyword-factoid') then
    (
    spear:person-data($model("data")),
    spear:relationships-aggregate($node,$model),
    spear:events($node,$model)
    )   
else if($model("data")//tei:listRelation) then
    ( 
    <div class="bottom-padding indent">
        {spear:relationships($node,$model)}
    </div>,
    global:tei2html(  
       <factoid xmlns="http://www.tei-c.org/ns/1.0">
           {$model("data")}
       </factoid>)   
    )
else global:tei2html(  
    <factoid xmlns="http://www.tei-c.org/ns/1.0">
        {$model("data")}
    </factoid>)
                    
};

(: 
    How to list all the factoids?
    should have the options of by type, in order and using 'advance browse options?'   
:)
declare function spear:source-data($data){
(<div class="panel panel-default">
    <div class="panel-heading clearfix">
        <h4 class="panel-title pull-left" style="padding-top: 7.5px;">About {global:tei2html($data/descendant::tei:titleStmt/tei:title[1])}</h4>
    </div>
    <div class="panel-body">
        {global:tei2html(<spear-titleStmt xmlns="http://www.tei-c.org/ns/1.0">{$data/descendant::tei:titleStmt}</spear-titleStmt>)}
        <div>
            <ul>
                <li>Person Factoids: {count($data/descendant::tei:div[tei:listPerson])}</li>
                <li>Relationship Factoids: {count($data/descendant::tei:div[tei:listRelation])}</li>
                <li>Event Factoids: {count($data/descendant::tei:div[tei:listEvent])}</li>
            </ul>
        </div>
    </div>
</div>,
<div class="panel-group">
  <div class="panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">
        <a data-toggle="collapse" href="#persons">Person Factoids ({count($data/descendant::tei:div[tei:listPerson])})</a>
      </h4>
    </div>
    <div id="persons" class="panel-collapse collapse">
      <div class="panel-body">{
        let $personInfo := $data/descendant::tei:div[tei:listPerson] 
        return  global:tei2html(
                    <aggregate xmlns="http://www.tei-c.org/ns/1.0">
                        {$personInfo}
                    </aggregate>)
        }
    </div>                    
  </div>
  </div>
  <div class="panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">
        <a data-toggle="collapse" href="#relationships">Relationship Factoids ({count($data/descendant::tei:div[tei:listRelation])})</a>
      </h4>
    </div>
    <div id="relationships" class="panel-collapse collapse">
      <div class="panel-body">{ 
        let $relation := $data/descendant::tei:div/tei:listRelation
        for $r in $relation/descendant::tei:relation
        return <p>{rel:build-short-relationships-list($r, $spear:id)}</p>
        }
    </div>                    
  </div>
  </div>
  <div class="panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">
        <a data-toggle="collapse" href="#events">Event Factoids ({count($data/descendant::tei:div[tei:listEvent])})</a>
      </h4>
    </div>
    <div id="events" class="panel-collapse collapse">
      <div class="panel-body">{
        let $events := $data/descendant::tei:div/tei:listEvent/descendant::tei:event 
        return   
        (ev:build-timeline($events,'events'),
        ev:build-events-panel($events))
        }
    </div>                    
  </div>
  </div>  
</div>,
(:Sources:)
global:tei2html(<spear-sources xmlns="http://www.tei-c.org/ns/1.0">{$data/descendant::tei:back/descendant::tei:bibl}</spear-sources>))
  
};

declare function spear:person-data($data){
let $personInfo := $data//tei:div[tei:listPerson/child::*/tei:persName[1][@ref=$app:id]] 
return 
    if(not(empty($personInfo))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Person Factoids about {spear:title()}</h4>
             </div>
             <div class="panel-body">
                {global:tei2html(
                    <aggregate xmlns="http://www.tei-c.org/ns/1.0">
                        {$personInfo}
                    </aggregate>)}
             </div>
        </div>
    else ()
};

declare %templates:wrap function spear:relationships-aggregate($node as node(), $model as map(*)){
let $relations := 
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@active, concat($spear:id,"(\W|$)"))]] |
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@passive, concat($spear:id,"(\W|$)"))]] |
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@mutual, concat($spear:id,"(\W|$)"))]]
let $count := count($relations)   
let $relation := subsequence($relations,1,20)
return  
    if(not(empty($relation))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Relationship Factoids about {spear:title()}</h4>
             </div>
             <div class="panel-body">
                <div class="indent">
                    {
                       rel:build-short-relationships-list($relation, $spear:id),
                       if($count gt 20) then 
                           <a href="#" class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="{$global:nav-base}/spear/search.html?relation={$spear:id}&amp;perpage={$count}&amp;sort=alpha" 
                            data-label="See all {$count} &#160; Relationships" id="related-names">See all {$count} relationships <i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                       else ()
                    }
                </div>
            </div>
        </div>            
    else ()
};

declare %templates:wrap function spear:relationships($node as node(), $model as map(*)){
let $relation := $model("data")//tei:listRelation
for $r in $relation/descendant::tei:relation
return rel:build-short-relationships($r,'')
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
 : NOTE: this is really the cononical, not the related... should have two, on for factoids, one for 
 aggrigate?  
 Checks link to related record
:)
declare function spear:srophe-related($node as node(), $model as map(*), $view as xs:string?){
if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
    <div class="panel panel-default">
        <div class="panel-heading clearfix">
            <h4 class="panel-title">NHSL Record information</h4>
        </div>
        <div class="panel-body">
        
         </div>
    </div>      
else
    let $data := $model("data")
    let $rec-exists := spear:canonical-rec()  
    let $type := string($rec-exists/ancestor::tei:place/@type)
    let $geo := $rec-exists/ancestor::tei:body//tei:geo
    let $abstract := $rec-exists/ancestor::tei:body//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $rec-exists/ancestor::tei:body//tei:note[@type='abstract']
    return
        if($rec-exists) then
            <div class="panel panel-default">
                 <div class="panel-heading clearfix">
                     <h4 class="panel-title">About {spear:title()}</h4>
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
               <p><hr/>View full entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Syriac Biographical Dictionary' else 'The Syriac Gazetteer' }</a></p>
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
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] or $data/descendant::tei:persName or $data/descendant::tei:placeName or $data/descendant::tei:relation) then 
        <div class="panel panel-default">
            <div class="panel-heading clearfix">
                <h4 class="panel-title">Related Persons, Places and Keywords</h4>
            </div>
            <div class="panel-body">
            {
                let $relations := distinct-values(tokenize(string-join(($data/descendant::*/@ref,
                                    $data/descendant::*/@target,
                                    $data/descendant::tei:relation/@mutual,
                                    $data/descendant::tei:relation/@active,
                                    $data/descendant::tei:relation/@passive),' '),' '))
                let $persNames := $relations[contains(.,'/person/')]
                let $placeNames := $relations[contains(.,'/place/')]
                let $keywords := $relations[contains(.,'/keyword/')]
                let $count-persons := count($persNames)
                let $count-places := count($placeNames)
                let $count-keywords := count($keywords)
                return 
                    (
                    if($count-persons gt 0) then 
                        <div>
                            <h4>Related Person(s) {$count-persons}</h4>
                            <div class="facet-list show">
                                <ul>
                                    {
                                        for $r in subsequence($persNames,1,5)
                                        return 
                                            <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                    }
                                </ul>
                             </div>
                              {
                                    if($count-persons gt 5) then
                                        (<div class="facet-list collapse" id="show-person">
                                            <ul>
                                            {
                                            for $r in subsequence($persNames,6,$count-persons + 1)
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
                    if($count-places gt 0) then                        
                        <div>
                            <h4>Related Places(s) {$count-places}</h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($placeNames,1,5)
                                            return 
                                                <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                        }
                                    </ul>
                                </div>
                                {
                                    if($count-places gt 5) then
                                        (<div class="facet-list collapse" id="show-places">
                                            <ul>
                                            {
                                            for $r in subsequence($placeNames,6,$count-places + 1)
                                            return 
                                                  <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                            }
                                            </ul>
                                        </div>,
                                        <a class="facet-label togglelink btn btn-info" 
                                        data-toggle="collapse" data-target="#show-places" href="#show-places" 
                                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                                    else ()
                                }
                        </div>
                    else (),
                    if($count-keywords gt 0) then                        
                        <div>
                            <h4>Related Keyword(s) {$count-keywords}</h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($keywords,1,5)
                                            return 
                                                <li><a href="aggregate.html?id={$r}">{substring-after($r,'/keyword/')}</a></li>
                                        }
                                    </ul>
                                </div>
                                {
                                    if($count-keywords gt 5) then
                                        (<div class="facet-list collapse" id="show-keywords">
                                            <ul>
                                            {
                                            for $r in subsequence($keywords,6,$count-keywords + 1)
                                            return 
                                                  <li><a href="aggregate.html?id={$r}">{substring-after($r,'/keyword/')}</a></li>
                                            }
                                            </ul>
                                        </div>,
                                        <a class="facet-label togglelink btn btn-info" 
                                        data-toggle="collapse" data-target="#show-keywords" href="#show-keywords" 
                                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                                    else ()
                                }
                        </div>
                    else ())     
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

