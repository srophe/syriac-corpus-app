xquery version "3.0";        

module namespace search="http://syriaca.org/search";
import module namespace page="http://syriaca.org/page" at "../lib/paging.xqm";
import module namespace facets="http://syriaca.org/facets" at "../lib/facets.xqm";
import module namespace persons="http://syriaca.org/persons" at "persons-search.xqm";
import module namespace places="http://syriaca.org/places" at "places-search.xqm";
import module namespace spears="http://syriaca.org/spears" at "spear-search.xqm";
import module namespace bhses="http://syriaca.org/bhses" at "bhse-search.xqm";
import module namespace bibls="http://syriaca.org/bibls" at "bibl-search.xqm";
import module namespace ms="http://syriaca.org/ms" at "ms-search.xqm";
import module namespace common="http://syriaca.org/common" at "common.xqm";
import module namespace geo="http://syriaca.org/geojson" at "../lib/geojson.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ 
 : Shared global parameters for building search paging function
:)
declare variable $search:q {request:get-parameter('q', '') cast as xs:string};
declare variable $search:persName {request:get-parameter('persName', '') cast as xs:string};
declare variable $search:placeName {request:get-parameter('placeName', '') cast as xs:string};
declare variable $search:title {request:get-parameter('title', '') cast as xs:string};
declare variable $search:bibl {request:get-parameter('bibl', '') cast as xs:string};
declare variable $search:idno {request:get-parameter('idno', '') cast as xs:string};
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:sort {request:get-parameter('sort', '') cast as xs:string};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?, $view as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string := 
                        if($coll = ('sbd','q','authors','saints','persons')) then persons:query-string($coll)
                        else if($coll ='spear') then spears:query-string()
                        else if($coll = 'places') then places:query-string()
                        else if($coll = 'bhse') then bhses:query-string()
                        else if($coll = 'bibl') then bibls:query-string()
                        else if($coll = 'manuscripts') then ms:query-string()
                        else search:query-string($collection)
    return                         
    map {"hits" := 
                if(exists(request:get-parameter-names()) or ($view = 'all')) then 
                    if($search:sort = 'alpha') then 
                        for $hit in util:eval($eval-string)
                        let $en-title := 
                                     if($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]) then 
                                         string-join($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]//text(),' ')   
                                     else $hit/ancestor::tei:TEI/descendant::tei:title[1]/text()
                        order by common:build-sort-string($en-title) ascending
                        return $hit                                                     
                    else if($search:sort = 'date') then 
                        for $hit in util:eval($eval-string)
                        let $date := 
                                if($hit/descendant::tei:birth) then $hit/descendant::tei:birth/@syriaca-computed-start
                                else if($hit/descendant::tei:death) then $hit/descendant::tei:death/@syriaca-computed-start
                                else ()
                        order by xs:date($date) ascending
                        return $hit 
                    else 
                        for $hit in util:eval($eval-string)
                        let $expanded := util:expand($hit, "expand-xincludes=no")
                        let $headword := count($expanded/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][descendant::*:match])
                        let $headword := if($headword gt 0) then $headword + 15 else 0
                        order by ft:score($hit) + (count($expanded/descendant::tei:bibl) div 2) + $headword descending
                        return $expanded
                else ()                        
         }
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
if($collection !='') then 
    concat("collection('",$global:data-root,"/",$collection,"')//tei:body",
    common:keyword($search:q),
    search:persName(),
    search:placeName(), 
    search:title(),
    search:bibl(),
    search:idno()
    )
else 
concat("collection('",$global:data-root,"')//tei:body",
    common:keyword($search:q),
    search:persName(),
    search:placeName(), 
    search:title(),
    search:bibl(),
    search:idno(),"/ancestor::tei:TEI"
    )
};

declare function search:persName(){
    if($search:persName != '') then 
        common:element-search('persName',$search:persName) 
    else '' 
};

declare function search:placeName(){
    if($search:placeName != '') then 
        common:element-search('placeName',$search:placeName) 
    else '' 
};

declare function search:title(){
    if($search:title != '') then 
        common:element-search('placeName',$search:title) 
    else '' 
};

declare function search:bibl(){
    if($search:bibl != '') then 
        common:element-search('placeName',$search:bibl) 
    else '' 
};

declare function search:idno(){
    if($search:idno != '') then 
        common:element-search('placeName',$search:idno) 
    else '' 
};

declare function search:search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($search:q)}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{common:clean-string(request:get-parameter($parameter, ''))}</span>)    
        else ())
        }
</span>
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    if($collection = ('persons','authors','saints','sbd','q')) then persons:search-string()
    else if($collection ='spear') then spears:search-string()
    else if($collection = 'places') then places:search-string()
    else if($collection = 'bhse') then bhses:search-string()
    else if($collection = 'bibl') then bibls:search-string()
    else if($collection = 'manuscripts') then ms:search-string()
    else search:search-string()
};

