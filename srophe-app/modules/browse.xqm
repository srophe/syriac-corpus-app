xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace browse="http://syriaca.org//browse";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";
import module namespace templates="http://syriaca.org//templates" at "templates.xql";
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

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
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:fq {request:get-parameter('fq', '')};

(:~
 : Build browse path for evaluation 
 : NOTE: causes problems for persons and places
:)
declare function browse:get-all($node as node(), $model as map(*), $coll as xs:string?){
let $browse-path := 
    if($coll = 'persons') then concat("collection('",$config:app-root,"/data/persons/tei')//tei:person",browse:get-syr()) 
    else if($coll = 'saints') then concat("collection('",$config:app-root,"/data/persons/tei/saints')//tei:person",browse:get-syr())
    else if($coll = 'places') then concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr())
    else if(exists($coll)) then concat("collection('",$config:app-root,"/data/",xs:anyURI($coll),"/tei')//tei:body",browse:get-syr())
    else concat("collection('",$config:app-root,"/data')//tei:body",browse:get-syr())
return 
    map{"browse-data" := util:eval($browse-path)}        
};


(:~
 : Filter titles by syriac 
 : @param $browse:view
:)
declare function browse:get-syr(){
    if($browse:view = 'syr') then
        "[descendant::*[@xml:lang = 'syr'][@syriaca-tags='#syriaca-headword']]"
    else ()    
};
(:~
 : Build default browse listings
 : NOTE: add collection varaible here as well use it to build browse links
:)
declare function browse:browse-results($node as node(), $model as map(*), $coll as xs:string?){
    for $data in $model('browse-data')
    let $en-title := $data/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]
    let $syr-title := $data/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/tei:foreign
    let $title := 
        if($browse:view = 'syr') then $syr-title else $en-title
    let $browse-title := browse:build-sort-string($title)
    let $id := $data/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][2]/text()
    where contains(browse:get-sort(), substring($browse-title,1,1))
    order by $title
    return 
        browse:display-titles($title,$id, $coll)
}; 

declare function browse:display-titles($title as node(), $id as xs:string?, $coll as xs:string?){
    if($browse:view = 'syr') then 
    <li>
        <a href="{$coll}.html?id={$id}">Syr: {$title/text()}</a>
    </li>
   else
    <li>
        <a href="{$coll}.html?id={$id}">Eng: {$title/text()}</a>
    </li>
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
 : Strips english titles of non-sort characters as established by The Syriac Gazetteer
 :)
declare function browse:build-sort-string($titlestring){
    replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]','')
};

declare  %templates:wrap function browse:browse-abc-menu($node as node(), $model as map(*), $coll){
if(($browse:view = 'en') or ($browse:view='')) then
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
            <li><a href="?view={$browse:view}&amp;sort=all">All</a></li>
            {
                let $vals := $model('browse-data')/upper-case(substring(normalize-space(/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/text()),1,1))
                (:let $vals := upper-case(substring(normalize-space($titles),1,1)):)
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    if(contains($vals,$letter)) then 
                    <li><a href="?view={$spear:view}&amp;sort={$letter}">{$letter}</a></li>
                    else <li>{$letter}</li>
            }
        </ul>
    </div>
else if(($browse:view = 'syr')) then  
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
            <li><a href="?view={$browse:view}&amp;sort=all">All</a></li>
            {
                let $vals := $model('browse-data')/upper-case(substring(normalize-space(/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/tei:foreign/text()),1,1))
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return
                    if(contains($vals,$letter)) then 
                    <li><a href="?view={$spear:view}&amp;sort={$letter}">{$letter}</a></li>
                    else <li>{$letter}</li>
            }
        </ul>
    </div>
else ()        
};


declare  %templates:wrap function browse:browse-maps($node as node(), $model as map(*)){
if($browse:view = 'map') then
    if($model('browse-data')//tei:geo) then
        let $geo-hits := $model("browse-data")//tei:geo
        return geo:build-map($geo-hits,'','')
    else ()
else ()    
};

declare function browse:build-tabs($node as node(), $model as map(*), $coll as xs:string?){
if($coll = 'persons') then 
    <ul class="nav nav-tabs" id="nametabs">
        <li>{if(not($browse:view)) then 
                attribute class {'active'} 
             else if($browse:view = 'en') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
        </li>
        <li>{if($browse:view = 'syr') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
        </li>
        <li>{if($browse:view = 'type') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=type">Type</a>
        </li>
        <li>{if($browse:view = 'date') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=date">Date</a>
        </li>
    </ul>
else if($coll = 'saints') then 
    <ul class="nav nav-tabs" id="nametabs">
        <li>{if(not($browse:view)) then 
                attribute class {'active'} 
             else if($browse:view = 'en') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
        </li>
        <li>{if($browse:view = 'syr') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
        </li>
        <li>{if($browse:view = 'date') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=date">Date</a>
        </li>
    </ul>    
else if($coll = 'places') then
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
        {
        if($model('browse-data')//tei:geo) then 
        <li>{if($browse:view = 'map') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=map">Map</a>
        </li>
        else ()
        }
    </ul>
};
