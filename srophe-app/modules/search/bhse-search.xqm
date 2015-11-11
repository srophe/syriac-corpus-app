xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bhses="http://syriaca.org/bhses";
import module namespace functx="http://www.functx.com";
import module namespace common="http://syriaca.org/common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bhses:q {request:get-parameter('q', '')};
declare variable $bhses:title {request:get-parameter('title', '')};
declare variable $bhses:idno {request:get-parameter('idno', '')};
declare variable $bhses:id-type {request:get-parameter('id-type', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
:)
declare function bhses:keyword() as xs:string? {
    if($bhses:q != '') then concat("[ft:query(.,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:persName,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:placeName,'",common:clean-string($bhses:q),"',common:options()) or ft:query(ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:desc,'",common:clean-string($bhses:q),"',common:options())]")
    else ()    
};

declare function bhses:title() as xs:string? {
    if($bhses:title != '') then concat("[ft:query(tei:bibl/tei:title,'",common:clean-string($bhses:title),"',common:options())]")
    else ()    
};

declare function bhses:idno() as xs:string? {
    if($bhses:idno != '') then 
        if($bhses:id-type != '') then concat("[descendant::tei:idno[@type='",$bhses:id-type,"'][normalize-space(.) = '",$bhses:idno,"']]")
        else concat("[descendant::tei:idno[normalize-space(.) = '",$bhses:idno,"']]")
    else ()    
};


(:~
 : Build query string to pass to search.xqm 
:)
declare function bhses:query-string() as xs:string? {
 concat("collection('",$global:data-root,"/works/tei')//tei:body",
    bhses:keyword(),bhses:title(),bhses:idno()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bhses:search-string() as xs:string*{
    let $keyword-string := if($bhses:q != '') then 
                                (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($bhses:q)}&#160;</span>)
                           else ''  
    let $title-string :=   if($bhses:title != '') then 
                                (<span class="param">Title: </span>,<span class="match">{common:clean-string($bhses:title)}&#160;</span>)
                           else ''           
    let $idno-string :=   if($bhses:idno != '') then 
                                (<span class="param">ID: </span>,<span class="match">{common:clean-string($bhses:idno)}&#160;</span>)
                           else ''                             
    return ($keyword-string, $title-string, $idno-string)                  
};

(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function bhses:results-node($hit){
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
declare function bhses:search-form() {   
<form method="get" action="search.html" class="form-horizontal" role="form">
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
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="title" name="title" class="form-control"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Id number: </label>
                <div class="col-sm-10 col-md-3 ">
                    <input type="text" id="idno" name="idno" class="form-control"/>
                </div>
                <div class="col-sm-10 col-md-3 ">
                    <select type="text" id="id-type" name="id-type" class="form-control">
                        <option value="">-- ID Type --</option>
                        <option value="URI">Syriaca.org URI</option>
                        <option value="BHS">BHS</option>
                        <option value="BHO">BHO</option>
                        <option value="CPG">CPG</option>
                    </select>
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