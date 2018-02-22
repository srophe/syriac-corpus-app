xquery version "3.0";
(:~  
 : Builds browse pages for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists, browse by type, browse by date, map browse. 
 :
 : @see lib/facet.xqm for facets
 : @see lib/global.xqm for global variables
 : @see lib/paging.xqm for paging functionality
 : @see lib/maps.xqm for map generation
 : @see browse-spear.xqm for additional SPEAR browse functions 
 :)

module namespace browse="http://syriaca.org/browse";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "facet-defs.xqm";
import module namespace page="http://syriaca.org/page" at "lib/paging.xqm";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "lib/tei2html.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) from browse.html 
 : @param $browse:type selects doc type filter eg: place@type
 : @param $browse:view selects language for browse display
 : @param $browse:date selects doc by date
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')};
declare variable $browse:lang {request:get-parameter('lang', '')};
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:sort-element {request:get-parameter('sort-element', 'title')};
declare variable $browse:sort-order {request:get-parameter('sort-order', '')};
declare variable $browse:alpha-filter {request:get-parameter('alpha-filter', '')};
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $browse:perpage {request:get-parameter('perpage', 25) cast as xs:integer};
declare variable $browse:fq {request:get-parameter('fq', '')};

(:~
 : @depreciated
 : Set a default value for language, default sets to English. 
 : @param $browse:lang language parameter from URL
:)
declare variable $browse:computed-lang{ 
    if($browse:lang != '') then $browse:lang
    else if($browse:lang = '' and $browse:sort != '') then 'en'
    else if($browse:view = '') then 'en'
    else ()
};

(: @depreciated, use seriesStmt/title for collection browsing
 : Step one directory for browse 'browse path'
:)
declare function browse:collection-path($collection){
    if($collection = ('persons','sbd','saints','q','authors')) then 
        concat("collection('",$global:data-root,"/persons/tei')")
    else if($collection = 'places') then 
        concat("collection('",$global:data-root,"/places/tei')")
    else if($collection = ('bhse','nhsl')) then 
        concat("collection('",$global:data-root,"/works/tei')")
    else if($collection = 'bibl') then 
        concat("collection('",$global:data-root,"/bibl/tei')")
    else if($collection = 'spear') then 
        concat("collection('",$global:data-root,"/spear/tei')")
    else if($collection = 'manuscripts') then 
        concat("collection('",$global:data-root,"/manuscripts/tei')")
    else if(exists($collection)) then 
        concat("collection('",$global:data-root,xs:anyURI($collection),"')")
    else 
        concat("collection('",$global:data-root,"')")
};

(:
 : Limit browse to spceified collection. 
 : Uses seriesStmt/title
 : @param $collection param from URL or passed via html templates
:)
declare function browse:sub-collection-filter($collection){
let $c := if($browse:coll != '') then $browse:coll
          else if($collection = 'bibl') then ()
          else $collection
return          
    if($c != '') then
        concat("//tei:title[. = '",browse:parse-collections($collection),"']")    
    else '//tei:TEI'
};

(:~
 : Parse collection to match series name
 : @param $collection collection should match data subdirectory name or tei series name
:)
declare function browse:parse-collections($collection as xs:string?) {
    if($collection = ('persons','sbd')) then 'The Syriac Biographical Dictionary'
    else if($collection = ('saints','q')) then 'Qadishe: A Guide to the Syriac Saints'
    else if($collection = 'authors' ) then 'A Guide to Syriac Authors'
    else if($collection = 'bhse' ) then 'Bibliotheca Hagiographica Syriaca Electronica'
    else if($collection = 'nhsl' ) then 'New Handbook of Syriac Literature'
    else if($collection = ('places','The Syriac Gazetteer')) then 'The Syriac Gazetteer'
    else if($collection = ('spear','SPEAR: Syriac Persons, Events, and Relations')) then 'SPEAR: Syriac Persons, Events, and Relations'
    else if($collection != '' ) then $collection
    else ()
};

(:~
 : Make XPath language filter. 
 : @param $collection used to select browse element: persName/placeName/title
 : @param $browse:computed-lang 
:)
declare function browse:lang-filter($collection){    
    if($browse:computed-lang != '') then 
        concat("/descendant::",browse:lang-element($collection),"[@xml:lang = '", $browse:computed-lang, "']")
    else ()
};

