xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collection SPEAR
 : Alphabetical English and Syriac Browse lists
 : Browse by type
 :
 : @see lib/geojson.xqm for map generation
 :)

module namespace bs="http://syriaca.org/bs";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace common="http://syriaca.org/common" at "search/common.xqm";
import module namespace functx="http://www.functx.com";
import module namespace facets="http://syriaca.org/facets" at "lib/facets.xqm";
import module namespace ev="http://syriaca.org/events" at "lib/events.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace page="http://syriaca.org/page" at "lib/paging.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $bs:coll selects collection (persons/places ect) for browse.html 
 : @param $bs:type selects doc type filter eg: place@type person@ana
 : @param $bs:view selects language for browse display
 : @param $bs:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $bs:coll {request:get-parameter('coll', '')};
declare variable $bs:type {request:get-parameter('type', '')}; 
declare variable $bs:view {request:get-parameter('view', '')};
declare variable $bs:sort {request:get-parameter('sort', '')};
declare variable $bs:date {request:get-parameter('date', '')};
declare variable $bs:fq {request:get-parameter('fq', '')};
declare variable $bs:title {request:get-parameter('title', '')};
declare variable $bs:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $bs:perpage {request:get-parameter('perpage', 25) cast as xs:integer};

declare function bs:spear-person($hits){
let $d := util:eval(concat('$hits[descendant::tei:persName]',facets:facet-filter()))
for $data in $d
group by $facet-grp := $data/descendant::tei:persName[1]/@ref
return $data[1]
};

declare function bs:spear-place($hits){
let $d := util:eval(concat('$hits[descendant::tei:placeName]',facets:facet-filter()))
for $data in $d
group by $facet-grp := $data/descendant::tei:placeName[1]/@ref
return $data[1]
};

declare function bs:spear-event($hits){
    util:eval(concat('$hits[descendant::tei:listEvent]',facets:facet-filter()))
};

declare function bs:narrow-by-type(){
    if($bs:type = 'persons') then '[tei:listPerson]'
    else if($bs:type = 'events') then '[tei:listEvent]'
    else if($bs:type = 'relations') then '[tei:listRelation]'
    else ()
};

declare function bs:narrow-by-title(){
concat("[ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[@level='a'][1][. = '",$bs:title,"']]")
};

(:~ 
 : Build Facet groups
 : For browsing by element type 
:)
declare function bs:spear-facet-groups($nodes, $category){
    <li><a href="?view=sources&amp;type={$category}&amp;fq={$facets:fq}" class="facet-label"> {$category} factoids 
    <span class="count">({
        if($category = 'persons') then count(distinct-values($nodes/descendant::tei:persName[1]/@ref)) 
        else count($nodes)
    })</span></a></li>
};

declare function bs:narrow-spear($hits){
    if($bs:view = 'persons' or ($bs:view='sources' and $bs:type = 'persons')) then 
        bs:spear-person($hits)
    else if($bs:view = 'places') then 
        bs:spear-place($hits)
    else if($bs:view = 'events') then 
        bs:spear-event($hits)
    else if($bs:view = 'keywords') then   
        bs:spear-event($hits)
    else if($bs:view = 'advanced') then 
        util:eval(concat('$hits',facets:facet-filter()))
    else util:eval(concat('$hits',facets:facet-filter(),bs:narrow-by-type()))
};

declare function bs:spear-results-panel($hits){
let $hits := bs:narrow-spear($hits)
return
   ( 
        if($bs:view = 'person' or $bs:view = 'place') then 'ABC Menu' else(),
        if($bs:view = 'relations') then 
            <div class="col-md-12">
                <h3>Explore SPEAR Relationships</h3>
                <iframe id="iframe" src="../modules/d3xquery/build-html.xqm" width="100%" height="700" scrolling="auto" frameborder="0" seamless="true"/>
            </div>
        else    
        <div class="col-md-3">
            {
                if($bs:view = 'advanced') then 
                     <div>
                         
                         {
                             let $facets := $hits//tei:persName | $hits//tei:placeName | $hits//tei:event 
                             | $hits/ancestor::tei:TEI/descendant::tei:title[@level='a'][parent::tei:titleStmt]
                             return facets:facets($facets)
                         }
                     </div>
                else
                   <div>
                    <h4>Narrow by Source Text</h4>
                    <span class="facets applied">
                        {
                            if($facets:fq) then facets:selected-facet-display()
                            else ()            
                        }
                    </span>
                    <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
                        {<li>{facets:title($hits)}</li>}
                    </ul>
                        {(
                        if($bs:view = 'keywords') then 
                            (<h4>Narrow by Keyword</h4>,
                             <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
                                {
                                    let $facet-nodes := $hits
                                    let $facets := $facet-nodes//tei:event
                                    return 
                                        <li>{facets:keyword($facets)}</li>
                                }
                             </ul>)
                        else (),     
                        if($bs:view = 'sources' or $bs:view = '') then 
                            (<h4>Narrow by Type</h4>,
                             if($bs:type != '') then 
                                <span class="facets applied">
                                    <span class="facet" title="Remove {$bs:type}">
                                        <span class="label label-facet" title="{$bs:type}">{$bs:type} 
                                            <a href="?view=sources&amp;fq={$facets:fq}" class="facet icon"><span class="glyphicon glyphicon-remove" aria-hidden="true"></span></a>
                                        </span>
                                    </span>            
                                </span>
                            else(),
                            <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
                                {(
                                    bs:spear-facet-groups($hits/tei:listPerson, 'persons'),
                                    bs:spear-facet-groups($hits/tei:listEvent, 'events'), 
                                    bs:spear-facet-groups($hits/tei:listRelation, 'relations') 
                                )}
                            </ul>)
                        else ()
                        )}        
                </div>}
        </div>,
        <div class="col-md-8">
           <h3> {
                            if($bs:view = 'keywords') then concat('Browse Factoids by Keywords (',count($hits),')')
                            else if($bs:view = 'persons') then concat('Persons Mentioned (',count($hits),')')
                            else if($bs:view = 'places') then concat('Places Mentioned (',count($hits),')')
                            else if($bs:view = 'events') then concat('Browse Events (',count($hits),')')
                            else concat('Browse (',count($hits),')')
                        }</h3>
           {bs:display-spear($hits)}
       </div>
    )    
};

