(:~              
 : Builds spear page  
 :)
xquery version "3.0";

module namespace spear="http://syriaca.org/spear";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace ev="http://syriaca.org/events" at "lib/events.xqm";
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace functx="http://www.functx.com";

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
        else if(contains($spear:id, '/spear') and contains($spear:id, '-')) then 'factoid'
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
                    for $rec in 
                        collection($global:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$app:id or @target=$app:id]] |
                        collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@active, concat($spear:id,"(\W|$)"))]] |
                        collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@passive, concat($spear:id,"(\W|$)"))]] |
                        collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@mutual, concat($spear:id,"(\W|$)"))]]
                    return $rec  
            }
        </aggregate>}
    else  map {"data" :=  
                    for $rec in collection($global:data-root)//tei:div[@uri = $id]
                    return 
                        <TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec}</TEI>
                
                }  
};

(:~   
 : Checks for canonical record in Syriaca.org 
 : @param $spear:id 
:)
declare function spear:canonical-rec($id){
  collection($global:data-root)//tei:TEI[.//tei:idno = $id]
  (:collection($global:data-root)//tei:idno[. = $id]:)
};

declare function spear:title($id){
    if($spear:item-type = ('place-factoid','person-factoid')) then 
        global:tei2html(
            <spear-headwords xmlns="http://www.tei-c.org/ns/1.0">
                {spear:canonical-rec($id)/descendant::*[@syriaca-tags="#syriaca-headword"]}
            </spear-headwords>)
    else if($spear:item-type = 'keyword-factoid') then   
        concat('"',lower-case(functx:camel-case-to-words(substring-after($id,'/keyword/'),' ')),'"')
    else ()
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
            let $rec-exists := spear:canonical-rec($spear:id)  
            let $title :=  $rec-exists/descendant::*[@syriaca-tags="#syriaca-headword"]
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
    spear:events($node,$model),
    spear:person-data($model("data")))
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
        {
            for $r in spear:relationships($node,$model)
            return 
            <p>{$r}</p>
        }
    </div>,
    global:tei2html(  
       <factoid xmlns="http://www.tei-c.org/ns/1.0">
           {$model("data")}
       </factoid>)   
    )
else    
    global:tei2html(<factoid xmlns="http://www.tei-c.org/ns/1.0">
        {(
            $model("data"), 
            if($model("data")/descendant::tei:persName[@ref] = '') then 
                let $id := string($model("data")/descendant::tei:persName[. = ''][1]/@ref)
                return
                <factoid-headword xmlns="http://www.tei-c.org/ns/1.0">{spear:canonical-rec($id)/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]}</factoid-headword>
            else ()
            )}
    </factoid>)
                    
};

(:~          
    How to list all the factoids?
    should have the options of by type, in order and using 'advance browse options?'   
:)
declare function spear:source-data($data){
let $refs := distinct-values(tokenize(string-join($data//@active | $data//@passive | $data//@mutual | $data//@ref | $data//@target,' '),' '))
let $factoids := $data/descendant::tei:div[@uri]
let $count-factoids := count($factoids)
let $biographical := $factoids[tei:listPerson]
let $count-biographical := count($biographical)
let $relationship := $factoids[tei:listRelation]
let $count-relationship := count($relationship)
let $event := $factoids[tei:listEvent]
let $count-event := count($event)
let $unique-persons := count($refs[contains(.,'/person/')])
let $unique-places := count($refs[contains(.,'/place/')])
let $unique-keywords := count($refs[contains(.,'/keyword/')])
return 
<div class="panel panel-default">
    <div class="panel-heading clearfix">
        <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Publication Information</h4>
    </div>
    <div class="panel-body"> 
        {global:tei2html(<spear-teiHeader xmlns="http://www.tei-c.org/ns/1.0">{$data/descendant::tei:teiHeader, $data/descendant::tei:back}</spear-teiHeader>)}
        <div><span class="srp-label">Data Set:</span>
        <ul>
            <li>This prosopography contains  {$count-factoids} 
            factoids about {$unique-persons} persons, 
            {$unique-places} places, and {$unique-keywords} subjects.</li>
            <li>
                The data is composed of {$count-biographical} biographical factoids, {$count-relationship} relationship factoids, 
                and {$count-event} event factoids.
            </li>
        </ul>
        </div>
    </div>
</div>
};
     
declare function spear:person-data($data){
let $personInfo := $data//tei:div[tei:listPerson]
return 
    if(not(empty($personInfo))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Person Factoids {if($spear:item-type = 'person-factoid') then ' about ' else ' referencing '} {spear:title($spear:id)}</h4>
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
let $relations := $model("data")//tei:div[descendant::tei:relation]
(:
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@active, concat($spear:id,"(\W|$)"))]] |
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@passive, concat($spear:id,"(\W|$)"))]] |
                collection($global:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@mutual, concat($spear:id,"(\W|$)"))]]
