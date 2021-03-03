xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://srophe.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "facets.xql";
import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
import module namespace page="http://srophe.org/srophe/page" at "../lib/paging.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Variables:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $search:q {request:get-parameter('q', '') cast as xs:string};
declare variable $search:persName {request:get-parameter('persName', '') cast as xs:string};
declare variable $search:placeName {request:get-parameter('placeName', '') cast as xs:string};
declare variable $search:title {request:get-parameter('title', '') cast as xs:string};
declare variable $search:bibl {request:get-parameter('bibl', '') cast as xs:string};
declare variable $search:idno {request:get-parameter('uri', '') cast as xs:string};
declare variable $search:sort-element {request:get-parameter('sort-element', '') cast as xs:string};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};

(:~
 : Builds search result, saves to model("hits") for use in HTML display
:)

(:~
 : Search results stored in map for use by other HTML display functions
 data:search($collection)
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string?, $view as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string :=  concat(search:query-string($collection),facet:facet-filter(global:facet-definition-file($collection)))
    let $hits := 
                if(exists(request:get-parameter-names()) or ($view = 'all')) then 
                    if(($search:sort-element != '') and ($search:sort-element != 'relevance') or ($view = 'all')) then 
                        for $hit in util:eval($eval-string)
                        order by global:build-sort-string(data:add-sort-options($hit,$search:sort-element),'') ascending
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
    return map {"hits" : $hits[descendant::tei:body[ft:query(., (),sf:facet-query())]]}
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
<!--<div>{search:query-string($collection)}</div>-->
    {
        let $hits := $model("hits")
        for $hit at $p in subsequence($hits, $search:start, $search:perpage)
        let $id := replace($hit/descendant-or-self::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
        return 
            <div class="result row">
                <div class="col-md-12">
                      <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">
                        <span class="badge">{$search:start + $p - 1}</span>
                      </div>
                      <div class="col-md-9" xml:lang="en">
                        {(tei2html:summary-view-generic($hit, $id)) }
                        {if(request:get-parameter('keywordProximity', '') castable as xs:integer) then 
                           tei2html:output-kwic($hit,$id)  
                         else
                            let $expanded := util:expand($hit)
                            return
                                if($expanded//exist:match) then 
                                    tei2html:output-kwic($expanded, $id)
                                else ()
                          }
                      </div>
                </div>
            </div>
    } 
</div>
};

(:~
 : Build advanced search form using either search-config.xml or the default form search:default-search-form()
 : @param $collection. Optional parameter to limit search by collection. 
 : @note Collections are defined in repo-config.xml
 : @note Additional Search forms can be developed to replace the default search form. 
:)
declare function search:search-form($node as node(), $model as map(*), $collection as xs:string?){
if(exists(request:get-parameter-names())) then ()
else 
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return search:default-search-form()
};

(:~
 : Builds a simple advanced search from the search-config.xml. 
 : search-config.xml provides a simple mechinisim for creating custom inputs and XPaths, 
 : For more complicated advanced search options, especially those that require multiple XPath combinations
 : we recommend you add your own customizations to search.xqm
 : @param $search-config a values to use for the default search form and for the XPath search filters. 
:)
declare function search:build-form($search-config) {
    let $config := doc($search-config)
    return 
        <form method="get" class="form-horizontal indent" role="form">
            <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
            {if($config//search-tips != '') then 
                    (<button type="button" class="btn btn-info pull-right clearfix search-button" data-toggle="collapse" data-target="#searchTips">
                        Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span></button>,                       
                    if($config//search-tips != '') then
                    <div class="panel panel-default collapse" id="searchTips">
                        <div class="panel-body">
                        <h3 class="panel-title">Search Tips</h3>
                        {$config//search-tips}
                        </div>
                    </div>
                    else ())
                else ()}
            <div class="well well-small search-box">
                <div class="row">
                    <div class="col-md-10">{
                        for $input in $config//input
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{string($input/@label)}: 
                                {if($input/@title != '') then 
                                    <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="{string($input/@title)}"></span>
                                else ()}
                                </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" 
                                        id="{$id}" 
                                        name="{$name}" 
                                        data-toggle="tooltip" 
                                        data-placement="left" class="form-control keyboard"/>
                                        {($input/@title,$input/@placeholder)}
                                        {
                                            if($input/@keyboard='yes') then 
                                                <span class="input-group-btn">{global:keyboard-select-menu($id)}</span>
                                             else ()
                                         }
                                    </div> 
                                </div>
                            </div>}
                    </div>
                </div> 
            </div>
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn btn-warning">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </form> 
};


(:~
 : Simple default search form to us if not search-config.xml file is present. Can be customized. 
:)
declare function search:default-search-form() {
    <form method="get" class="form-horizontal indent" role="form">
        <h1 class="search-header">Search</h1>
        <div class="well well-small search-box">
        {let $search-config := 
            if(doc-available(concat($config:app-root,'/','search-config.xml'))) then concat($config:app-root,'/','search-config.xml')
            else concat($config:app-root, '/search-config.xml')
         let $config := 
                if(doc-available($search-config)) then doc($search-config)
                else ()                            
         return 
                if($config != '') then 
                    (<button type="button" class="btn btn-info pull-right clearfix search-button" data-toggle="collapse" data-target="#searchTips">
                        Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span></button>,                       
                    if($config//search-tips != '') then
                    <div class="panel panel-default collapse" id="searchTips">
                        <div class="panel-body">
                        <h3 class="panel-title">Search Tips</h3>
                        {$config//search-tips}
                        </div>
                    </div>
                    else if(doc-available($config:app-root || '/searchTips.html')) then doc($config:app-root || '/searchTips.html')
                    else ())
                else ()}
            <div class="row top-padding">
                <div class="col-md-10">
                    <!-- Keyword -->
                    
                 <div class="form-group">
                    <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <div class="input-group">
                            <input type="text" id="qs" name="q" class="form-control keyboard"/>
                            <div class="input-group-btn">{global:keyboard-select-menu('qs')}</div>
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
                                   {global:keyboard-select-menu('author')}
                            </div>
                         </div>   
                    </div>
                </div>
                <div class="form-group">
                    <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                    <div class="col-sm-10 col-md-9">
                        <div class="input-group">
                            <input type="text" id="title" name="title" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    {global:keyboard-select-menu('title')}
                            </div>
                            <div class="input-group-btn" style="width:50%;">
                                <select name="fq" class="form-control">
                                <option value=""> -- Limit by Catalog -- </option>
                                {search:catalog-limit()}
                                </select>
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
               <div class="form-group">
                    <label for="cds" class="col-sm-2 col-md-3 control-label">Dates: </label>
                    <div class="col-sm-10 col-md-9 form-inline">
                        <input type="text" id="startDate" name="startDate" placeholder="Start Date" class="form-control"/>&#160;
                        <input type="text" id="endDate" name="endDate" placeholder="End Date" class="form-control"/>
                        <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                    </div>
                </div>
                <!-- end col  -->
                </div>
                <!-- end row  -->
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
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
concat("collection('",$config:data-root,"')//tei:TEI",
    search:keyword(),
    data:element-search('author',request:get-parameter('author', '')),
    data:element-search('title',request:get-parameter('title', '')),
    search:section(),
    search:corpus-id(),
    search:syriaca-id(),
    search:text-id(),
    search:nhsl-edition(),
    search:bibl-edition(),
    search:dates()
    )
};

(: Corpus specific search fields:) 
declare function search:corpus-id(){
    if(request:get-parameter('corpus-uri', '') != '') then 
        concat("[.//tei:publicationStmt/tei:idno = '",request:get-parameter('corpus-uri', ''),"']") 
    else () 
};

declare function search:bibl-edition(){
    if(request:get-parameter('bibl-edition', '') != '') then 
        concat("[.//tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:idno[@type='URI'][. = '",request:get-parameter('bibl-edition', ''),"']]") 
    else () 
};

declare function search:nhsl-edition(){
    if(request:get-parameter('nhsl-edition', '') != '') then 
        concat("[.//tei:fileDesc/tei:titleStmt/tei:title[@ref = '",request:get-parameter('nhsl-edition', ''),"']]") 
    else () 
};

declare function search:syriaca-id(){
    if(request:get-parameter('syriaca-uri', '') != '') then 
        concat("[.//tei:titleStmt/tei:title[@ref = '",request:get-parameter('syriaca-uri', ''),"']]") 
    else ()
};

declare function search:text-id(){
    if(request:get-parameter('text-id', '') != '') then 
        concat("[.//tei:div1[@n = '",request:get-parameter('text-id', ''),"']]") 
    else () 
};

declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := data:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($config:data-root || '/bibl')//tei:body[ft:query(.,$terms, data:search-options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()  
};

(: NOTE add additional idno locations, ptr/@target @ref, others? :)
declare function search:idno(){
    if($search:idno != '') then 
         (:concat("[ft:query(descendant::tei:idno, '&quot;",$search:idno,"&quot;')]"):)
         concat("[.//tei:idno = '",$search:idno,"']")
    else () 
};

declare function search:catalog-limit(){
    for $r in collection($config:data-root)//tei:titleStmt/tei:title[@level="s"]
    group by $group := $r/@ref
    order by global:build-sort-string($r[1]/text(),'')
    return <option value="{concat(';fq-Catalog:',$group)}">{$r[1]/text()}</option>
};

declare function search:section(){
    if(request:get-parameter('section', '') != '') then 
        concat("[ft:query(.//tei:body/tei:div1/tei:div2/tei:head,'",request:get-parameter('section', ''),"',data:search-options())]") 
    else ()
};

(: Corpus search functions :)
declare function search:strip-chars($string){
let $query-string := $string
let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) then 
	       replace($query-string, '"', ' ')
	   else $query-string   (:if there is an uneven number of quotation marks, delete all quotation marks.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
let $query-string := replace($string,"'","''")	   
return 
    if(matches($query-string,"(^\*$)|(^\?$)")) then 'Invalid Search String, please try again.' (: Must enter some text with wildcard searches:)
    else replace(replace($query-string,'<|>|@',''), '(\.|\[|\]|\\|\||\-|\^|\$|\+|\{|\}|\(|\)|(/))','\\$1') (: Escape special characters. Fixes error, but does not return correct results on URIs see: http://viaf.org/viaf/sourceID/SRP|person_308 :)
};

(:~
 : Search options passed to ft:query functions
:)
declare function search:options($proximity){
let $phrase-slop := if($proximity castable as xs:integer) then xs:integer($proximity) else xs:integer(1)
return
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>{$phrase-slop}</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
};

(:
 : Build full-text keyword search over full record data 
:)
declare function search:keyword(){
    if(request:get-parameter('q', '') != '') then
        let $string := if(request:get-parameter('keywordProximity', '') castable as xs:integer) then
                            concat('"',search:strip-chars(request:get-parameter('q', '')),'"','~',request:get-parameter('keywordProximity', ''))
                       else search:strip-chars(request:get-parameter('q', ''))
        return concat("[descendant::tei:teiHeader[ft:query(.,'",$string,"')] or descendant::tei:div[ft:query(.,'",$string,"')]]") 
    else () 
};

(: Courpus date range :)
(:~
 : Build date range for origDate 
 : tei:origDate[@to|@from|@when]
:)
declare function search:dates(){
let $start := request:get-parameter('startDate', '')
let $end := request:get-parameter('endDate', '')
return 
    if($start != '') then 
        if($end != '') then 
            concat("[descendant::tei:origDate
                [(@from gt '",global:make-iso-date($start),"' and @to lt '",global:make-iso-date($end),"') 
                or (@from gt '",global:make-iso-date($start),"' and not(exists(@to)))
                or (@when gt '",global:make-iso-date($start),"' and @when lt '",global:make-iso-date($end),"')
                ]]")
                
        else
            concat("[descendant::tei:origDate
                [@from gt '",global:make-iso-date($start),"' 
                or @to gt '",global:make-iso-date($start),"'
                or @when gt '",global:make-iso-date($start),"'
                ]]")
    else if ($end != '') then 
        concat("[descendant::tei:origDate
            [@to lt '",global:make-iso-date($end),"' 
            or @from lt '",global:make-iso-date($end),"' and not(@to)]
            or @when lt '",global:make-iso-date($end),"'
            ]")
    else ''
};

