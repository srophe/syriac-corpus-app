xquery version "3.0";

module namespace search="http://syriaca.org//search";
import module namespace search-form="http://syriaca.org//search-form" at "search-form.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $search:q {request:get-parameter('q', '')};
declare variable $search:p {request:get-parameter('p', '')};
declare variable $search:type {request:get-parameter('type', '')};

declare variable $search:loc {request:get-parameter('loc', '')};
declare variable $search:lat {request:get-parameter('lat', '')};
declare variable $search:long {request:get-parameter('long', '')};

declare variable $search:e {request:get-parameter('e', '')};
declare variable $search:e-start {request:get-parameter('e-start', '')};
declare variable $search:e-end {request:get-parameter('e-end', '')};

declare variable $search:a {request:get-parameter('a', '')};
declare variable $search:a-start {request:get-parameter('a-start', '')};
declare variable $search:a-end {request:get-parameter('a-end', '')};

declare variable $search:c {request:get-parameter('c', '')};
declare variable $search:c-start {request:get-parameter('c-start', '')};
declare variable $search:c-end {request:get-parameter('c-end', '')};

declare variable $search:exist {request:get-parameter('exist', '')};
declare variable $search:exist-start {request:get-parameter('exist-start', '')};
declare variable $search:exist-end {request:get-parameter('exist-end', '')};

declare variable $search:lang {request:get-parameter('lang', '')};

declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
:)
declare function search:clean-string($param-string){
    replace ($param-string, "[&amp;&quot;-;-`~!@#$%^()_+-=\[\]\{\}\|';:/.,(:]", "")
};

(:~
 : Build full-text keyword search over all tei:place data
 : @q full text query
 descendant-or-self::* or . testing which is most correct
 
:)
declare function search:keyword(){
    if(exists($search:q) and $search:q != '') then concat('[ft:query(descendant-or-self::*,"',search:clean-string($search:q),'")]')
    else ''    
};

(:~
 : Build full-text keyword search over all tei:placeName data
 : @p full text query
:)
declare function search:place-name(){
    if(exists($search:p) and $search:p != '') then concat('[ft:query(tei:placeName,"',search:clean-string($search:p),'")]')
    else ''    
};

(:~
 : Build range search on tei:place/@type data
 : @type full text query
:)
declare function search:type(){
    if(exists($search:type) and $search:type != '') then string(concat('[@type = "',search:clean-string($search:type),'"]'))
    else '' 
};

(:~
 : Build full-text search on tei:place/tei:location data
 : @loc full text query
 : NOTE: need to understand location search better. 
:)
declare function search:location(){
    if(exists($search:loc) and $search:loc != '') then concat('[ft:query(tei:location,"',search:clean-string($search:loc),'")]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type != attestation] data
 NOTE: will probably have to build this into the date range, so they hold together as one AND predicate
 : @e full text query
:)
declare function search:event(){
    if(exists($search:e) and $search:e != '') then concat('[ft:query(tei:event[@type != "attestation" or not(@type)],"',search:clean-string($search:e),'")]')
    else ''
};

(:~
 : Build date range for event 
 : tei:event[@type != attestation]
 : @e-start event start range index
 : @e-end event end range index
//tei:place[descendant::tei:state[@syriaca-computed-start gt "1000-01-01" and @syriaca-computed-end lt "1200-01-01"]]
:)
declare function search:event-dates(){
    if(exists($search:e-start) and $search:e-start != '') then 
        if(exists($search:e-end) and $search:e-end != '') then 
            concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',search:do-date($search:e-start),'" and @syriaca-computed-end lt "',search:do-date($search:e-end),'"]]')
        else concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',search:do-date($search:e-start),'"]]') 
    else if (exists($search:e-end) and $search:e-end != '') then 
        concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-end lt "',search:do-date($search:e-end),'"]]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type = attestation] data
 : @e full text query
:)
declare function search:attestation(){
    if(exists($search:a) and $search:a != '') then concat('[ft:query(tei:event[@type = "attestation"],"',search:clean-string($search:a),'")]')
    else ''
};