:)                
let $count := count($relations)   
let $relation := subsequence($relations,1,20)
return 
    if(not(empty($relation))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Relationship Factoids about {spear:title($spear:id)}</h4>
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
    let $rec-exists := spear:canonical-rec($spear:id)  
    let $type := string($rec-exists/descendant::tei:place/@type)
    let $geo := $rec-exists/descendant::tei:body[descendant-or-self::tei:geo]
    let $abstract := $rec-exists/descendant::tei:body//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $rec-exists/descendant::tei:body//tei:note[@type='abstract']
    return
        if($rec-exists) then
            <div class="panel panel-default">
                 <div class="panel-heading clearfix">
                     <h4 class="panel-title">About {spear:title($spear:id)}</h4>
                 </div>
                 <div class="panel-body">
                 {(if($geo) then 
                    <div>
                        <div>
                            {maps:build-map($geo,0)}
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
               <p><hr/>View entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Syriac Biographical Dictionary' else 'The Syriac Gazetteer' }</a></p>
                 </div>
            </div> 
        else ()       
};

(:~          
 : Find related factoids
 : Side bar used by aggrigate pages. Not to be confussed with spear:relationships-aggregate, which is used for center page display in aggrigate pages, and decodes relationships. 
:)
declare function spear:related-factiods($node as node(), $model as map(*), $view as xs:string?){
let $data := $model("data")  
let $title := $data/descendant::tei:titleStmt/tei:title[1]/text()
return
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] or $data/descendant::tei:persName or $data/descendant::tei:placeName or $data/descendant::tei:relation) then 
        <div class="panel panel-default">
            <div class="panel-heading clearfix">
                {
                    if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                        <h4 class="panel-title">Browse Persons, Places and Keywords in {$title}</h4>
                    else
                        <h4 class="panel-title">Related Persons, Places and Keywords</h4>
                }

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
                            <h4>Person(s) <span class="badge">{$count-persons}</span></h4>
                            <div class="facet-list show">
                                <ul>
                                    {
                                        for $r in subsequence($persNames,1,5)
                                        return 
                                            if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Person:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                            else     
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
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Person:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else     
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
                            <h4>Places(s) <span class="badge">{$count-places}</span></h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($placeNames,1,5)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Place:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else 
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
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Place:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else 
                                                    <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>                                            }
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
                            <h4>Keyword(s) <span class="badge">{$count-keywords}</span></h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($keywords,1,5)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Keyword:{$r}&amp;view=advanced">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>
                                                else
                                                    <li><a href="aggregate.html?id={$r}">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>                                                    
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
                                                  <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Keyword:{$r}&amp;view=advanced">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>
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
let $doc := spear:canonical-rec($uri)
(:collection($global:data-root)/tei:TEI[.//tei:idno = concat($uri,"/tei")]:)
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
return global:tei2html(<spear-citation xmlns="http://www.tei-c.org/ns/1.0">{($bibl)}</spear-citation>)
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