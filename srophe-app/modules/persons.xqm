xquery version "3.0";
(:~
 : Builds search page for Syriac.org sub-collections 
 :)
module namespace persons="http://syriaca.org//persons";
import module namespace common="http://syriaca.org//common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $persons:q {request:get-parameter('q', '')};
declare variable $persons:name {request:get-parameter('name', '')};
declare variable $persons:name-type {request:get-parameter('name-type', '')};

declare variable $persons:uri {request:get-parameter('uri', '')};
declare variable $persons:uri-type {request:get-parameter('uri-type', '')};
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
        if($persons:name-type != '') then 
            persons:name-type()
        else concat('//tei:persName[parent::tei:person][ft:query(.,"',common:clean-string($persons:name),'")]')   
    else if($persons:name-type != '') then 
        'Do something??'
    else ()
};

(:
 : @deprciated
<addName type="family" sort="1">Payne Smith</addName>
<addName type="untagged-title" sort="2">
<roleName type="saint" sort="2">St.</roleName>
<forename sort="1">افرام</forename>
make sure these do not have child elements?? 
descendant-or-self::*
:)
declare function persons:name-type() as xs:string? {
    let $name-type := if($persons:name-type = 'given') then '/tei:foreName'
                      else if($persons:name-type = 'family') then '/tei:addName[@type="family"]'
                      else if($persons:name-type = 'title') then '/tei:addName[@type="untagged-title"]'
                      else ()
    return 
        concat('/tei:persName',$name-type,'[ft:query(.,"',common:clean-string($persons:name),'")]')                  
};

(:~
 : Search URI, limit by type
 (any / VIAF / WorldCat / Fihrist / Wikipedia)
 Figure out where the predicate happens?? 
 make form submit correct values. 
:)

declare function persons:uri() as xs:string? { 
    if($persons:uri != '') then
        if($persons:uri-type != '') then
            if($persons:uri-type !='any') then 
                concat('//tei:idno[@type="URI"][contains(.,"',common:clean-string($persons:uri),'") and contains(.,"',$persons:uri-type,'")]')
            else concat('//tei:idno[@type="URI"][contains(.,"',common:clean-string($persons:uri),'")]')    
        else concat('//tei:idno[@type="URI"][contains(.,"',common:clean-string($persons:uri),'")]')
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
:)
declare function persons:related-places() as xs:string?{
    if($persons:place-name  != '') then
         concat('//tei:relation[contains(@passive,"',common:clean-string($persons:place-name),'") and contains(@passive,"place")]')
    else ()
};

(:~
 : Search related persons 
 : NOTE add place type
:)
declare function persons:related-persons() as xs:string?{
    if($persons:related-persons  != '') then
         concat('//tei:relation[contains(@passive,"',common:clean-string($persons:related-persons),'") and contains(@passive,"person")]')
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
    persons:related-persons()
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
    let $name-type-string := if($persons:name-type != '') then
                               (<span class="param">Name Type: </span>,<span class="match">{$persons:name-type}&#160;</span>) 
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
                               (<span class="param">Related Places: </span>,<span class="match">{$persons:related-persons}&#160;</span>)                
                            else ''                                
    return ($keyword-string,$name-string,$name-type-string,$uri-string,$type-string,$related-places-string,$related-persons-string)                                          
};

(:~
 : Format search results
:)
declare function persons:results-node($hit){
    let $root := $hit/ancestor::tei:text//tei:person    
    let $title-en := $root/tei:persName[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')]
    let $title-syr := 
                    if($root/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']) then 
                        (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                {$root/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']}
                            </bdi>)
                    else ''
    let $type := if($root/@ana) then  
                    <bdi dir="ltr" lang="en" xml:lang="en"> ({replace($hit//tei:person/@ana,'#syriaca-','')})</bdi>
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