(:~
 : Build date range for attestation
 : tei:event[@type = attestation]
 : @as attestation start range index
 : @ae attestation end range index
:)
declare function search:attestation-dates(){
    if(exists($search:a-start) and $search:a-start != '') then 
        if(exists($search:a-end) and $search:a-end != '') then 
            concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-start gt "',search:do-date($search:a-start),'" and @syriaca-computed-end lt "',search:do-date($search:a-end),'"]]')
        else concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-start gt "',search:do-date($search:a-start),'"]]') 
    else if (exists($search:a-end) and $search:a-end != '') then 
        concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-end lt "',search:do-date($search:a-end),'"]]')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = confession] data
 : @e full text query
:)
declare function search:confession(){
    if(exists($search:c) and $search:c != '') then concat('[ft:query(descendant::tei:state[@type = "confession"],"',search:clean-string($search:c),'")]')
    else ''
};

(:~
 : Build date range for confession
 : tei:state[@type = confession]
 : @a-start confession start range index
 : @a-end confession end range index
:)
declare function search:confession-dates(){
    if(exists($search:c-start) and $search:c-start != '') then 
        if(exists($search:c-end) and $search:c-end != '') then 
            concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',search:do-date($search:c-start),'" and @syriaca-computed-end lt "',search:do-date($search:c-end),'"]]')
        else concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',search:do-date($search:c-start),'"]]') 
    else if (exists($search:c-end) and $search:c-end != '') then 
        concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',search:do-date($search:c-end),'"]]')
    else ''
};

declare function search:show-confession-dates(){
    if(exists($search:c-start) and $search:c-start != '') then 
        if(exists($search:c-end) and $search:c-end != '') then 
            concat('/descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',search:do-date($search:c-start),'" and @syriaca-computed-end lt "',search:do-date($search:c-end),'"]')
        else concat('/descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',search:do-date($search:c-start),'"]') 
    else if (exists($search:c-end) and $search:c-end != '') then 
        concat('/descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',search:do-date($search:c-end),'"]')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = ‘existence’] data
 : @e full text query
:)
declare function search:existence(){
    if(exists($search:exist) and $search:exist != '') then concat('[ft:query(descendant::tei:state[@type = "confession"],"',search:clean-string($search:exist),'")]')
    else ''
};

(:~
 : Build date range for existence
 : tei:state[@type = existence]
 : @a-start confession start range index
 : @a-end confession end range index
:)
declare function search:existence-dates(){
    if(exists($search:exist-start) and $search:exist-start != '') then 
        if(exists($search:exist-end) and $search:exist-end != '') then 
            concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',search:do-date($search:exist-start),'" and @syriaca-computed-end lt "',search:do-date($search:exist-end),'"]]')
        else concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',search:do-date($search:exist-start),'"]]') 
    else if (exists($search:exist-end) and $search:exist-end != '') then 
        concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-end lt "',search:do-date($search:exist-end),'"]]')
    else ''
};

declare function search:show-existence-dates(){
    if(exists($exist-start) and $exist-start != '') then 
        if(exists($exist-end) and $exist-end != '') then 
            concat('/descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',search:do-date($search:exist-start),'" and @syriaca-computed-end lt "',search:do-date($search:exist-end),'"]')
        else concat('/descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',search:do-date($search:exist-start),'"]') 
    else if (exists($search:exist-end) and $search:exist-end != '') then 
        concat('/descendant::tei:state[@type = "existence"][@syriaca-computed-end lt "',search:do-date($search:exist-end),'"]')
    else ''
};

(:~
 : Function to cast dates strings from url to xs:date
 : Tests string length, may need something more sophisticated to test dates, 
 : or form validation via js before submit. 
 : @param $date passed to function from parent function
:)
declare function search:do-date($date){
let $date-format := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 3) then concat('0',string($date),'-01-01')
                    else string($date)
let $final-date := xs:date($date-format) 
return $final-date
};

(:need some clarification on what exactly is being limited by lang?:)
declare function search:limit-by-lang(){
    if(exists($search:lang) and $search:lang != '') then concat('[descendant::*/@lang = "',$search:lang,'"]')
    else ''
};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*)){
    let $eval-string := concat("collection('/db/apps/srophe/data/places/tei')//tei:place",
    search:keyword(),
    search:type(),
    search:place-name(),
    search:location(),
    search:event(),search:event-dates(),
    search:attestation(), search:attestation-dates(), 
    search:existence(),search:existence-dates(),
    search:confession(),search:confession-dates()
    )
    return
    map {"hits" := 
                let $hits := util:eval($eval-string)    
                for $hit in $hits
                let $id := substring-after($hit/@xml:id,'place-')
                order by ft:score($hit) descending
                return $hit
    }
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
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*)){
let $perpage := 20
let $start := if($search:start) then $search:start else 1
let $total-result-count := search:hit-count($node, $model)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function:)
let $url-params := replace(request:get-query-string(), '&amp;start=\d+', '')
let $parameters :=  request:get-parameter-names()
let $search-string: = 
        for $parameter in $parameters
        return if($parameter = 'search' or starts-with($parameter,'start')) then ''
               else search:clean-string(request:get-parameter($parameter, ''))
