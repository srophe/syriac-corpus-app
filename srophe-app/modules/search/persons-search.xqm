xquery version "3.0";
(:~
 : Builds search information for persons sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace persons="http://syriaca.org//persons";
import module namespace common="http://syriaca.org//common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $persons:q {request:get-parameter('q', '')};
declare variable $persons:name {request:get-parameter('name', '')};

declare variable $persons:uri {request:get-parameter('uri', '')};
declare variable $persons:type {request:get-parameter('type', '')};

declare variable $persons:start-date {request:get-parameter('start-date', '')};
declare variable $persons:end-date {request:get-parameter('end-date', '')};
declare variable $persons:date-type {request:get-parameter('date-type', '')};

declare variable $persons:related-place {request:get-parameter('related-place', '')};
declare variable $persons:place-type {request:get-parameter('place-type', '')};

declare variable $persons:related-persons {request:get-parameter('related-persons', '')};
declare variable $persons:mentioned {request:get-parameter('mentioned', '')};


(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
 descendant-or-self::* or . testing which is most correct
 common:build-query($pram-string)
:)
declare function persons:keyword() as xs:string? {
    if($persons:q != '') then concat("[ft:query(.,'",common:clean-string($persons:q),"',common:options())]")
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
        concat("[ft:query(descendant::tei:person/tei:persName,'",common:clean-string($persons:name),"',common:options())]")   
    else ()
};

(:~
 : Search URI
 : Accepts a URI  
:)

declare function persons:uri() as xs:string? { 
    if($persons:uri != '') then    
        concat("[descendant::tei:person/tei:idno[@type='URI'][matches(.,'",$persons:uri,"')]]")
    else ()
};

(:~
 : Search limit by person type. 
:)
declare function persons:type() as xs:string?{
    if($persons:type != '') then
        if($persons:type = 'any') then ()
        else
         concat("[descendant::tei:person/@ana = '#syriaca-",$persons:type,"']")
    else ()
};

(:~
 : Build date search string
 : @param $persons:date-type indicates element to restrict date searches on, if empty, no element restrictions
 : @param $persons:start-date start date
 : @param $persons:end-date end date       
:)
declare function persons:date-range() as xs:string?{
if($persons:date-type != '') then 
    if($persons:date-type = 'birth') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:birth[(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-start lt 
                '",common:do-date($persons:end-date),"'
                )]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:birth[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:birth[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
    else if($persons:date-type = 'death') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:death[(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-start lt 
                '",common:do-date($persons:end-date),"'
                )]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:death[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:death[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
    else if($persons:date-type = 'floruit') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:floruit[(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-end lt 
                '",common:do-date($persons:end-date),"'
                ) or (
                @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and 
                not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:floruit[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:floruit[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else ''      
   else if($persons:date-type = 'reign') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[//tei:state[@type='office'][(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-end lt 
                '",common:do-date($persons:end-date),"'
                ) or (
                @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and 
                not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:state[@type='office'][@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:state[@type='office'][@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
   else if($persons:date-type = 'event') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[//tei:event[(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-end lt 
                '",common:do-date($persons:end-date),"'
                ) or (
                @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and 
                not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:event[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:event[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else ''
    else 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::*[(
                @syriaca-computed-start gt 
                    '",common:do-date($persons:start-date),"' 
                    and @syriaca-computed-end lt 
                    '",common:do-date($persons:end-date),"'
                    ) or (
                    @syriaca-computed-start gt 
                    '",common:do-date($persons:start-date),"' 
                    and 
                    not(exists(@syriaca-computed-end)))]]") 
             else if($persons:start-date != ''  and $persons:end-date = '') then 
                 concat("[descendant::*[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
             else if($persons:end-date != ''  and $persons:start-date = '') then
                concat("[descendant::*[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
             else ''
else 
    if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::*[(
            @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and @syriaca-computed-end lt 
                '",common:do-date($persons:end-date),"'
                ) or (
                @syriaca-computed-start gt 
                '",common:do-date($persons:start-date),"' 
                and 
                not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::*[@syriaca-computed-start gt '",common:do-date($persons:start-date),"' or @syriaca-computed-end gt '",common:do-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::*[@syriaca-computed-end lt '",common:do-date($persons:end-date),"' or @syriaca-computed-start lt '",common:do-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
}; 

(:~
 : Search related places 
:)
declare function persons:related-places() as xs:string?{                   
if($persons:related-place  != '') then 
    let $related-place-uri := if(ends-with($persons:related-place,'.html')) then substring-before($persons:related-place,'.html') else $persons:related-place
    return
    if($persons:place-type !='' and $persons:place-type !='any') then 
        if($persons:place-type = 'birth') then concat("[descendant::tei:relation[@name ='born-at'][matches(@passive,'(^|\W)",$related-place-uri,"(\W|$)')]]")
        else if($persons:place-type = 'death') then concat("[descendant::tei:relation[@name ='died-at'][matches(@passive,'(^|\W)",$related-place-uri,"(\W|$)')]]")
        else if($persons:place-type = 'venerated') then concat("[descendant::tei:event[matches(@contains,'(^|\W)",$related-place-uri,"(\W|$)')]]")
        else concat("[descendant::tei:relation[matches(@passive,'(^|\W)",$related-place-uri,"(\W|$)') | matches(@active,'(^|\W)",$related-place-uri,"(\W|$)')]]")
    else    
        concat("[descendant::tei:relation[matches(@passive,'(^|\W)",$related-place-uri,"(\W|$)') | matches(@active,'(^|\W)",$related-place-uri,"(\W|$)')]]")
else ()
};

(:~
 : Search related persons as uri in tei:relation/@passive and tei:relation/@active
 : Uses regex to match on word boundries
:)
declare function persons:related-persons() as xs:string?{
    if($persons:related-persons  != '') then
        let $related-persons-uri := if(ends-with($persons:related-persons,'.html')) then substring-before($persons:related-persons,'.html') else $persons:related-persons
        return
         concat("[descendant::tei:relation[matches(@passive,'(^|\W)",$related-persons-uri,"(\W|$)') | matches(@active,'(^|\W)",$related-persons-uri,"(\W|$)')]]")
    else ()
};

(:~
 : Search citations 
:)
declare function persons:mentioned() as xs:string?{
    if($persons:mentioned  != '') then
        let $mentioned-uri := if(ends-with($persons:mentioned,'.html')) then substring-before($persons:mentioned,'.html') else $persons:mentioned
        return
         concat("[descendant::tei:person/tei:bibl/tei:ptr[@target = '",$mentioned-uri,"']]")
    else ()
};

(:~
 : Build query string to pass to search.xqm 
:)
declare function persons:query-string() as xs:string? {
 concat("collection('/db/apps/srophe/data/persons/tei')//tei:body",
    persons:keyword(),
    persons:type(),
    persons:name(),
    persons:uri(),
    persons:date-range(),
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
    let $date-type-string :=if($persons:date-type != '') then
                               (<span class="param">Date Type: </span>,<span class="match">{$persons:date-type}&#160;</span>)                
                            else ''
    let $date-start-string :=if($persons:start-date != '') then
                               (<span class="param">Start Date: </span>,<span class="match">{$persons:start-date}&#160;</span>)                
                            else ''
    let $date-end-string :=if($persons:end-date != '') then
                               (<span class="param">End Date: </span>,<span class="match">{$persons:end-date}&#160;</span>)                
                            else ''
    let $related-places-string := if($persons:related-place != '') then
                               (<span class="param">Related Places: </span>,<span class="match">{$persons:related-place}&#160;</span>)                
                            else '' 
    let $related-persons-string := if($persons:related-persons != '') then
                               (<span class="param">Related Persons: </span>,<span class="match">{$persons:related-persons}&#160;</span>)                
                            else ''
    let $mentioned-string := if($persons:mentioned != '') then
                               (<span class="param">Mentioned in: </span>,<span class="match">{$persons:mentioned}&#160;</span>)                
                            else ''                                               
    return ($keyword-string,$name-string,$uri-string,$type-string,$date-type-string,$date-start-string,$date-end-string,$related-places-string,$related-persons-string, $mentioned-string)                                          
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
                            <option value="any">any</option>
                            <option value="author">author</option>
                            <option value="saint">saint</option>
                        </select>
                       </div> 
                    </div>
                <!-- URI
                    <div class="row-fluid">
                        <div class="span2">URI: </div>
                        <div class="span10 form-inline">
                        <input type="text" name="uri"/>&#160;
                        <input type="text" name="uri"/>&#160;
                            <select name="uri-type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="any">any</option>
                                <option value="viaf">VIAF</option>
                                <option value="worldcat">WorldCat</option>
                                <option value="fihrist">Fihrist</option>
                                <option value="wikipedia">Wikipedia</option>
                            </select>
                        </div>
                    </div>
                    -->
                    <!-- Date range-->
                    <div class="row-fluid">
                        <div class="span2">Date Range: </div>
                        <div class="span10 form-inline">
                             <input type="text" name="start-date" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="end-date" placeholder="End Date" class="input-small"/>&#160;
                            <select name="date-type" class="input-medium">
                                <option value="">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="floruit">floruit</option>
                                <option value="reign">reign</option>
                                <option value="event">other event</option>
                            </select>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                    
                    <!-- Associated Places-->
                    <div class="row-fluid">
                        <div class="span2">Associated Places: </div>
                        <div class="span10 form-inline">
                            <input type="text" name="related-place"/>&#160;
                            <select name="place-type" class="input-medium">
                                <option value="">any</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <!--<option value="venerated">venerated</option>-->
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
        <div><p><em>* and ? wild cards may not be used at the begining of a word or search string. They may be used withing a string (Eph*m). * and ? will be stripped from the begining of words.</em></p></div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};