xquery version "3.0";
(:~
 : Builds browse page for Syriac Gazetteer
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and transformed by ../resources/xsl/browselisting.xsl
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
 : @param $lang selects language for browse display
 : @param $sort passes browse by letter for alphabetical browse lists
 :)
 
declare variable $browse:lang {request:get-parameter('lang', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};

(:~
 : Initialize search string
:)
declare function browse:get-places($node as node(), $model as map(*)){
     map { "places-data" := collection($config:app-root || "/data/places/tei")//tei:place[tei:placeName[@xml:lang = 'en'][starts-with(@syriaca-tags, '#syriaca-headword')]]}
};

(:~
 : Build English browse list
 : @param $browse:lang indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 : Final sorting is handled by xslt ../resources/xsl/browselisting.xsl
 :)
declare function browse:get-place-en($node as node(), $model as map(*)){
    for $place-name in $model("places-data")
    let $title := $place-name/tei:placeName[1]/text()
    let $browse-title := browse:build-sort-string($title)
    where contains(browse:get-sort(),substring($browse-title,1,1))
    order by $browse-title
    return $place-name 
};

(:~
 : @deprecated no longer needed and confusing for users
 : Build numbered English browse list, returns all results 
 : Returns all English titles, with no sort options applies.
 : Final sorting is handled by xslt ../resources/xsl/browselisting.xsl
 :)
declare function browse:get-place-all($node as node(), $model as map(*)){
    for $place-name in $model("places-data")
    return $place-name     
};

(:~
 : Build Syriac browse list
 : @param $browse:lang indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Final sorting is handled by xslt ../resources/xsl/browselisting.xsl
 :)
declare function browse:get-place-syr($node as node(), $model as map(*)){
    for $place-name in $model("places-data")/self::*[tei:placeName[@xml:lang = 'syr']]
    let $title := $place-name/tei:placeName[@xml:lang = 'syr']/text()
    let $title-length := string-length($title)
    let $title-letter := substring($title,1,1)
    where contains($title-letter,$browse:sort)
    order by $title collation "?lang=syr"
    return $place-name
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
        else if($browse:sort = 'O') then 'O o Œ œ'
        else $browse:sort
    else 'A a ẵ Ẵ ằ Ằ ā Ā'
};

(:~
 : Strips english titles of non-sort characters as established by The Syriac Gazetteer
 :)
declare function browse:build-sort-string($titlestring){
    replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]','')
};

(:~
 : Returns a list of unique values for the first letter of each title
 : @param $browse:lang indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 :)
declare function browse:get-letter-menu($node as node()){
    distinct-values(
    for $place-name in collection($config:app-root || "/data/places/tei")//tei:placeName[starts-with(@syriaca-tags, '#syriaca-headword')]
    let $title := $place-name/text()
    let $browse-title := browse:build-sort-string($title)
    return substring($browse-title,1,1)
    ) 
};

(:~
 : Builds tei node to be transformed by xslt
 : Final results are passed to ../resources/xsl/browselisting.xsl
 :)
declare %templates:wrap function browse:get-place-names($node as node(), $model as map(*)){
    let $cache := 'testing3457'
    let $results := 
     <tei:TEI xml:lang="en"
        xmlns:xi="http://www.w3.org/2001/XInclude"
        xmlns:svg="http://www.w3.org/2000/svg"
        xmlns:math="http://www.w3.org/1998/Math/MathML"
        xmlns="http://www.tei-c.org/ns/1.0" browse-type="{$browse:lang}" browse-sort="{$browse:sort}">
        <tei:menu xmlns="http://www.tei-c.org/ns/1.0">{browse:get-letter-menu($node)}</tei:menu>
        { if(exists($browse:lang)) then 
            if($browse:lang ='en') then browse:get-place-en($node, $model)
            else if($browse:lang ='syr') then browse:get-place-syr($node, $model)
            else if($browse:lang ='num') then browse:get-place-all($node, $model)
            else browse:get-place-en($node, $model)
           else browse:get-place-en($node, $model)
           }
     </tei:TEI>  
    return transform:transform($results, doc('../resources/xsl/browselisting.xsl'),() )
};