(:~
 : Matches English letters and their equivalent letters as established by Syriaca.org
 : @param $browse:sort indicates letter for browse
 :)
declare function browse:get-sort(){
    if(exists($browse:sort) and $browse:sort != '') then
        if($browse:lang = 'ar') then
            browse:ar-sort()
        else
            if($browse:sort = 'A') then '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
            else if($browse:sort = 'D') then '(D|d|đ|Đ)'
            else if($browse:sort = 'S') then '(S|s|š|Š|ṣ|Ṣ)'
            else if($browse:sort = 'E') then '(E|e|ễ|Ễ)'
            else if($browse:sort = 'U') then '(U|u|ū|Ū)'
            else if($browse:sort = 'H') then '(H|h|ḥ|Ḥ)'
            else if($browse:sort = 'T') then '(T|t|ṭ|Ṭ)'
            else if($browse:sort = 'I') then '(I|i|ī|Ī)'
            else if($browse:sort = 'O') then '(O|Ō|o|Œ|œ)'
            else $browse:sort
    else '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
};

declare function browse:ar-sort(){
    if($browse:sort = 'ٱ') then '(ٱ|ا|آ|أ|إ)'
        else if($browse:sort = 'ٮ') then '(ٮ|ب)'
        else if($browse:sort = 'ة') then '(ة|ت)'
        else if($browse:sort = 'ڡ') then '(ڡ|ف)'
        else if($browse:sort = 'ٯ') then '(ٯ|ق)'
        else if($browse:sort = 'ں') then '(ں|ن)'
        else if($browse:sort = 'ھ') then '(ھ|ه)'
        else if($browse:sort = 'ۈ') then '(ۈ|ۇ|ٷ|ؤ|و)'
        else if($browse:sort = 'ى') then '(ى|ئ|ي)'
        else $browse:sort
};

(:~
 : Syriaca.org uses headwords for Syriac and English language browse
 : @param $browse:computed-lang 
:)
declare function browse:lang-headwords(){
    if($browse:computed-lang = ('en','syr')) then 
        "[@syriaca-tags='#syriaca-headword']"
    else ()    
};

(:~
  : Select correct tei element to base browse list on. 
  : Places use place/placeName
  : Persons use person/persName
  : All others use title
:)
declare function browse:lang-element($collection){
    if($collection = ('persons','sbd','saints','q','authors')) then
        "tei:person/tei:persName"
    else if($collection = ('places','geo')) then
        "tei:place/tei:placeName"
    else "tei:title"    
};

(:~
 : @depreciated - depreciating now...
 : Browse by date, persons only
 : Could also be handled by facets... 
:)
declare function browse:narrow-by-date(){
    if($browse:date != '') then 
        if($browse:date = 'BC dates') then 
            "[descendant::tei:body[descendant::*[(@syriaca-computed-start[starts-with(.,'-')] or @syriaca-computed-end[starts-with(.,'-')])]]]"
        else
        concat("[descendant::tei:body[descendant::*[(
                @syriaca-computed-start >= 
                    '",browse:get-start-date(),"' 
                    and @syriaca-computed-end <= 
                    '",browse:get-end-date(),"'
                    ) or (
                    @syriaca-computed-start >= 
                    '",browse:get-start-date(),"' 
                    and @syriaca-computed-start <= 
                    '",browse:get-end-date(),"' and 
                    not(exists(@syriaca-computed-end)))]]]") 
    else () 
};

