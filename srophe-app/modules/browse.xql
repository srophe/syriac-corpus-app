xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace browse="http://syriaca.org//browse";

import module namespace templates="http://syriaca.org//templates" at "templates.xql";
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace ngram="http://exist-db.org/xquery/ngram";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse display 
 : @param $browse:type selects doc type filter
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')}; 
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:type-map {request:get-parameter('type-map', '')};

(:~
 : Build browse path for evaluation
:)
declare function browse:get-all($node as node(), $model as map(*)){
let $browse-path := 
    if(exists($browse:coll)) then 
        if($browse:coll = 'persons') then concat("collection('",$config:app-root,"/data/persons/tei')//tei:person",browse:get-syr()) 
        else if($browse:coll = 'places') then concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr()) 
        else concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr())
    else concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr())
return 
    map{"browse-data" := util:eval($browse-path)}        
};

(:~
 : Build browse using supplied options
 : @param $browse:type place type browse
 : @param $browse:view browse option, lang or map
 : @param $browse:sort place returned by first character in title
:)
declare function browse:build-browse-results($node as node(), $model as map(*)){  
    for $data in $model('browse-data')
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $en-title := 
        $data/tei:placeName[starts-with(@xml:lang,'en')][1]/text() | 
        $data/tei:persName[starts-with(@xml:lang,'en')][@syriaca-tags='#syriaca-headword'][1]/child::*[1]/text()
    let $syr-title := 
        $data/tei:placeName[@xml:lang = 'syr'][1]/text() |
        $data/tei:persName[starts-with(@xml:lang,'syr')][@syriaca-tags='#syriaca-headword'][1]/child::*[1]/text()
    let $title := 
        if($browse:view = 'syr') then $syr-title else $en-title
    let $browse-title := browse:build-sort-string($title)
    where contains(browse:get-sort(), substring($browse-title,1,1))
    return
        <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name
            }
        </browse>
};

(:~
 : Returns a list places by type
 : @param $browse:type indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 let $eval-string := concat("$model('browse-data')//self::*[@type = ",$browse:type,"]")
    let $results := util:eval($eval-string)    
    for $place-name in $results
:)
declare function browse:get-place-type($node as node(), $model as map(*)){
    for $data in $model('browse-data')//self::*[@type = $browse:type]
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $title := 
        if($browse:view = 'syr') then $data/tei:placeName[@xml:lang = 'syr'][1]/text()
        else $data/tei:placeName[1]/text()
    let $browse-title := browse:build-sort-string($title)
    let $geo := $data/descendant::*/tei:geo
(:    where matches($place-name/@type, $browse:type):)
    order by $browse-title
    return 
     <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                (
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name,
                $geo
                )
            }
        </browse>
};



(:~
 : Returns a list persons by type
 : @param $browse:type indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 :)
declare function browse:get-pers-type($node as node(), $model as map(*)){
    for $data in $model('browse-data')//self::*[@ana = concat('#',$browse:type)]
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $title := 
        if($browse:view = 'syr') then $data/tei:placeName[@xml:lang = 'syr'][1]/text()
        else $data/tei:placeName[1]/text()
    let $browse-title := browse:build-sort-string($title)
    let $geo := $data/descendant::*/tei:geo
(:    where matches($place-name/@type, $browse:type):)
    order by $browse-title
    return 
     <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                (
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name,
                $geo
                )
            }
        </browse>
};

(:Work in progress to streamline 
declare function browse:get-ana(){
    if($browse:type != '') then
        if($browse:coll = 'persons') then 
            concat("[self::*[@ana = '#", $browse:type,"']]")
        else concat("//self::*[@type =", $browse:type,"]")
    else ()    
};
:)

(:~
 : Filter titles by syriac 
 : @param $browse:view
:)
declare function browse:get-syr(){
    if($browse:view = 'syr') then
        "[child::*[@xml:lang = 'syr'][@syriaca-tags='#syriaca-headword']]"
    else ()    
};
(:~
 : Filter titles by type 
 : @param $browse:view
:)
declare function browse:get-type(){
    if($browse:type != '') then
        concat('[@type =', $browse:type,']')
    else ()    
};
(:~
 : Builds collation for syriac results
 : @param $browse:view
:)
declare function browse:get-order(){
    if($browse:view = 'syr') then
        'collation "?view=syr"'
    else ()
};

(:~
 : Matches English letters and thier equivalent letters as established by The Syriac Gazetteer
 : @param $browse:sort indicates letter for browse
 :)
declare function browse:get-sort(){
    if(exists($browse:sort) and $browse:sort != '') then
        if($browse:sort = 'A') then 'A a ẵ Ẵ ằ Ằ ā Ā'
        else if($browse:sort = 'D') then 'D d đ Đ'
        else if($browse:sort = 'S') then 'S s š Š ṣ Ṣ'
        else if($browse:sort = 'E') then 'E e ễ Ễ'
        else if($browse:sort = 'U') then 'U u ū Ū'
        else if($browse:sort = 'H') then 'H h ḥ Ḥ'
        else if($browse:sort = 'T') then 'T t ṭ Ṭ'
        else if($browse:sort = 'I') then 'I i ī Ī'
        else if($browse:sort = 'O') then 'O Ō o Œ œ'
        else $browse:sort
    else 'A a ẵ Ẵ ằ Ằ ā Ā'
};

