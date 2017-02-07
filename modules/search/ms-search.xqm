xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace ms="http://syriaca.org/ms";
import module namespace facets="http://syriaca.org/facets" at "../lib/facets.xqm";
import module namespace functx="http://www.functx.com";
import module namespace common="http://syriaca.org/common" at "common.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
declare function ms:facets($node as node(), $model as map(*)){
    let $facet-nodes := $model("browse-data")
    let $facets := $facet-nodes//tei:repository | $facet-nodes//tei:country
    return facets:facets($facets)
};
:)

(:~
 : Build query string to pass to search.xqm 
:)
declare function ms:query-string() as xs:string? {
 concat("collection('",$global:data-root,"/manuscripts/tei')//tei:teiHeader",
    common:keyword(),facets:facet-filter()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function ms:search-string() as xs:string*{
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element') then ()
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')} &#160;</span>)    
        else ()            
};

(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function ms:results-node($hit){
    let $root := $hit 
    let $title := $root/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title/text()
    let $id := $root/ancestor::tei:TEI/descendant::tei:idno[starts-with(.,$global:base-uri)][1]/text()
    return 
        <p style="font-weight:bold padding:.5em;">
            <a href="manuscript.html?id={$id}">{$title}</a>
        </p>
};

(:~
 : Builds advanced search form for persons
 :)
declare function ms:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
             <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span>
            </button>&#160;
            <xi:include href="{$global:app-root}/searchTips.html"/>
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
        <div class="form-group">
            <label for="q" class="col-sm-2 col-md-3  control-label">Full-text: </label>
            <div class="col-sm-10 col-md-9 ">
                <div class="input-group">
                    <input type="text" id="qs" name="q" class="form-control keyboard"/>
                    <div class="input-group-btn">
                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                            </button>
                            {global:keyboard-select-menu('qs')}
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