(:~
 : Call facets on search results
 : NOTE: need better template integration
:)
declare %templates:wrap function search:spear-facets($hits){
if(exists(request:get-parameter-names())) then 
    <div>
     <h4>Browse by</h4>
     {
        let $facet-nodes := $hits
        let $facets := $facet-nodes//tei:persName | $facet-nodes//tei:placeName | $facet-nodes//tei:event 
        | $facet-nodes/ancestor::tei:TEI/descendant::tei:title[@level='a'][parent::tei:titleStmt]
        return facets:facets($facets)
     }
    </div>
else ()    
};

(:~
 : Call facets on search results
 : NOTE: need better template integration
:)
declare %templates:wrap function search:facets($node as node()*, $model as map(*)){
<div>
     {
        let $facet-nodes := $model("hits")
        let $facets := $facet-nodes//tei:repository | $facet-nodes//tei:country
        return facets:facets($facets)
     }
</div>
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?){
   if($view = 'all') then 
        page:pageination($model("hits"), $search:start, $search:perpage, true())
   else if(exists(request:get-parameter-names())) then 
        page:pageination($model("hits"), $search:start, $search:perpage, true(), $collection, search:search-string($collection))
   else ()
};

(:~
 : Build Map view of search results with coordinates
 : @param $node search resuls with coords
:)
declare function search:build-geojson($node as node()*, $model as map(*)){
let $geo-hits := $model("hits")//tei:geo
return
    if(count($geo-hits) gt 0) then
         (
         geo:build-map($model("hits")//tei:geo, '', ''),
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>,
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>)
    else ()         
};

(:~
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ''
    else 
        if($collection = ('persons','sbd','authors','q','saints')) then <div>{persons:search-form($collection)}</div>
        else if($collection ='spear') then <div>{spears:search-form()}</div>
        else if($collection ='manuscripts') then <div>{ms:search-form()}</div>
        else if($collection ='bhse') then <div>{bhses:search-form()}</div>
        else if($collection ='bibl') then <div>{bibls:search-form()}</div>
        else <div>{search:search-form()}</div>
};

(:~ 
 : Builds results output

:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="row">
    <div class="col-md-2">
     {
        if($collection = 'spear') then search:spear-facets($model("hits"))
        else ()     
    }
    </div>
   <div class="col-md-10" id="search-results" style="background-color:white;">
   <div>{search:build-geojson($node,$model)}</div>
   {
       for $hit at $p in subsequence($model("hits"), $search:start, $search:perpage)
       return
           <div class="row" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
               <div class="col-md-12">
                     <div class="col-md-1" style="margin-right:-1em;">
                       <span class="label label-default">{$search:start + $p - 1}</span>
                     </div>
                     <div class="col-md-9" xml:lang="en">
                       {
                        if(starts-with(request:get-parameter('author', ''),$global:base-uri)) then 
                            global:display-recs-short-view($hit,'',request:get-parameter('author', ''))
                        else global:display-recs-short-view($hit,'')
                       } 
                     </div>
               </div>
           </div>
      }
   </div>   
</div>
};

(:~          
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
 : NOTE: could add view param to show all for faceted browsing? 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?) {
    if(exists(request:get-parameter-names()) or ($view = 'all')) then search:show-hits($node, $model, $collection)
    else ()
};

(:~
 : Builds advanced search form
 :)
declare function search:search-form() {   
<form method="get" action="search.html" style="margin-top:2em;" class="form-horizontal" role="form">
<h1>Advanced Search</h1>
    <div class="well well-small">
        <div class="well well-small" style="background-color:white;">
            <div class="row">
                <div class="col-md-7">
                <!-- Keyword -->
                 <div class="form-group">
                    <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="q" name="q" class="form-control"/>
                    </div>
                  </div>
                    <!-- Place Name-->
                  <div class="form-group">
                    <label for="placeName" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="placeName" name="placeName" class="form-control"/>
                    </div>
                  </div>
                <div class="form-group">
                    <label for="persName" class="col-sm-2 col-md-3  control-label">Person Name: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="persName" name="persName" class="form-control"/>
                    </div>
                  </div>
                <div class="form-group">
                    <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="title" name="title" class="form-control"/>
                    </div>
                  </div> 
                <div class="form-group">
                    <label for="bibl" class="col-sm-2 col-md-3  control-label">Citation: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="bibl" name="bibl" class="form-control"/>
                    </div>
               </div> 
                <div class="form-group">
                    <label for="uri" class="col-sm-2 col-md-3  control-label">Syriaca.org URI: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="uri" name="uri" class="form-control"/>
                    </div>
               </div> 
               </div>
            </div>    
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};
