xquery version "3.0";        
 
module namespace search="http://syriaca.org/search";
import module namespace data="http://syriaca.org/data" at "../lib/data.xqm";
import module namespace page="http://syriaca.org/page" at "../lib/paging.xqm";
import module namespace rel="http://syriaca.org/related" at "../lib/get-related.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "../facet-defs.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "../lib/tei2html.xqm";
import module namespace maps="http://syriaca.org/maps" at "../lib/maps.xqm";
import module namespace common="http://syriaca.org/common" at "common.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

import module namespace functx="http://www.functx.com";
import module namespace kwic="http://exist-db.org/xquery/kwic";
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
declare variable $search:idno {request:get-parameter('uri', '') cast as xs:string};
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:sort-element {request:get-parameter('sort-element', '') cast as xs:string};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?, $view as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string :=  search:query-string($collection)
    return map {"hits" := 
                if(exists(request:get-parameter-names()) or ($view = 'all')) then 
                    if($search:sort-element != '' and $search:sort-element != 'relevance' or $view = 'all') then 
                        for $hit in util:eval($eval-string)
                        order by global:build-sort-string(page:add-sort-options($hit,$search:sort-element),'') ascending
                        return $hit   
                    else if(request:get-parameter('rel', '') != '' and ($search:sort-element = '' or not(exists($search:sort-element)))) then 
                        for $hit in util:eval($eval-string)
                        let $part := xs:integer($hit/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('child-rec', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
                        order by $part
                        return $hit                                                                                               
                    else 
                        for $hit in util:eval($eval-string)
                       (: let $expanded := util:expand($hit, "expand-xincludes=no")
                        let $headword := count($expanded/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][descendant::*:match])
                        let $headword := if($headword gt 0) then $headword + 15 else 0:)
                        order by ft:score($hit) + (count($hit/descendant::tei:bibl) div 100) descending
                        return $hit
                else ()                        
         } 
};

(: for debugging :)
declare function search:search-xpath($collection as xs:string?){
   let $coll := if($search:collection != '') then $search:collection else $collection
    return search:query-string($collection)                    
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return
if($collection != '') then 
    if(doc-available($search-config)) then 
       concat("collection('",$global:data-root,"/",$collection,"')//tei:body",search:dynamic-paths($search-config))
    else
        concat("collection('",$global:data-root,"/",$collection,"')//tei:body",
        data:keyword(),
        search:persName(),
        search:placeName(), 
        search:title(),
        search:bibl(),
        data:uri()
      )
else 
concat("collection('",$global:data-root,"')//tei:TEI",
    common:keyword(),
    common:xpath-search('.//tei:titleStmt/tei:author',request:get-parameter('author', '')),
    common:xpath-search('.//tei:body/tei:div1/tei:head/tei:title',request:get-parameter('title', '')), 
    common:xpath-search('.//tei:body/tei:div1/tei:div2/tei:head',request:get-parameter('section', '')),
    search:corpus-id(),
    search:syriaca-id(),
    search:text-id(),
    search:nhsl-edition(),
    search:bibl-edition()
    )
};

