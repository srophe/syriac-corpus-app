xquery version "3.0";

module namespace search="http://syriaca.org//search";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $search:q {request:get-parameter('q', '')};
declare variable $search:mode {request:get-parameter('mode', '')};
declare variable $search:place {request:get-parameter('place', '')};
declare variable $search:type {request:get-parameter('place', '')};
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};

declare function search:build-ft-query(){
    <query>
        {
            if ($search:mode eq 'any') then
                for $term in tokenize($search:q, '\s')
                return
                    <term occur="should">{$term}</term>
            else if ($search:mode eq 'all') then
                for $term in tokenize($search:q, '\s')
                return
                    <term occur="must">{$term}</term>
            else if ($search:mode eq 'phrase') then
                <phrase>{$search:q}</phrase>
            else
                <near>{$search:q}</near>
        }
        </query>
};

declare function search:build-predicates(){
    let $keyword := if(exists($search:q) and $search:q != '') then concat('[',ft:query(., search:build-ft-query()),']')
                    else ''
    let $place   := if(exists($search:place) and $search:place != '') then concat('[',ft:query(tei:placeName, search:build-ft-query()),']')
                    else ''  
    (:NOTE, may need to have moe sophisticated processing for type, if no other params exist?:)
    let $type    := if(exists($search:type) and $search:type != '') then concat('[',@type=$search:type,']')
                    else '' 
    return ($keyword,$place,$type)                
};
declare function search:build-get-results($node as node(), $model as map(*)){
    map {"hits" := search:get-hits()}
};

declare function search:get-hits(){
    let $query := search:build-ft-query()
    let $eval-string := concat("collection('/db/apps/srophe/data/places/tei')//tei:place",'[ft:query(.,search:build-ft-query())]')
    let $hits := util:eval($eval-string)    
    for $hit in $hits
(:    for $hit in collection($config:app-root || "/data/places/tei")//tei:place[ft:query(., $query)]:)
(:    for $hit in collection($config:app-root || "/data/places/tei")//tei:place[ft:query(tei:placeName, 'edessa')][@type ='settlement']:)
    order by ft:score($hit) descending
    return $eval-string
};

declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

declare  %templates:wrap function search:pageination($node as node()*, $model as map(*)){
let $max := search:hit-count($node, $model)
let $records := 20
let $prev := $search:start  - $records
let $next := if ($max < $search:start +$records) then $search:start 
             else $search:start + $records
let $start := if($search:start) then $search:start else 1             
let $end := min (($search:start + $records - 1,$max)) 
let $pages := round($max div $records) + 1
return
    <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px solid #333; padding-top: 2em;">
    <div class="span6">
        Found: {$max} matches for <span class="match" style="font-weight:bold;">{$search:q}</span>.
    </div>
    <div class="span6">
      <ul class="inline pull-right">
        <li><a href="?q={$search:q}&amp;start=1"><i class="icon-step-backward"></i></a></li>
        <li>
            {
                if($start = 1) then <i class="icon-backward"></i> 
                else <a href="?q={$search:q}&amp;start={$prev}"><i class="icon-backward"></i></a> 
            }
        </li>
        <li>
            {$start} to 
            {
                if($max lt $records) then $max
                else $search:start + $records
            } 
            of {$max}
        </li>
        <!--<li>Jump to: </li>-->
        <li>
            {
                if($start lt $max - $records) then <i class="icon-forward"></i>
                else <a href="?q={$search:q}&amp;start={$next}"><i class="icon-forward"></i></a>
            }
        </li>
        <li><a href="?q={$search:q}&amp;start={$max - $records}"><i class="icon-step-forward"></i></a></li>
      </ul>
    </div>
    <!--
    for $summary at $h in subsequence($kwic, 1, 5) 
                return $summary
                
    NOTE: need better handling for 1st page, prev and next  
    also, problems if there are more then 10 pages of results..
    -->
    <!--
    <div class="span6 pagination">
      <ul>
        <li><a href="?q={$search:q}&amp;start={$prev}">Prev</a></li>
        {
            for $page in (1 to $pages)
            let $page-start := $records * $page
            return 
            <li><a href="?q={$search:q}&amp;start={$page-start}">{$page}</a></li>
        }
        <li><a href="?q={$search:q}&amp;start={$next}">Next</a></li>
      </ul>
    </div>
    -->
    </div>
};

declare 
    %templates:default("start", 1)
function search:show-form($node as node()*, $model as map(*)) {
    <div>
    <form method="get" action="search.html">  
        <!-- Full text -->
        <label>Place Name: </label>
        <input type="text" name="place"/>
        <!-- range -->
        <label>Type: </label>
        <!-- Values from controlled vocab in https://docs.google.com/spreadsheet/ccc?key=0AnhFTnX2Mw6YdGFieExCX0xIQ3Q0WnBOQmlnclo0WlE&usp=sharing#gid=1-->
        <select name="type">
            <option value="">- Select -</option>
            <option value="settlement">settlement</option>
            <option value="monastery">monastery</option>
            <option value="region">region</option>
            <option value="province">province</option>
            <option value="open-water">open-water</option>
            <option value="fortification">fortification</option>
            <option value="mountain">mountain</option>
            <option value="quarter">quarter</option>
            <option value="state">state</option>
            <option value="building">building</option>
            <option value="diocese">diocese</option>
            <option value="island">island</option>
            <option value="parish">parish</option>
            <option value="unknown">unknown</option>
        </select>
        <br/>
    <input type="submit" name="Submit"/>
</form>
    </div>
};

declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*)) {
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    let $kwic := kwic:summarize($hit, <config width="40" table="no"/>)
    let $id := substring-after($hit/@xml:id,'place-')
(: kwic:summarize($hit as element(), $config as element()?) as element()*  
let $kwic := kwic:summarize($hit, <config width="40" table="yes"/>,'')
            <div>{
                for $summary at $h in subsequence($kwic, 1, 5) 
                return $summary
            }</div>
:)
    return
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px solid #ccc; padding-top:.5em">
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
                {$hit/tei:desc[starts-with(@xml:id,'abstract')]/descendant-or-self::text()}
            </div>
            </div>
            </div>
        </div>
        
        </div>
};

