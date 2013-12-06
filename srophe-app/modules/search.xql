xquery version "3.0";

module namespace search="http://syriaca.org//search";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $search:q {request:get-parameter('q', '')};
declare variable $search:mode {request:get-parameter('mode', '')};
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

declare function search:build-get-results($node as node(), $model as map(*)){
    map {"hits" := search:get-hits()}
};

declare function search:get-hits(){
    let $query := search:build-ft-query()
    for $hit in collection($config:app-root || "/data/places/tei")//tei:place[ft:query(., $query)]
    order by ft:score($hit) descending
    return $hit
};

declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*)) {
    for $hit at $p in subsequence($model("hits"), $search:start, 10)
    let $kwic := kwic:summarize($hit, <config width="40" table="no"/>)
(: kwic:summarize($hit as element(), $config as element()?) as element()*  
let $kwic := kwic:summarize($hit, <config width="40" table="yes"/>,''):)
    return
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml">
        <div class="span10 offset1">
        <div class="result">
          <div class="span1" >
            <span class="number">{$search:start + $p - 1}</span>
          </div>
          <div class="span9">  
            <p style="font-weight:bold">
                <bdi dir="ltr" lang="en" xml:lang="en">
                    {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']}
                </bdi>
                <bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>
                <bdi dir="rtl" lang="syr" xml:lang="syr">
                    {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']}
                </bdi>
            </p>
            <div>{
                for $summary at $h in subsequence($kwic, 1, 5) 
                return $summary
            }</div>
            </div>
            </div>
        </div>
        
        </div>
};