(: Formats end dates queries for searching :)
declare function browse:get-end-date(){
let $date := substring-after($browse:date,'-')
return 
    if($date = '0-100') then '0001-01-01'
    else if($date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else '0100-01-01'
};

(: Formats end start queries for searching :)
declare function browse:get-start-date(){
let $date := substring-before($browse:date,'-')
return 
    if($date = '0-100') then '0001-01-01'
    else if($date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else '0100-01-01'
};

(:~
 : Browse by type, used for persons/places
:)
declare function browse:narrow-by-type($collection){
    if($browse:type != '') then 
        if($collection = ('persons','saints','authors')) then 
            if($browse:type != '') then 
                if($browse:type = 'unknown') then
                    "[tei:teiHeader[not(/descendant::tei:title[. = 'Qadishe: A Guide to the Syriac Saints']) and not(/descendant::tei:title[. = 'A Guide to Syriac Authors'])]]"
                else 
                    concat("[descendant::tei:title[@level='m'][. ='", browse:parse-collections($browse:type),"']]")
            else ()
        else   
            if($browse:type != '') then 
                 concat("[descendant::tei:place[contains(@type,'",$browse:type,"')]]")
            else ()
    else ()
};  
(:~
 : Add initial browse results function to be passed to display and refine functions
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
:)  
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string?){
let $hits-main := collection($global:data-root)//tei:TEI
(:util:eval(concat(browse:collection-path($collection),browse:sub-collection-filter($collection))):)
let $hits := 
    util:eval(concat("$hits-main",
    facet:facet-filter(facet-defs:facet-definition('')),browse:narrow-by-type($collection),browse:narrow-by-date(),browse:lang-filter($collection)))
let $data :=   
        if($browse:view = 'title')  then
            for $hit in $hits-main//tei:titleStmt/tei:title[starts-with(@ref, 'http://syriaca.org/')][1][matches(substring(global:build-sort-string(.,$browse:computed-lang),1,1),browse:get-sort(),'i')]
            let $num := if(xs:integer($hit/@n)) then xs:integer($hit/@n) else 0
            order by $hit/text()[1], $num
            return $hit/ancestor::tei:TEI 
        else if($browse:view = 'author' or empty(request:get-parameter-names())) then 
            for $hit in $hits-main//tei:titleStmt/tei:author[starts-with(@ref, 'http://syriaca.org/')][1][matches(substring(global:build-sort-string(.,$browse:computed-lang),1,1),browse:get-sort(),'i')]
            order by global:build-sort-string(page:add-sort-options($hit/text()[1],$browse:sort-element),'') 
            return
                <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
        else if($browse:computed-lang != '') then 
            for $hit in $hits[matches(substring(global:build-sort-string(.,$browse:computed-lang),1,1),browse:get-sort(),'i')]
            let $title := global:build-sort-string($hit,$browse:computed-lang)
            order by $title 
            return 
                <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
        else if($browse:view = 'numeric') then
            for $hit in $hits/ancestor::tei:TEI/descendant::tei:idno[starts-with(.,$global:base-uri)][1]
            let $rec-id := tokenize(replace($hit,'/tei|/source',''),'/')[last()]
            order by xs:integer($rec-id)
            return $hit/ancestor::tei:TEI
        else if($browse:view = 'all') then
            for $hit in $hits-main/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]
            order by global:build-sort-string(page:add-sort-options($hit,$browse:sort-element),'') 
            return $hit/ancestor::tei:TEI
        else if($browse:view = 'A-Z') then
                for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}','i')]
                where $hit[matches(substring(global:build-sort-string(.,$browse:computed-lang),1,1),browse:get-sort(),'i')]
                order by global:build-sort-string(page:add-sort-options($hit,$browse:sort-element),'')
                return $hit/ancestor::tei:TEI
        else if($browse:view = 'ܐ-ܬ') then
                for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsSyriac}','i')]
                order by global:build-sort-string(page:add-sort-options($hit,$browse:sort-element),'') 
                return $hit/ancestor::tei:TEI                            
        else if($browse:view = 'ا-ي') then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsArabic}','i')]
            order by  global:build-sort-string(page:add-sort-options($hit,$browse:sort-element),'ar') 
            return $hit/ancestor::tei:TEI 
        else if($browse:view = 'other') then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][not(matches(substring(global:build-sort-string(.,''),1,1),'\p{IsSyriac}|\p{IsArabic}|\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}|\p{IsLatinExtendedAdditional}','i'))]
            order by global:build-sort-string(page:add-sort-options($hit,$browse:sort-element),'') 
            return $hit/ancestor::tei:TEI
        else 
            for $hit in $hits
            let $title := global:build-sort-string($hit,$browse:computed-lang)
            order by $title 
            return 
                $hit/ancestor-or-self::tei:TEI           
return map{"browse-data" := $data } 
};

(:~
 : Display in html templates
:)
declare %templates:wrap function browse:pageination($node as node()*, $model as map(*), $collection as xs:string?, $sort-options as xs:string*){
   page:pages($model("browse-data"), $browse:start, $browse:perpage,'', $sort-options)
};