(: add paging 
<h3>{if($bs:view) then $bs:view else 'Factoids'} ({count($data)})</h3>
:)
declare function bs:display-spear($hits){
<div>
    <div>
        {
            if($bs:view = 'events') then 
                (ev:build-timeline($hits,'events'), ev:build-events-panel($hits))
            else if($bs:view = 'persons' or ($bs:view='sources' and $bs:type = 'persons')) then 
                bs:spear-persons($hits)
            else if($bs:view = 'places') then 
                bs:spear-places($hits)                
            else
            (page:pages($hits, $bs:start, $bs:perpage,'', ''),
            bs:hits($hits))

        }
    </div>
</div>
};

declare function bs:hits($hits){
    for $data in subsequence($hits, $bs:start,$bs:perpage)
    let $uri := $data/@uri
    return 
    <div class="results-list">
        {
        if($data/tei:listRelation) then 
        <span class="srp-label">[{functx:capitalize-first(string($data/tei:listRelation/tei:relation/@type))} relation] </span>
        else ()
        }
        <a href="factoid.html?id={$uri}" class="syr-label">
            {
                if($data/descendant-or-self::tei:titleStmt) then $data/descendant-or-self::tei:titleStmt[1]/text()
                else if($data/tei:listRelation) then 
                    <span> 
                     {concat(' ', functx:camel-case-to-words(substring-after($data/tei:listRelation/tei:relation/@name,':'),' '))} :
                     {
                     if($data/tei:listRelation/tei:relation/@active) then
                        (string($data/tei:listRelation/tei:relation/@active),' - ',string($data/tei:listRelation/tei:relation/@passive))
                     else 
                        string($data/tei:listRelation/tei:relation/@mutual)
                        }
                    </span>
                else substring(string-join($data/descendant-or-self::*[not(self::tei:idno)][not(self::tei:bibl)][not(self::tei:biblScope)][not(self::tei:note)][not(self::tei:orig)][not(self::tei:sic)]/text(),' '),1,550)
            }                                    
        </a>
    </div>  

};


declare function bs:spear-persons($nodes){
for $d in $nodes
let $id := string($d/descendant::tei:persName[1]/@ref)
let $connical := collection($global:data-root)//tei:idno[. = $id]
let $name := if(exists($connical)) then $connical/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/text()
             else if($d/text()) then global:parse-name($d)
             else tokenize($id,'/')[last()]
order by $name[1] collation "?lang=en&lt;syr&amp;decomposition=full"
return 
    if($connical) then 
            global:display-recs-short-view($connical/ancestor::tei:TEI,'')
    else ()
    (:
     <div class="results-list">
        <span class="srp-label">Name: {$name} </span>
        <span class="results-list-desc uri"><span class="srp-label">URI: </span> {$id}</span>
        <span class="results-list-desc uri"><span class="srp-label">SPEAR: </span> <a href="factoid.html?id={$id}"> http://syriaca.org/spear/factoid.html?id={$id}</a></span>
    </div>
    :)
};

declare function bs:spear-places($nodes){
for $d in $nodes
let $id := string($d/descendant::tei:placeName[1]/@ref)
let $connical := collection($global:data-root)//tei:idno[. = $id]
let $name := if($connical) then $connical/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/text()
             else if(empty($d/descendant::tei:placeName[1])) then tokenize($id,'/')[last()]
             else normalize-space($d/descendant::tei:placeName[1]/text())
order by $name[1] collation "?lang=en&lt;syr&amp;decomposition=full"
return 
    if($connical) then 
            global:display-recs-short-view($connical/ancestor::tei:TEI,'')
    else ()
    (:
     <div class="results-list">
        <span class="srp-label">Name: {$name} </span>
        <span class="results-list-desc uri"><span class="srp-label">URI: </span> {$id}</span>
        <span class="results-list-desc uri"><span class="srp-label">SPEAR: </span> <a href="factoid.html?id={$id}"> http://syriaca.org/spear/factoid.html?id={$id}</a></span>
    </div>
    :)
};

(:~
 : Browse Tabs - SPEAR
:)
declare function bs:build-tabs-spear($node, $model){    
    (<li>{if(not($bs:view)) then 
                attribute class {'active'} 
          else if($bs:view = 'sources') then 
                attribute class {'active'}
          else '' }<a href="browse.html?view=sources">Sources</a>
    </li>,
    <li>{if($bs:view = 'persons') then 
                attribute class {'active'} 
        else '' }<a href="browse.html?view=persons">Persons</a>
    </li>,
    <li>{if($bs:view = 'events') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=events">Events</a>
    </li>,
    <li>{
             if($bs:view = 'relations') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=relations">Relations</a>
    </li>,
    <li>{if($bs:view = 'places') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=places">Places</a>
    </li>,
    <li>{if($bs:view = 'keywords') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=keywords">Keywords</a>
    </li>,
    <li>{if($bs:view = 'advanced') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=advanced">Advanced Browse</a>
    </li>)
};
