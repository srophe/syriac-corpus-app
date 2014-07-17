xquery version "3.0";
(:~
 : Builds search information for persons sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace persons="http://syriaca.org//persons";
import module namespace common="http://syriaca.org//common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $persons:q {request:get-parameter('q', '')};
declare variable $persons:name {request:get-parameter('name', '')};

declare variable $persons:uri {request:get-parameter('uri', '')};
declare variable $persons:type {request:get-parameter('type', '')};

declare variable $persons:start-date {request:get-parameter('start-date', '')};
declare variable $persons:end-date {request:get-parameter('end-date', '')};
declare variable $persons:date-type {request:get-parameter('date-type', '')};

declare variable $persons:place-name {request:get-parameter('place-name', '')};
declare variable $persons:place-type {request:get-parameter('place-type', '')};

declare variable $persons:related-persons {request:get-parameter('related-persons', '')};
declare variable $persons:mentioned {request:get-parameter('mentioned', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
 descendant-or-self::* or . testing which is most correct
:)
declare function persons:keyword() as xs:string? {
    if($persons:q != '') then concat('//tei:body[ft:query(.,"',common:clean-string($persons:q),'")]')
    else ()    
};

(:~
 : Search Name
 : @param $name search persName
 want to be able to return all given/family ect without a search term?
 given / family / title
:)
declare function persons:name() as xs:string? {
    if($persons:name != '') then
        concat('//tei:persName[parent::tei:person][ft:query(.,"',common:clean-string($persons:name),'")]')   
    else ()
};

(:~
 : Search URI
 : Accepts a URI  
:)

declare function persons:uri() as xs:string? { 
    if($persons:uri != '') then    
        concat('//tei:idno[@type="URI"][matches(.,"',$persons:uri,'")]')
    else ()
};

(:~
 : Search limit by person type. 
:)
declare function persons:type() as xs:string?{
    if($persons:type != '') then
         concat('//tei:person[@ana = "#syriaca-',$persons:type,'"]')
    else ()
};

(:
 : SKIPPING DATE RANGE, because We need to talk about the elements/attributes/data involved examples would be helpful
 :)
 
(:~
 : Search related places 
 : NOTE add place type
 
relation/@active
relation/@passive
event/@where
birth/placeName/@ref
death/placeName/@ref

Note, what is element for other and type for event
:)
declare function persons:related-places() as xs:string?{                   
if($persons:place-name  != '') then
    if($persons:place-type !='' and $persons:place-type !='any') then 
        if($persons:place-type = 'birth') then concat('//tei:birth/placeName[matches(@ref,"',$persons:place-name,'")]')
        else if($persons:place-type = 'death') then concat('//tei:death/placeName[matches(@ref,"',$persons:place-name,'")]')
        else if($persons:place-type = 'venerated') then concat('//tei:event[matches(@where,"',$persons:place-name,'")]') 
        else ()
    else    
        concat('//tei:relation[matches(@passive,"',$persons:place-name,'") 
                | matches(@active,"',$persons:place-name,'")] 
                | //tei:birth/placeName[matches(@ref,"',$persons:place-name,'")]
                | //tei:death/placeName[matches(@ref,"',$persons:place-name,'")]
                | //tei:event[matches(@where,"',$persons:place-name,'")]')     
else ()
};

(:~
 : Search related persons 
:)
declare function persons:related-persons() as xs:string?{
    if($persons:related-persons  != '') then
         concat('//tei:relation[matches(@passive,"',$persons:related-persons,'") | matches(@active,"',$persons:related-persons,'")]')
    else ()
};

(:~
 : Search citations 
:)
declare function persons:mentioned() as xs:string?{
    if($persons:mentioned  != '') then
         concat('//tei:bibl/tei:ptr[matches(@target,"',$persons:mentioned,'")]')
    else ()
};

(:~
 : Build query string to pass to search.xqm 
:)
declare function persons:query-string() as xs:string? {
    concat("collection('/db/apps/srophe/data/persons/tei')",
    persons:keyword(), 
    persons:name(),
    persons:uri(),
    persons:type(),
    persons:related-places(),
    persons:related-persons(),
    persons:mentioned()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function persons:search-string() as xs:string*{
    let $keyword-string := if($persons:q != '') then 
                                (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($persons:q)}&#160;</span>)
                           else ''
    let $name-string :=    if($persons:name != '') then
                                (<span class="param">Name: </span>,<span class="match">{common:clean-string($persons:name)}&#160;</span>)
                           else ''
    let $uri-string :=      if($persons:uri != '') then
                               (<span class="param">URI: </span>,<span class="match">{$persons:uri}&#160;</span>)                
                            else ''
    let $type-string :=      if($persons:type != '') then
                               (<span class="param">Person Type: </span>,<span class="match">{$persons:type}&#160;</span>)                
                            else ''
    let $related-places-string := if($persons:place-name != '') then
                               (<span class="param">Related Places: </span>,<span class="match">{$persons:place-name}&#160;</span>)                
                            else '' 
    let $related-persons-string := if($persons:related-persons != '') then
                               (<span class="param">Related Persons: </span>,<span class="match">{$persons:related-persons}&#160;</span>)                
                            else ''
    let $mentioned-string := if($persons:mentioned != '') then
                               (<span class="param">Mentioned in: </span>,<span class="match">{$persons:mentioned}&#160;</span>)                
                            else ''                                               
    return ($keyword-string,$name-string,$uri-string,$type-string,$related-places-string,$related-persons-string, $mentioned-string)                                          
};

(:~
 : Format search results
:)
declare function persons:results-node($hit){
    let $root := $hit//tei:person    
    let $title-en := $root/tei:persName[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')]
    let $title-syr := 
                    if($root/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']) then 
                        (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                {$root/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']}
                            </bdi>)
                    else ''
    let $type := if($root/@ana) then  
                    <bdi dir="ltr" lang="en" xml:lang="en"> ({replace($root/@ana,'#syriaca-','')})</bdi>
                  else ''  
    let $id := substring-after($root/@xml:id,'person-')                  
    return
        <p style="font-weight:bold padding:.5em;">
            <!--<a href="/person/{$id}.html">-->
            <a href="person.html?id={$id}">
                <bdi dir="ltr" lang="en" xml:lang="en">{$title-en}</bdi>
                {$type, $title-syr}
            </a>
        </p>
};

(:~
 : Builds advanced search form for persons
 :)
declare function persons:search-form() {   
<form method="get" action="search.html" id="search-form">
    <div class="well well-small">
        <div class="navbar-inner search-header">
            <h3>Advanced Search</h3>
        </div>
        <div class="well well-small search-inner">
            <div class="row-fluid">
                <div class="span12">
                    <div class="row-fluid" style="margin-top:1em;">
                        <div class="span2">Keyword: </div>
                        <div class="span10"><input type="text" name="q"/></div>
                    </div>
                    
                    <!-- Place Name-->
                    <div class="row-fluid">
                        <div class="span2">Person Name: </div>
                        <div class="span10 form-inline">
                            <input type="text" name="name"/>&#160;
                            <!--<select name="name-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="given">given</option>
                                <option value="family">family</option>
                                <option value="title">title</option>
                            </select>-->
                        </div>
                    </div>
                    <hr/>
                     <!-- Person Type-->
                    <div class="row-fluid">
                        <div class="span2">Person Type: </div>
                        <div class="span10 form-inline">
                        <select name="type" class="input-medium">
                            <option value="">- Select -</option>
                            <option value="any">any</option>
                            <option value="author">author</option>
                            <option value="saint">saint</option>
                        </select>
                       </div> 
                    </div>
                                        <!-- URI-->
                    <div class="row-fluid">
                        <div class="span2">URI: </div>
                        <div class="span10 form-inline">
                        <!--
                        <input type="text" name="uri"/>&#160;
                            <select name="uri-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="viaf">VIAF</option>
                                <option value="worldcat">WorldCat</option>
                                <option value="fihrist">Fihrist</option>
                                <option value="wikipedia">Wikipedia</option>
                            </select>
                            -->
                        </div>
                    </div>
                    <!-- Date range-->
                    <div class="row-fluid">
                        <div class="span2">Date Range: </div>
                        <div class="span10 form-inline">
                             <input type="text" name="start-date" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="end-date" placeholder="End Date" class="input-small"/>&#160;
                            <select name="date-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="floruit">floruit</option>
                                <option value="reign">reign</option>
                                <option value="other">other event</option>
                            </select>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                    
                    <!-- Associated Places-->
                    <div class="row-fluid">
                        <div class="span2">Associated Places: </div>
                        <div class="span10 form-inline">
                            <input type="text" name="place-name"/>&#160;
                            <select name="place-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="venerated">venerated</option>
                                <option value="other">other</option>
                            </select>
                        </div>
                    </div>
                    
                    <!-- Related persons-->
                    <div class="row-fluid">
                        <div class="span2">Related Persons: </div>
                        <div class="span10"><input type="text" name="related-persons"/></div>
                    </div>
                    
                    <!-- Mentioned in Source-->
                    <div class="row-fluid">
                        <div class="span2">Mentioned in Source: </div>
                        <div class="span10"><input type="text" name="mentioned"/></div>
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