declare function browse:pages($hits, $collection as xs:string?, $sort-options as xs:string*){
 page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $collection passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
let $hits := $model("browse-data")
return
    if($browse:view = 'map') then 
        <div class="col-md-12 map-lg">{browse:get-map($hits)}</div>
    else if($browse:view = 'all' or $browse:view = 'ܐ-ܬ' or $browse:view = 'ا-ي' or $browse:view = 'other') then 
        <div class="col-md-12">
            <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
            <div>{browse:display-hits($hits)}</div>
        </div>
    else 
        <div class="col-md-12">
            {(
            if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else(),
            <div class="float-container">
                <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right"}">
                     <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                </div>
                {browse:browse-abc-menu()}
            </div>,
            <h3>{(
                if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then 
                    (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
                else attribute class {"label"},
                    if($browse:sort != '') then $browse:sort else 'A')}</h3>,
            <div class="{if($browse:lang = 'syr' or $browse:lang = 'ar') then 'syr-list' else 'en-list'}">
                <div class="row">
                    <div class="col-sm-12">
                    {if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else()}
                    {browse:display-hits($hits)}
                    </div>
                </div>
            </div>
            )}
        </div>
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $collection passed from html 
:)
declare function browse:display-persons-map($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
let $hits := $model("browse-data")
let $related := distinct-values(
                    tokenize(
                        string-join(($hits//tei:relation/@mutual,$hits//tei:relation/@passive,$hits//tei:relation/@active),' '),
                        ' '))
let $geo := for $r in $related[contains(.,'/place/')]
            return 
               collection($global:data-root)//tei:idno[@type='URI'][. = concat($r,'/tei')]/ancestor::tei:TEI[descendant::tei:geo]
return                
         maps:build-map($geo,'')

};

declare function browse:display-hits($hits){
    for $data in subsequence($hits, $browse:start,$browse:perpage)
    let $sort-title := if($data/@sort-title != '') then string($data/@sort-title) else () 
    let $uri :=  $data/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em" class="short-rec-result">
            {($sort-title, tei2html:summary-view($data, $browse:computed-lang, $uri)) }
        </div>
};

(: Display map :)
declare function browse:get-map($hits){
    if($hits/descendant::tei:body/tei:listPlace/descendant::tei:geo) then 
            maps:build-map($hits[descendant::tei:geo],count($hits))
    else if($hits/descendant::tei:body/tei:listPerson/tei:person) then 
        let $persons := 
            for $p in $hits//tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]
            let $name := string($p/ancestor::tei:TEI/descendant::tei:title[1])
            let $pers-id := string($p/ancestor::tei:TEI/descendant::tei:idno[1])
            let $relation := string($p/@name)
            let $places := for $p in tokenize(string-join(($p/@passive,$p/@active,$p/@mutual),' '),' ')[contains(.,'/place/')] return <placeName xmlns="http://www.tei-c.org/ns/1.0">{$p}</placeName>
            return 
                <person xmlns="http://www.tei-c.org/ns/1.0">
                    <persName xmlns="http://www.tei-c.org/ns/1.0" name="{$relation}" id="{replace($pers-id,'/tei','')}">{$name}</persName>
                        {$places}
                </person>
        let $places := distinct-values($persons/descendant::tei:placeName/text()) 
        let $locations := 
            for $id in $places
            for $geo in collection($global:data-root || '/places/tei')//tei:idno[. = $id][ancestor::tei:TEI[descendant::tei:geo]]
            let $title := $geo/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
            let $type := string($geo/ancestor::tei:TEI/descendant::tei:place/@type)
            let $geo := $geo/ancestor::tei:TEI/descendant::tei:geo
            return 
                <place xmlns="http://www.tei-c.org/ns/1.0">
                    <idno>{$id}</idno>
                    <title>{concat(normalize-space($title), ' - ', $type)}</title>
                    <desc>Related Persons:
                    {
                        for $p in $persons[child::tei:placeName[. = $id]]/tei:persName
                        return concat('<br/><a href="',string($p/@id),'">',normalize-space($p),'</a>')
                    }
                    </desc>
                    <location>{$geo}</location>  
                </place>
        return maps:build-map($locations,'')
    else ()
};

(:~
 : Browse Alphabetical Menus
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
        {
            if(($browse:lang = 'syr')) then  
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    <li class="syr-menu" lang="syr"><a href="?lang={$browse:lang}&amp;sort={$letter}">{$letter}</a></li>
            else if(($browse:lang = 'ar')) then  
                for $letter in tokenize('ا ب ت ث ج ح  خ  د  ذ  ر  ز  س  ش  ص  ض  ط  ظ  ع  غ  ف  ق  ك ل م ن ه  و ي', ' ')
                return 
                    <li class="ar-menu" lang="ar"><a href="?lang={$browse:lang}&amp;sort={$letter}">{$letter}</a></li>
            else if($browse:lang = 'ru') then 
                for $letter in tokenize('А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я',' ')
                return 
                <li><a href="?lang={$browse:lang}&amp;sort={$letter}">{$letter}</a></li>
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    <li><a href="?lang={$browse:lang}&amp;sort={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else '&amp;view=author'}">{$letter}</a></li>
        }
        </ul>
    </div>
};
(:~
 : Browse Type Menus
:)
declare function browse:browse-type($collection){  
    <ul class="nav nav-tabs nav-stacked">
        {
            if($collection = ('places','geo')) then 
                    for $types in collection($global:data-root || '/places/tei')//tei:place
                    group by $place-types := $types/@type
                    order by $place-types ascending
                    return
                        <li> {if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                            </a> 
                        </li>
            else      
                   let $persons := collection($global:data-root || '/persons/tei')//tei:person
                   let $unknown := count($persons[ancestor::tei:TEI[not(descendant::tei:title[@level='m'] = 'A Guide to Syriac Authors') and not(descendant::tei:title[@level='m'] = 'Qadishe: A Guide to the Syriac Saints')]])
                   let $author := count($persons[ancestor::tei:TEI/descendant::tei:title[@level='m'][. = 'A Guide to Syriac Authors']])
                   let $saint := count($persons[ancestor::tei:TEI/descendant::tei:title[@level='m'][. = 'Qadishe: A Guide to the Syriac Saints']])
                   return 
                         (<li>{if($browse:type = 'authors') then attribute class {'active'} else '' }
                             <a href="?view=type&amp;type=authors">
                                Authors <span class="count"> ({$author})</span>
                             </a>
                         </li>,
                        <li>{if($browse:type = 'saints') then attribute class {'active'} else '' }
                             <a href="?view=type&amp;type=saints">
                                Saints <span class="count"> ({$saint})</span>
                             </a>
                         </li>
                         (:,
                         <li>{if($browse:type = 'unknown') then attribute class {'active'} else '' }
                             <a href="?view=type&amp;type=unknown">
                                Unknown <span class="count"> ({$unknown})</span>
                             </a>
                         </li>:))
        }
    </ul>

};

(:
 : Build Tabs dynamically.
 : @param $text tab text, from template
 : @param $param tab parameter passed to url from template
 : @param $value value of tab parameter passed to url from template
 : @param $alpha-filter-value for abc menus. 
 : @param $default indicates initial active tab
:)
declare function browse:tabs($node as node(), $model as map(*), $text as xs:string?, $param as xs:string?, $value as xs:string?, $alpha-filter-value as xs:string?, $element as xs:string?, $default as xs:string?){ 
let $s := if($alpha-filter-value != '') then $alpha-filter-value else if($browse:alpha-filter != '') then $browse:alpha-filter else 'A'
return
    <li xmlns="http://www.w3.org/1999/xhtml">{
        if($default = 'true' and empty(request:get-parameter-names())) then  attribute class {'active'} 
        else if($value = $browse:view) then attribute class {'active'}
        else if($value = $browse:lang) then attribute class {'active'}
        (:else if($value = 'English' and empty(request:get-parameter-names())) then attribute class {'active'}:)
        else ()
        }
        <a href="browse.html?{$param}={$value}{if($param = 'lang') then concat('&amp;alpha-filter=',$s) else ()}{if($element != '') then concat('&amp;element=',$element) else()}">
        {if($value = 'syr' or $value = 'ar') then (attribute lang {$value},attribute dir {'ltr'}) else ()}
        {$text}
        </a>
    </li> 
};
