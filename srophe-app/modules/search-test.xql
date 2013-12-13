xquery version "3.0";


import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $q {request:get-parameter('q', '')};
declare variable $mode {request:get-parameter('mode', '')};
declare variable $place {request:get-parameter('place', '')};
declare variable $location {request:get-parameter('location', '')};
declare variable $type {request:get-parameter('type', '')};
declare variable $date {request:get-parameter('date', '') cast as xs:dateTime};
declare variable $start {request:get-parameter('start', 1) cast as xs:integer};



declare function local:build-ft-query(){
    <query>
        {
            if ($mode eq 'any') then
                for $term in tokenize($q, '\s')
                return
                    <term occur="should">{$term}</term>
            else if ($mode eq 'all') then
                for $term in tokenize($q, '\s')
                return
                    <term occur="must">{$term}</term>
            else if ($mode eq 'phrase') then
                <phrase>{$q}</phrase>
            else
                <near>{$q}</near>
        }
        </query>
};

declare function local:keyword(){
    if(exists($q) and $q != '') then concat('[ft:query(.,"',$q,'")]')
    else ''    
};

declare function local:type(){
    if(exists($type) and $type != '') then string(concat('[@type = "',$type,'"]'))
    else '' 
};
declare function local:place(){
    if(exists($place) and $place != '') then concat('[ft:query(tei:placeName,"',$place,'")]')
    else ''
};

declare function local:location(){
    if(exists($location) and $location != '') then concat('[ft:query(tei:location,"',$location,'")]')
    else ''
};
declare function local:dates(){
    if(exists($date) and $date != '') then concat('[@to = "',$date,'"]')
    else ''
};
declare function local:run-search(){
    let $eval-string := concat("collection('/db/apps/srophe/data/places/tei')//tei:place",
    local:keyword(),
    local:type(),
    local:place(),
    local:location(),
    local:dates())
    let $hits := util:eval($eval-string)    
    for $hit in $hits
    let $id := substring-after($hit/@xml:id,'place-')
    order by ft:score($hit) descending
    return 
            <div class="result" total="{count(util:eval($eval-string))}" search-string="{string($eval-string)}">
              <div class="span9">  
                <p style="font-weight:bold padding:.5em;">
                    <a href="places/place.html?id={$id}">
                    <bdi dir="ltr" lang="en" xml:lang="en">
                        {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']}
                    </bdi>
                    </a>
                </p>
                </div>
                </div>
};


let $cache := 'ddd'
return 
<div>
{local:run-search()}
</div>
    