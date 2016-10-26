xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collection SPEAR
 :
 : @see lib/geojson.xqm for map generation
 : @see lib/events.xqm for events timeline generation
 : @see lib/facet.xqm for facet generation
 :)

module namespace bs="http://syriaca.org/bs";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace common="http://syriaca.org/common" at "search/common.xqm";
import module namespace functx="http://www.functx.com";
import module namespace facet="http://expath.org/ns/facet" at "lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "facet-defs.xqm";
import module namespace facets="http://syriaca.org/facets" at "lib/facets.xqm";
import module namespace browse="http://syriaca.org/browse" at "browse.xqm";
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
 : @param $bs:date passes browse by date
 : @param $bs:fq passes browse by facet
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

(:~
 : Narrow and sort SPEAR results based on URI params
:)
declare function bs:spear-data-narrow($hits){ 
let $data := 
   if($bs:view = 'relations') then () 
   else if($bs:view = 'persons' or ($bs:view='sources' and $bs:type = 'persons')) then 
       let $d := util:eval(concat('$hits[descendant::tei:persName]',facet:facet-filter(facet-defs:facet-definition('spear-persons'))))
       let $uris := distinct-values($d/descendant::tei:persName/@ref)
       for $hit in $uris
       let $title := bs:get-title($hit)
       where 
            if($bs:sort='All') then 
                $title
            else if($bs:sort = 'Anonymous') then
                $title[starts-with(.,'Anonym')]
            else $title[not(starts-with(.,'Anonym'))][matches(substring(global:build-sort-string(.,'en'),1,1),browse:get-sort(),'i')] 
       order by $title collation "?lang=en&lt;syr&amp;decomposition=full"
       return <uri>{$hit}</uri>
   else if($bs:view = 'places') then 
       let $d := util:eval(concat('$hits[descendant::tei:placeName]',facet:facet-filter(facet-defs:facet-definition('spear'))))
       let $uris := distinct-values($d/descendant::tei:placeName/@ref)
       for $hit in $uris
       let $title := bs:get-title($hit)
       where 
        if($bs:sort='All') then 
            $title
        else $title[matches(substring(global:build-sort-string(.,'en'),1,1),browse:get-sort(),'i')]
       order by $title collation "?lang=en&lt;syr&amp;decomposition=full"
       return <uri>{$hit}</uri>
   else if($bs:view = 'events') then 
        util:eval(concat('$hits[descendant::tei:listEvent]',facet:facet-filter(facet-defs:facet-definition('spear-events'))))
   else if($bs:view = 'keywords') then   
        util:eval(concat('$hits[descendant::tei:listEvent]',facets:facet-filter()))
   else if($bs:view = 'advanced') then 
     util:eval(concat('$hits',facet:facet-filter(facet-defs:facet-definition('spear'))))
   else 
        util:eval(concat('$hits',facet:facet-filter(facet-defs:facet-definition('spear-sources'))))
return $data   
};

(:~
 : Browse Alphabetical Menus SPEAR
:)
declare function bs:browse-abc-menu(){
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
        {
            if($bs:view = 'persons') then  
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z Anonymous All', ' ')
                return
                    <li>{if($bs:sort = $letter) then attribute class {"selected badge"} else()}<a href="?view={$bs:view}&amp;sort={$letter}">{$letter}</a></li>
            else if($bs:view = 'places') then  
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z All', ' ')
                return
                     <li>{if($bs:sort = $letter) then attribute class {"selected badge"} else()}<a href="?view={$bs:view}&amp;sort={$letter}">{$letter}</a></li>
            else ()  

        }
        </ul>
    </div>
};

declare function bs:spear-results-panel($data){
let $hits := bs:spear-data-narrow($data)
return
   ( 
        if($bs:view = 'persons' or $bs:view = 'places') then 
            <div class="float-container">
                <div class="pull-right">
                     <div>{page:pages($hits, $bs:start, $bs:perpage,'', '')}</div>
                </div>
                {bs:browse-abc-menu()}
            </div>
        else(),
        if($bs:view = 'relations') then 
            <div class="col-md-12">
                <h3>Explore SPEAR Relationships</h3>
                <iframe id="iframe" src="../modules/d3xquery/build-html.xqm" width="100%" height="700" scrolling="auto" frameborder="0" seamless="true"/>
            </div>
        else (
            <div class="col-md-3">
                 <div>
                    { 
                    if($bs:view = 'sources' or not($bs:view)) then 
                        facet:html-list-facets-as-buttons(facet:count($hits, facet-defs:facet-definition('spear-sources')/child::*))
                    else if($bs:view = 'events') then
                        facet:html-list-facets-as-buttons(facet:count($hits, facet-defs:facet-definition('spear-events')/child::*))
                    else facet:html-list-facets-as-buttons(facet:count($hits, facet-defs:facet-definition('spear')/child::*))
                    }
                 </div>
             </div>,
             <div class="col-md-8">
                {
                    if($bs:view != 'persons' and $bs:view != 'places' and $bs:view != 'events') then
                        <div class="float-container">
                            <div class="pull-right">
                                 <div>{page:pages($hits, $bs:start, $bs:perpage,'', '')}</div>
                            </div>
                        </div>
                    else ()
                }
                <h3> {
                         if($bs:view = 'keywords') then concat('Browse Factoids by Keywords (',count($hits),')')
                         else if($bs:view = 'persons') then concat(' Persons Mentioned (',count($hits),')')
                         else if($bs:view = 'places') then concat('Places Mentioned (',count($hits),')')
                         else if($bs:view = 'events') then concat('Browse Events (',count($hits),')')
                         else concat('Browse (',count($hits),')')
                         }
                 </h3>            
                 {bs:display-spear($hits)}
            </div>)        
    )    
};

declare function bs:display-spear($hits){
<div>
    <div>
        {
            if($bs:view = 'events') then 
                (ev:build-timeline($hits,'events'), ev:build-events-panel($hits))
            else if($bs:view = 'persons' or ($bs:view='sources' and $bs:type = 'persons') or $bs:view = 'places') then 
                bs:display-canonical-names($hits)
            else bs:hits($hits)

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

(:~
 : Get title for record
 : NOTE: could be a global function
:)
declare function bs:get-title($uri){
let $doc := collection($global:data-root)/range:field-eq("uri", concat($uri,"/tei"))[1]
return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ',' ')
      else $uri 
};

(:~
 : Display results where canonical records are referenced
:)
declare function bs:display-canonical-names($nodes){
for $hit in subsequence($nodes,$bs:start,$bs:perpage)
let $doc := collection($global:data-root)/range:field-eq("uri", concat($hit,"/tei"))[1]
return 
    <div class="results-list">
        {
            if (exists($doc)) then
                global:display-recs-short-view($doc,'spear')
            else $hit
        }
    </div>
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
