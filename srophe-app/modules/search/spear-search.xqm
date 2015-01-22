xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace spears="http://syriaca.org//spears";
import module namespace functx="http://www.functx.com";
import module namespace common="http://syriaca.org//common" at "common.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $spears:q {request:get-parameter('q', '')};
declare variable $spears:name {request:get-parameter('name', '')};
declare variable $spears:place {request:get-parameter('place', '')};
declare variable $spears:event {request:get-parameter('event', '')};
declare variable $spears:ref {request:get-parameter('ref', '')};
declare variable $spears:keyword {request:get-parameter('keyword', '')};

declare variable $spears:type {request:get-parameter('type', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
 descendant-or-self::* or . testing which is most correct
 common:build-query($pram-string)
:)
declare function spears:keyword() as xs:string? {
    if($spears:q != '') then concat("[ft:query(.,'",common:clean-string($spears:q),"',common:options())]")
    else ()    
};

(:~
 : Search Name
 : @param $name search persName
 want to be able to return all given/family ect without a search term?
 given / family / title
:)
declare function spears:name() as xs:string? {
    if($spears:name != '') then
        concat("[ft:query(descendant::tei:persName,'",common:clean-string($spears:name),"',common:options())]")   
    else ()
};

(:~
 : Search Place
 : @param $name search placeName
:)
declare function spears:place() as xs:string? {
    if($spears:place != '') then
        concat("[ft:query(descendant::tei:placeName,'",common:clean-string($spears:place),"',common:options())]")   
    else ()
};

(:~
 : Search Event
 : @param $name search placeName
:)
declare function spears:event() as xs:string? {
    if($spears:event != '') then
        concat("[ft:query(descendant::tei:event,'",common:clean-string($spears:event),"',common:options())]")   
    else ()
};

(:~
 : Search keyword
 : @param keyword
:)
declare function spears:controlled-keyword-search(){
    concat("[descendant::*[matches(@ref,'(^|\W)",$spears:keyword,"(\W|$)')]]")
};

(:~
 : Search by date
 : NOTE: still thinking about this one
:)

(:~
 : Build query string to pass to search.xqm 
:)
declare function spears:query-string() as xs:string? {
 concat("collection('/db/apps/srophe/data/spear/tei')//tei:div",
    spears:keyword(),
    spears:name(),
    spears:place(),
    spears:event(),
    spears:controlled-keyword-search()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function spears:search-string() as xs:string*{
    let $keyword-string := if($spears:q != '') then 
                                (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($spears:q)}&#160;</span>)
                           else ''
    let $name-string :=    if($spears:name != '') then
                                (<span class="param">Name: </span>,<span class="match">{common:clean-string($spears:name)}&#160;</span>)
                           else ''
    let $place-string :=    if($spears:place != '') then
                                (<span class="param">Place Name: </span>,<span class="match">{common:clean-string($spears:place)}&#160;</span>)
                           else ''      
    let $event-string :=    if($spears:event != '') then
                                (<span class="param">Event: </span>,<span class="match">{common:clean-string($spears:event)}&#160;</span>)
                           else ''                                 
    let $controlled-keyword-string :=    if($spears:keyword != '') then
                                (<span class="param">Keyword: </span>,
                                <span class="match">
                                    {lower-case(functx:camel-case-to-words(substring-after($spears:keyword,'/keyword/'),' '))}&#160;
                                </span>)
                           else ''                           
    return (
    $keyword-string,
    $name-string,
    $place-string,
    $event-string,
    $controlled-keyword-string
    
    )                                          
};

(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function spears:results-node($hit){
    let $root := $hit    
    let $title := 
        if($root/tei:listPerson) then string-join($root/tei:listPerson/descendant::text(),' ')
        else if ($root/tei:listEvent) then string-join($root/tei:listEvent/tei:event/descendant::text(),' ')
        else $root/child::*/text()
    let $type :=  
        if($root/tei:listPerson) then '(Person)'
        else if ($root/tei:listEvent) then '(Event)'
        else '(Other)'
    return 
        if($root/tei:listPerson) then 
            if($root/tei:listPerson/tei:person/tei:persName) then 
                <p style="font-weight:bold padding:.5em;">
                    <a href="person.html?id={string($root/tei:listPerson/tei:person/tei:persName/@ref)}">
                        {$title, $type}
                    </a>
                </p>
            else 
                <p style="font-weight:bold padding:.5em;">
                    <a href="person.html?id={string($root/tei:listPerson/descendant::tei:persName[1]/@ref)}">
                        {$title, $type}
                    </a>
                </p>                
        else if ($root/tei:listEvent) then 
            <p style="font-weight:bold padding:.5em;">
                {$title, $type} <br/>
                <a href="person.html?id={string($root/descendant::tei:persName[1]/@ref)}">
                    View in Person Factoid
                </a> |
                <a href="event.html#http://syriaca.org/keyword/decree">
                    View in Event Timeline
                </a>
            </p>
        else 
            <p style="font-weight:bold padding:.5em;">
                    <a href="person.html?id={string($root/tei:listPerson/tei:person/tei:persName/@ref)}">
                        {$title, $type}
                    </a>
                </p>

};

(:~
 : Build drop down menu for controlled keywords
:)
declare function spears:keyword-menu(){
for $keywordURI in 
distinct-values(
    (
    for $keyword in collection('/db/apps/srophe/data/spear/')//@target[contains(.,'/keyword/')]
    return tokenize($keyword,' '),
    for $keyword in collection('/db/apps/srophe/data/spear/')//@ref[contains(.,'/keyword/')]
    return tokenize($keyword,' ')
    )
    )
let $key := lower-case(functx:camel-case-to-words(substring-after($keywordURI,'/keyword/'),' '))    
order by $key     
return
    <option value="{$keywordURI}">{$key}</option>
};

declare function spears:source-menu(){
for $title in collection('/db/apps/srophe/data/spear/')//tei:titleStmt/tei:title[1]
let $id := $title/ancestor::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="URI"]
order by $title  
return
    <option value="{$title}">{$title}</option>
};

(:~
 : Builds advanced search form for persons
 :)
declare function spears:search-form() {   
<form method="get" action="search.html" class="form-horizontal" role="form">
    <h1>Advanced Search</h1>
    <!--q name date? place
     gender/sex, ethnic label, languages spoken, religious affiliation, occupation/vocation/office and place -->
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
            <!-- Person Name -->
            <div class="form-group">            
                <label for="name" class="col-sm-2 col-md-3  control-label">Person Name: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="name" name="name" class="form-control"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="place" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="place" name="place" class="form-control"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="event" class="col-sm-2 col-md-3  control-label">Event: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="event" name="event" class="form-control"/>
                </div>
            </div>
            
            <!-- Person gender 
            <div class="form-group">            
                <label for="gender" class="col-sm-2 col-md-3  control-label">Gender: </label>
                <div class="col-sm-10 col-md-6">
                    <select name="gender" id="gender" class="form-control">
                            <option value="any">any</option>
                            <option value="M">M</option>
                            <option value="F">F</option>
                    </select>
                </div>
            </div>     -->       
                
            <div class="form-group">            
                <label for="keyword" class="col-sm-2 col-md-3  control-label">Keyword</label>
                <div class="col-sm-10 col-md-6">
                    <select name="keyword" id="keyword" class="form-control">
                        <option value="">- Select -</option>
                        {spears:keyword-menu()}
                    </select>
                </div>    
            </div>  
            <div class="form-group">            
                <label for="pim-src" class="col-sm-2 col-md-3  control-label">Primary Source</label>
                <div class="col-sm-10 col-md-6">
                    <select name="pim-src" id="pim-src" class="form-control">
                        <option value="">- Select -</option>
                        {spears:source-menu()}
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