(:~
 : Returns a list of unique values for the first letter of each title
 : @depreciated, currently have data for every letter, function adds unnecessarily to processing time
 : @param $browse:view indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
declare function browse:get-letter-menu($node as node(), $model as map(*)){
    distinct-values(
        for $place in $model("browse-data")//tei:place
        let $title := $place/tei:placeName[1]/text()
        let $browse-title := browse:build-sort-string($title)
        return substring($browse-title,1,1)
    ) 
};
:)

(:~
 : Strips english titles of non-sort characters as established by The Syriac Gazetteer
 :)
declare function browse:build-sort-string($titlestring){
    replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]','')
};


(:~
 : Returns a count of all places with coordinates
:)
declare function browse:count-geo($node as node(), $model as map(*)){
    count($model("browse-data")//self::*[descendant::*/tei:geo]) 
};
(:~
 : Returns a count of all places with coordinates
:)
declare function browse:count-all($node as node(), $model as map(*)){
    count($model("browse-data")) 
};

(:~
 : Build browse type
:)
declare function browse:type-counts($node as node(), $model as map(*)){
if($browse:view = 'type') then 
    if($browse:coll = 'persons') then 
    <div class="span4">
        <ul class="nav nav-tabs nav-stacked pull-left type-nav">
            {
            let $types := 'syriaca-author syriaca-saint'
            for $type in tokenize($types,' ')
            return 
                <li>{if($browse:type = $type) then attribute class {'active'} else '' }
                    <a href="?view=type&amp;type={$type}&amp;coll=persons">{$type} &#160; 
                        <span class="count">({count(for $type-count in $model("browse-data")//self::*[@ana = concat('#',$type)] return $type-count)})</span>
                    </a>
                </li>
            }
        </ul>
    </div>
    else
    <div class="span4">
        <ul class="nav nav-tabs nav-stacked pull-left type-nav">
            {
            let $types := 'building church diocese fortification island madrasa monastery mosque mountain open-water parish province quarter region river settlement state synagogue temple unknown'
            for $type in tokenize($types,' ')
            return 
                <li>{if($browse:type = $type) then attribute class {'active'} else '' }
                    <a href="?view=type&amp;type={$type}">{$type} &#160; 
                        <span class="count">({count(for $type-count in $model("browse-data")//self::*[@type = $type]return $type-count)})</span>
                    </a>
                </li>
            }
        </ul>
    </div>    
else ''    
};

declare function browse:build-tabs($node as node(), $model as map(*)){
if($browse:coll = 'persons') then 
<ul class="nav nav-tabs" id="nametabs">
    <li>{if(not($browse:view)) then 
            attribute class {'active'} 
         else if($browse:view = 'en') then 
            attribute class {'active'} 
         else '' }<a href="browse.html?view=en&amp;sort=A&amp;coll={$browse:coll}">English</a>
    </li>
    <li>{if($browse:view = 'syr') then 
            attribute class {'active'} 
         else '' }<a href="browse.html?view=syr&amp;sort=ܐ&amp;coll={$browse:coll}" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
    </li>
    <li>{if($browse:view = 'type') then 
            attribute class {'active'}
         else '' }<a href="browse.html?coll={$browse:coll}&amp;view=type">Type</a>
    </li>
</ul>
else
<ul class="nav nav-tabs" id="nametabs">
    <li>{if(not($browse:view)) then 
            attribute class {'active'} 
        else if($browse:view = 'en') then 
            attribute class {'active'} else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
    </li>
    <li>{if($browse:view = 'syr') then 
            attribute class {'active'} 
         else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
    </li>
    <li>{if($browse:view = 'type') then 
            attribute class {'active'}
         else '' }<a href="browse.html?view=type">Type</a>
    </li>
    <li>{if($browse:view = 'map') then 
            attribute class {'active'} 
         else '' }<a href="browse.html?view=map">Map</a>
    </li>
</ul>
};

(:~
 : Builds tei node to be transformed by xslt
 : Final results are passed to ../resources/xsl/browselisting.xsl
 :)
declare %templates:wrap function browse:get-browse-names($node as node(), $model as map(*)){
    let $cache := 'change this value to force page refresh 289986983766'
    let $results := 
     <tei:TEI xml:lang="en"
        xmlns:xi="http://www.w3.org/2001/XInclude"
        xmlns:svg="http://www.w3.org/2000/svg"
        xmlns:math="http://www.w3.org/1998/Math/MathML"
        xmlns="http://www.tei-c.org/ns/1.0" browse-coll="{$browse:coll}" browse-view="{$browse:view}" browse-sort="{$browse:sort}" browse-type="{$browse:type}" browse-type-map="{$browse:type-map}">
        {
            (
            if($browse:view = 'map') then 
                <tei:count-geo>
                *{browse:count-geo($node, $model)} of {browse:count-all($node, $model)} places have coordinates 
                and are shown on this map. <a href="#map-selection" role="button"  data-toggle="modal">
                Read more...</a>
                </tei:count-geo>
             else (),  
             if($browse:view = 'type') then 
                if($browse:type != '') then
                    if($browse:coll = 'persons') then 
                        browse:get-pers-type($node, $model)
                    else
                        browse:get-place-type($node, $model) 
                else 'Type'
             else browse:build-browse-results($node, $model)
            )
          }
     </tei:TEI>  
    return 
    (:$results:)
    transform:transform($results, doc('../resources/xsl/browselisting.xsl'),() )
};