declare function search:dynamic-paths($search-config as xs:string?){
    let $config := if(doc-available($search-config)) then doc($search-config) else ()
    let $params := request:get-parameter-names()
    return string-join(
    for $p in $params
    return 
        if($p = 'q') then
            concat("[ft:query(.,'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
        else 
           for $field in $config//input[@name = $p]
           return 
                if(request:get-parameter($p, '') != '') then
                       if(string($field/@element) = '.') then
                            concat("[ft:query(",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                        else concat("[ft:query(.//",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")    
                    else (),'')
};


(: Corpus specific search fields:) 
declare function search:corpus-id(){
    if(request:get-parameter('corpus-uri', '') != '') then 
        concat("[.//tei:publicationStmt/tei:idno = '",request:get-parameter('corpus-uri', ''),"']") 
    else '' 
};

declare function search:bibl-edition(){
    if(request:get-parameter('bibl-edition', '') != '') then 
        concat("[.//tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:idno[@type='URI'][. = '",request:get-parameter('bibl-edition', ''),"']]") 
    else '' 
};

declare function search:nhsl-edition(){
    if(request:get-parameter('nhsl-edition', '') != '') then 
        concat("[.//tei:fileDesc/tei:titleStmt/tei:title[@ref = '",request:get-parameter('nhsl-edition', ''),"']]") 
    else '' 
};

declare function search:syriaca-id(){
    if(request:get-parameter('syriaca-uri', '') != '') then 
        concat("[.//tei:titleStmt/tei:title[@ref = '",request:get-parameter('syriaca-uri', ''),"']]") 
    else '' 
};

declare function search:text-id(){
    if(request:get-parameter('text-id', '') != '') then 
        concat("[.//tei:div1[@n = '",request:get-parameter('text-id', ''),"']]") 
    else '' 
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
        common:element-search('title',$search:title) 
    else '' 
};

declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := common:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($global:data-root || '/bibl')//tei:body[ft:query(.,$terms, common:options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()
       (: common:element-search('bibl',$search:bibl):)  
};

(: NOTE add additional idno locations, ptr/@target @ref, others? :)
declare function search:idno(){
    if($search:idno != '') then 
         (:concat("[ft:query(descendant::tei:idno, '&quot;",$search:idno,"&quot;')]"):)
         concat("[.//tei:idno = '",$search:idno,"']")
    else () 
};

declare function search:search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element') then ()
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{$search:q}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    search:search-string()
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
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?, $sort-options as xs:string*){
   if($view = 'all') then 
        page:pages($model("hits"), $search:start, $search:perpage, '', $sort-options)
   else if(exists(request:get-parameter-names())) then 
        page:pages($model("hits"), $search:start, $search:perpage, search:search-string($collection), $sort-options)
   else ()
};

declare function search:display-facets($node as node()*, $model as map(*), $collection as xs:string?) {
    <div xmlns="http://www.w3.org/1999/xhtml">{facet:html-list-facets-as-buttons(facet:count($model("hits"), facet-defs:facet-definition($collection)/descendant::facet:facet-definition[not(@xml:lang)]))}</div>
};

(:~
 : Build Map view of search results with coordinates
 : @param $node search resuls with coords
:)
declare function search:build-geojson($node as node()*, $model as map(*)){
let $data := $model("hits")//tei:rec
let $geo-hits := $data//tei:geo
return
    if(count($geo-hits) gt 0) then
         (
         maps:build-map($data[descendant::tei:geo], count($data)),
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
    if(exists(request:get-parameter-names())) then ()
    else <div>{search:search-form($collection)}</div>
};

declare function search:show-grps($nodes, $p, $collection){
    for $node in $nodes
    return 
        typeswitch($node)
            case element(tei:grp) return 
                <div class="indent group">{search:show-grps($node/node(),$p,$collection)}</div>
            case element(tei:rec) return search:show-rec($node, $p,$collection)
            default return search:show-grps($node/node(),$p,$collection)
};

declare function search:show-rec($hit, $p, $collection){
    <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">
                <span class="badge" style="margin-right:1em;">
                    {$search:start + $p - 1}
                </span>
             </div>
            <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                {
                let $uri := $hit/descendant::tei:idno[@type='URI'][1]/text()
                return tei2html:summary-view($hit,'',$uri) 
                } 
            </div>
    </div>                   
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="indent" id="search-results">
    <div>{search:build-geojson($node,$model)}</div>
        {
        for $hit at $p in subsequence($model("hits"), $search:start, $search:perpage)
        let $id := $hit//tei:idno[1]
        let $expanded := kwic:expand($hit)
        order by ft:score($hit) descending
        return
            <div class="row" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                <div class="col-md-12">
                      <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">
                        <span class="badge">
                            {
                                if(request:get-parameter('child-rec', '') != '' and ($search:sort-element = '' or not(exists($search:sort-element)))) then
                                    string($hit/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('child-rec', ''))]]/tei:desc[1]/tei:label[@type='order']/@n)
                                else $search:start + $p - 1
                            }
                        </span>
                      </div>
                      <div class="col-md-9" xml:lang="en">
                        {(tei2html:summary-view($hit, (), $id[1])) }
                        {
                            if($expanded//exist:match) then 
                                <div class="col-md-9" style="padding-left:3em;">{tei2html:output-kwic($expanded, $id[1])}</div>
                            else ()
                        }
                      </div>
                </div>
            </div>
       } 
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
declare function search:search-form($collection) {  
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return 
    if(doc-available($search-config)) then 
        search:build-form($search-config) 
    else search:default-search-form()
};

declare function search:build-form($search-config){
let $config := if(doc-available($search-config)) then doc($search-config) else ()
return 
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal indent" role="form">
    <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
    {if($config//desc != '') then 
        <p class="indent">{$config//desc}</p>
    else() 
    }
    <div class="well well-small">
        <div class="well well-small" style="background-color:white; margin-top:2em;">
            <div class="row">
                <div class="col-md-10">
                    {
                        for $input in $config//input
                        let $label := string($input/@label)
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        (:<input type="text" label="Headword" name="headword" element="tei:term[@type='headword']" keyboard="yes"/>:)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{$label}: </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" id="{$id}" name="{$name}" class="form-control keyboard"/>
                                        {
                                            if($input/@keyboard='yes') then 
                                                <div class="input-group-btn">
                                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                                    </button>{global:keyboard-select-menu($id)}
                                                </div>
                                            else ()
                                        }
                                    </div> 
                                </div>
                            </div>     
                    }
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

(:~
 : Builds advanced search form
 :)
declare function search:default-search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal indent" role="form">
    <h1 class="search-header">Search the Corpus </h1>
    <div class="well well-small">
          <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span>
            </button>&#160;
            <xi:include href="{$global:app-root}/searchTips.html"/>
        <div class="well well-small" style="background-color:white; margin-top:2em;">
            <div class="row">
                <div class="col-md-7">
                <!-- Keyword -->
                 <div class="form-group">
                    <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <div class="input-group">
                            <input type="text" id="qs" name="q" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    {global:keyboard-select-menu('qs')}
                            </div>
                            <div class="input-group-btn">
                                <input type="text" id="keywordProximity" name="keywordProximity" class="form-control"/>
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Proximity Operator">
                                        &#160; Proximity *
                                 </button>
                            </div>
                         </div> 
                    </div>
                  </div>
                    <!-- Author-->
                  <div class="form-group">
                    <label for="author" class="col-sm-2 col-md-3  control-label">Author: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <div class="input-group">
                            <input type="text" id="author" name="author" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    {global:keyboard-select-menu('author')}
                            </div>
                         </div>   
                    </div>
                </div>
                <div class="form-group">
                    <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <div class="input-group">
                            <input type="text" id="title" name="title" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    {global:keyboard-select-menu('title')}
                            </div>
                         </div>   
                    </div>
                  </div>
                <div class="form-group">
                    <label for="section" class="col-sm-2 col-md-3  control-label">Section number: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="section" name="section" class="form-control"/>
                    </div>
               </div>                   
               <div class="form-group">
                    <label for="corpus-uri" class="col-sm-2 col-md-3  control-label">Corpus URI: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="corpus-uri" name="corpus-uri" class="form-control"/>
                    </div>
               </div>                   
              <div class="form-group">
                    <label for="syriaca-uri" class="col-sm-2 col-md-3  control-label">Syriaca URI: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="syriaca-uri" name="syriaca-uri" class="form-control"/>
                    </div>
               </div> 
               <div class="form-group">
                    <label for="text-id" class="col-sm-2 col-md-3  control-label">Text ID Number: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="text-id" name="text-id" class="form-control"/>
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
