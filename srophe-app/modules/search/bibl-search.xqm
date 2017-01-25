xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bibls="http://syriaca.org/bibls";
import module namespace functx="http://www.functx.com";
import module namespace common="http://syriaca.org/common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bibls:title {request:get-parameter('title', '')};
declare variable $bibls:author {request:get-parameter('author', '')};
declare variable $bibls:idno {request:get-parameter('idno', '')};
declare variable $bibls:subject {request:get-parameter('subject', '')};
declare variable $bibls:id-type {request:get-parameter('id-type', '')};
declare variable $bibls:pub-place {request:get-parameter('pub-place', '')};
declare variable $bibls:publisher {request:get-parameter('publisher', '')};
declare variable $bibls:date {request:get-parameter('date', '')};

declare function bibls:title() as xs:string? {
    if($bibls:title != '') then concat("[ft:query(descendant::tei:title,'",common:clean-string($bibls:title),"',common:options())]")
    else ()    
};

declare function bibls:author() as xs:string? {
    if($bibls:author != '') then concat("[ft:query(descendant::tei:author,'",common:clean-string($bibls:author),"',common:options()) or ft:query(descendant::tei:editor,'",common:clean-string($bibls:author),"',common:options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function bibls:idno() as xs:string? {
    if($bibls:idno != '') then  
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][matches(.,'",$bibls:idno,"$')]]")
            else concat("[descendant::tei:idno[matches(.,'",$bibls:idno,"$')]]")

    (:
        let $id := replace($bibls:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/bibl/',$id)
        return 
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    :)            
    else ()    
};

declare function bibls:pub-place() as xs:string? {
    if($bibls:pub-place != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:pubPlace,'",common:clean-string($bibls:pub-place),"',common:options())]")
    else ()  
};

declare function bibls:publisher() as xs:string? {
    if($bibls:publisher != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:publisher,'",common:clean-string($bibls:publisher),"',common:options())]")
    else ()  
};

declare function bibls:date() as xs:string? {
    if($bibls:date != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:date,'",common:clean-string($bibls:date),"',common:options())]")
    else ()  
};

declare function bibls:subject() as xs:string?{
    if($bibls:subject != '') then 
        concat("collection('",$global:data-root,"')//tei:idno[.='",$bibls:subject,"']/ancestor::tei:body/descendant::tei:bibl[child::tei:ptr]")
    else ()  
};

(:~     
 : Build query string to pass to search.xqm 
:)
declare function bibls:query-string() as xs:string? { 
if($bibls:subject != '') then bibls:subject()
else
 concat("collection('",$global:data-root,"/bibl/tei')//tei:body",
    common:keyword(),
    bibls:title(),
    bibls:author(),
    bibls:pub-place(),
    bibls:publisher(),
    bibls:date(),
    bibls:idno()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bibls:search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = 'start' or $parameter = 'sort-element') then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if ($parameter = 'author') then 
                    (<span class="param">Author/Editor: </span>,<span class="match">{$bibls:author}&#160; </span>)
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
            else ()               
};


(:~
 : Builds advanced search form for persons
 :)
declare function bibls:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
             <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span>
            </button>&#160;
            <xi:include href="../searchTips.html"/>
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard" placeholder="Any word in citation"/>
                        <div class="input-group-btn">
                            <div class="btn-group">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                <ul class="dropdown-menu">
                                    <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="qs">Syriac Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="qs">Syriac Phonetic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Arabic" data-keyboard-id="qs">Arabic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="qs">Greek</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="qs">Russian</a></li>
                                </ul>
                            </div>
                        </div>
                    </div>                 
                </div>
            </div> 
            <hr/>         
            <div class="form-group">            
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="title" name="title" class="form-control keyboard"  placeholder="Title of article, journal, book, or series"/>
                        <div class="input-group-btn">
                            <div class="btn-group">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                <ul class="dropdown-menu">
                                    <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="title">Syriac Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="title">Syriac Phonetic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Arabic" data-keyboard-id="title">Arabic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="title">Greek</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="title">Russian</a></li>
                                </ul>
                            </div>
                        </div>
                    </div>                 
                </div>
            </div>
            <div class="form-group">            
                <label for="author" class="col-sm-2 col-md-3  control-label">Author/Editor: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="author" name="author" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">
                            <div class="btn-group">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                <ul class="dropdown-menu">
                                    <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="author">Syriac Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="author">Syriac Phonetic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Arabic" data-keyboard-id="author">Arabic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="author">Greek</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="author">Russian</a></li>
                                </ul>
                            </div>
                        </div>
                    </div>                
                </div>
            </div>  
            <div class="form-group">            
                <label for="pub-place" class="col-sm-2 col-md-3  control-label">Publication Place: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="pubPlace" name="pub-place" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">
                            <div class="btn-group">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                <ul class="dropdown-menu">
                                    <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="pubPlace">Syriac Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="pubPlace">Syriac Phonetic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Arabic" data-keyboard-id="pubPlace">Arabic</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="pubPlace">Greek</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="pubPlace">Russian</a></li>
                                </ul>
                            </div>
                        </div>
                    </div>                
                </div>
            </div>
            <div class="form-group">            
                <label for="publisher" class="col-sm-2 col-md-3  control-label">Publisher: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                    <input type="text" id="publisher" name="publisher" class="form-control keyboard" placeholder="Publisher Name"/>
                            <div class="input-group-btn">
                                <div class="btn-group">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="publisher">Syriac Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="publisher">Syriac Phonetic</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Arabic" data-keyboard-id="publisher">Arabic</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="publisher">Greek</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="publisher">Russian</a></li>
                                    </ul>
                                </div>
                            </div>
                    </div>                 
                </div>
            </div>   
            <div class="form-group">            
                <label for="date" class="col-sm-2 col-md-3  control-label">Date: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="date" name="date" class="form-control" placeholder="Year as YYYY"/>
                </div>
            </div>   
            <hr/>
            <div class="form-group">            
                <label for="idno" class="col-sm-2 col-md-3  control-label">Id Number: </label>
                <div class="col-sm-10 col-md-2 ">
                    <input type="text" id="idno" name="idno" class="form-control"  placeholder="Ex: 3490"/>
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