let $pagination-links := 
    if ($total-result-count = 0) then ()
    else 
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml">
            <div class="span5">
            <h4>Search results:</h4>
                <p class="offset1">{$total-result-count} matches for <span class="match" style="font-weight:bold;">{$search-string}</span>.</p>
            </div>
            {if(search:hit-count($node, $model) gt $perpage) then 
              <div class="span7" style="text-align:right">
                  <div class="pagination" >
                      <ul style="margin-bottom:-2em; padding-bottom:0;">
                          {
                          (: Show 'Previous' for all but the 1st page of results :)
                              if ($current-page = 1) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $perpage * ($current-page - 2)) }">Prev</a></li>
                          }
                          {
                          (: Show links to each page of results :)
                              let $max-pages-to-show := 8
                              let $padding := xs:integer(round($max-pages-to-show div 2))
                              let $start-page := 
                                  if ($current-page le ($padding + 1)) then
                                      1
                                  else $current-page - $padding
                              let $end-page := 
                                  if ($number-of-pages le ($current-page + $padding)) then
                                      $number-of-pages
                                  else $current-page + $padding - 1
                              for $page in ($start-page to $end-page)
                              let $newstart := 
                                  if($page = 1) then 1 
                                  else $perpage * ($page - 1)
                              return
                                  (
                                  if ($newstart eq $start) then 
                                      (<li class="active"><a href="#" >{$page}</a></li>)
                                  else
                                      <li><a href="{concat('?', $url-params, '&amp;start=', $newstart)}">{$page}</a></li>
                                  )
                          }
           
                          {
                          (: Shows 'Next' for all but the last page of results :)
                              if ($start + $perpage ge $total-result-count) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $start + $perpage)}">Next</a></li>
                          }
                      </ul>
                  </div>
              </div>
             else'' 
              }
        </div>    

return
   ($pagination-links,
   if(search:hit-count($node,$model) gt 0) then ''
   else <div>{search-form:show-form()}</div>
   )
};

(:~
 : Builds search form, called from search-form.xqm
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*)) {   
    if(exists(request:get-parameter-names())) then ''
    else <div>{search-form:show-form()}</div>
};

declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*)) {
<div class="well" style="background-color:white;">
{
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    let $kwic := kwic:summarize($hit, <config width="40" table="no"/>)
    let $id := substring-after($hit/@xml:id,'place-')
    return
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="span10 offset1">
                <div class="result">
                  <div class="span1" style="margin-right:-1em;">
                    <span class="label">{$search:start + $p - 1}</span>
                  </div>
                  <div class="span9">  
                    <p style="font-weight:bold padding:.5em;">
                        <a href="places/place.html?id={$id}">
                        <bdi dir="ltr" lang="en" xml:lang="en">
                            {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']}
                        </bdi>
                        <bdi dir="ltr" lang="en" xml:lang="en"> ({string($hit/@type)})</bdi>
                        {
                            if($hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']) then 
                                (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                                <bdi dir="rtl" lang="syr" xml:lang="syr">
                                    {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']}
                                </bdi>)
                             else ''  
                        }
                        </a>
                    </p>
                    <div style="margin-bottom:1em; margin-top:-1em; padding-left:1em;">
                     <!-- $kwic[1] gets keyword in context, but odd output with syriac due to right to left text 
                     <div>{
                        for $summary at $h in subsequence($kwic, 1, 5) 
                        return $summary
                    }</div>
                     -->
                        {$hit/tei:desc[starts-with(@xml:id,'abstract')]/descendant-or-self::text()}
                    </div>
                  </div>
                </div>
            </div>
        </div>
   }
   </div>
};

(:~
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*)) {
if(exists(request:get-parameter-names())) then (search:pageination($node,$model),search:show-hits($node, $model))
else ''
};