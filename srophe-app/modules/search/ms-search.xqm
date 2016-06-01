xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace ms="http://syriaca.org/ms";
import module namespace functx="http://www.functx.com";

import module namespace common="http://syriaca.org/common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $ms:q {request:get-parameter('q', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
 descendant-or-self::* or . testing which is most correct
 common:build-query($pram-string)
:)
declare function ms:keyword() as xs:string? {
    if($ms:q != '') then concat("[ft:query(.,'",common:clean-string($ms:q),"',common:options())]")
    else ()    
};

(:~
 : Build query string to pass to search.xqm 
:)
declare function ms:query-string() as xs:string? {
 concat("collection('",$global:data-root,"/manuscripts/tei')//tei:msDesc",
    ms:keyword()
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
            if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{$ms:q}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}</span>)    
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
<form method="get" action="search.html" class="form-horizontal" role="form">
    <h1>Advanced Search</h1>
    <div class="well well-small">
        <div><p><em>Wild cards * and ? may be used to optimize search results.
        Wild cards may not be used at the beginning of a word, as it hinders search speed.</em></p></div>
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Full-text: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="q" name="q" class="form-control"/>
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