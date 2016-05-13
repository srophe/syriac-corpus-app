xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Browse by type
 :
 : @see lib/geojson.xqm for map generation
 :)

module namespace browse="http://syriaca.org/browse";
import module namespace bs="http://syriaca.org/bs" at "browse-spear.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace common="http://syriaca.org/common" at "search/common.xqm";
import module namespace facets="http://syriaca.org/facets" at "lib/facets.xqm";
import module namespace ev="http://syriaca.org/events" at "lib/events.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace rec="http://syriaca.org/short-rec-view" at "short-rec-view.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse.html 
 : @param $browse:type selects doc type filter eg: place@type person@ana
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')};
declare variable $browse:lang {request:get-parameter('lang', '')};
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:fq {request:get-parameter('fq', '')};
declare variable $browse:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $browse:perpage {request:get-parameter('perpage', 25) cast as xs:integer};

(:~
 : Build browse path for evaluation 
 : Uses $collection to build path to appropriate data set 
 : If no $collection parameter is present data and all subdirectories will be searched.
 : @param $collection collection name passed from html, should match data subdirectory name
:)
declare function browse:build-path($collection as xs:string?){
    if($collection = ('persons','sbd','saints','q','authors')) then concat("collection('",$global:data-root,"/persons/tei')",browse:get-coll($collection),browse:lang($collection))
    else if($collection = 'places') then concat("collection('",$global:data-root,"/places/tei')",browse:get-coll($collection),browse:lang($collection))
    else if($collection = 'bhse') then concat("collection('",$global:data-root,"/works/tei')",browse:get-coll($collection),browse:lang($collection))
    else if($collection = 'bibl') then concat("collection('",$global:data-root,"/bibl/tei')",browse:lang($collection))
    else if($collection = 'spear') then concat("collection('",$global:data-root,"/spear/tei')",browse:lang($collection))
    else if($collection = 'manuscripts') then concat("collection('",$global:data-root,"/manuscripts/tei')//tei:TEI")
    else if(exists($collection)) then concat("collection('",$global:data-root,xs:anyURI($collection),"')",browse:get-coll($collection),browse:lang($collection))
    else concat("collection('",$global:data-root,"')",browse:get-coll($collection),browse:lang($collection))
};

(:~
 : Add initial browse results to map function to be passed to display and refine functions
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
:)
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string?){
    map{"browse-data" := util:eval(browse:build-path($collection))}      
};

(:~
 : Parse collection to match series name
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
:)
declare function browse:parse-collections($collection as xs:string?) {
    if($collection = ('persons','sbd')) then 'The Syriac Biographical Dictionary'
    else if($collection = ('saints','q')) then 'Qadishe: A Guide to the Syriac Saints'
    else if($collection = 'authors' ) then 'A Guide to Syriac Authors'
    else if($collection = 'bhse' ) then 'Bibliotheca Hagiographica Syriaca Electronica'
    else if($collection = ('places','The Syriac Gazetteer')) then 'The Syriac Gazetteer'
    else if($collection = ('spear','SPEAR: Syriac Persons, Events, and Relations')) then 'SPEAR: Syriac Persons, Events, and Relations'
    else if($collection != '' ) then $collection
    else ()
};

(:~
 : Filter titles by subcollection
 : Used by persons as there are several subcollections within SBD
 : @param $collection passed from html template
:)
declare function browse:get-coll($collection) as xs:string?{
if(not(empty($collection))) then
    concat("//tei:title[. = '",browse:parse-collections($collection),"']/ancestor::tei:TEI")    
else '//tei:TEI'    
};

(:~
 : Get record by language
 : Matches on alt persNames, placeNames or titles that are direct children of the main content. 
 : (Selects first occurence of specified element/@xml:lang)
 : @param $lang 
:)
declare function browse:lang($collection as xs:string?) as xs:string?{
    if($browse:lang != '') then
        if($collection = ('persons','sbd','saints','q','authors')) then 
            concat("[descendant::tei:person/tei:persName[@xml:lang = '",$browse:lang,"']]")
        else if($collection = 'places') then 
            concat("[descendant::tei:place/tei:placeName[@xml:lang = '",$browse:lang,"']]")
        else 
            concat("[descendant::tei:title[@xml:lang = '",$browse:lang,"']]")
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
 : Strips english titles of non-sort characters as established by Syriaca.org
 : @param $titlestring 
 :)
declare function browse:build-sort-string($titlestring as xs:string?) as xs:string* {
    if($browse:lang = 'ar') then browse:ar-sort-string($titlestring)
    else replace(replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]',''),'On ','')
};

(:~
 : Strips Arabic titles of non-sort characters as established by Syriaca.org
 : @param $titlestring 
 :)
declare function browse:ar-sort-string($titlestring as xs:string?) as xs:string* {
    replace(replace(replace(replace($titlestring,'^\s+',''),'^(\sابن|\sإبن|\sبن)',''),'(ال|أل|ٱل)',''),'^[U064B - U0656]','')
};

(:~
 : Sort on Titles/Headwords
:)
declare function browse:lang-filter($node as node(), $model as map(*)){
    if($browse:lang != '' and $browse:lang != 'en') then 
       $model("browse-data")//tei:body/child::*[1]/child::*[1][child::*[@xml:lang = $browse:lang][1][matches(substring(browse:build-sort-string(string-join(descendant-or-self::*/text(),' ')),1,1),browse:get-sort(),'i')]]
    else $model("browse-data")//tei:title[@level='a'][parent::tei:titleStmt][matches(substring(browse:build-sort-string(string-join(text(),' ')),1,1),browse:get-sort(),'i')]        
};

(: 
 : @deprecated use parse-collections()
 NOTE, parse-collections alread does this, just pass in $browse:type:)
declare function browse:browse-pers-types(){
    if($browse:type = 'saint') then 'Qadishe: A Guide to the Syriac Saints'
    else if($browse:type = ('author')) then 'A Guide to Syriac Authors'
    else ()
};

(: Formats end dates queries for searching :)
declare function browse:get-end-date(){
let $date := substring-after($browse:date,'-')
return
    if($browse:date = '0-100') then '0001-01-01'
    else if($browse:date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else '0100-01-01'
};

(: Formats end start queries for searching :)
declare function browse:get-start-date(){
let $date := substring-before($browse:date,'-')
return 
    if(matches($date,'0')) then '0001-01-01'
    else if($browse:date = '2000-') then '2000-01-01'
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else '0001-01-01'
};

declare function browse:narrow-by-type($node as node(), $model as map(*), $collection){
    if($browse:type != '') then 
        if($collection = ('persons','saints','authors')) then
            if($browse:type != '') then 
                if($browse:type = 'unknown') then $model("browse-data")//tei:person[not(ancestor::tei:TEI/descendant::tei:title[@level='m'][. = ('A Guide to Syriac Authors','Qadishe: A Guide to the Syriac Saints')])]
                    else $model("browse-data")//tei:person[ancestor::tei:TEI/descendant::tei:title[@level='m'][. = browse:browse-pers-types()]]
                else ()
            else   
                if($browse:type != '') then 
                    $model("browse-data")//tei:place[contains(@type,$browse:type)]
                else $model("browse-data")
    else () 
};

declare function browse:narrow-by-date($node as node(), $model as map(*)){
    if($browse:date != '') then 
        if($browse:date = 'BC dates') then 
            $model("browse-data")/self::*[starts-with(descendant::*/@syriaca-computed-start,"-") or starts-with(descendant::*/@syriaca-computed-end,"-")]
        else
            $model("browse-data")//tei:body[descendant::*[@syriaca-computed-start lt browse:get-end-date() and @syriaca-computed-start gt  browse:get-start-date()]] 
            | $model("browse-data")//tei:body[descendant::*[@syriaca-computed-end gt browse:get-start-date() and @syriaca-computed-start lt browse:get-end-date()]]
    else () 
};

(:~
 : Evaluates additional browse parameters; type, date, abc, etc. 
 : Adds narrowed data set to new map
:)
declare function browse:get-narrow($node as node(), $model as map(*),$collection as xs:string*){
let $data := 
        if($collection = 'spear') then bs:narrow-spear($node,$model)
        else if($browse:view='numeric') then $model("browse-data")
        else if($browse:view = 'type') then browse:narrow-by-type($node, $model, $collection)   
        else if($browse:view = 'date') then browse:narrow-by-date($node, $model)
        else if($browse:view = 'map') then $model("browse-data")
        else browse:lang-filter($node, $model)
return
    map{"browse-refine" := $data}
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $collection passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*), $collection){
if($collection = 'spear') then bs:spear-results-panel($node, $model)
else if($browse:view = 'type' or $browse:view = 'date') then
    (<div class="col-md-4">{if($browse:view='type') then browse:browse-type($node,$model,$collection)  else browse:browse-date()}</div>,
     <div class="col-md-8">{
        if($browse:view='type') then
            if($browse:type != '') then 
                (<h3>{concat(upper-case(substring($browse:type,1,1)),substring($browse:type,2))}</h3>,
                 <div>{browse:get-data($node,$model,$collection)}</div>)
            else <h3>Select Type</h3>    
        else if($browse:view='date') then 
            if($browse:date !='') then 
                (<h3>{$browse:date}</h3>,
                 <div>{browse:get-data($node,$model,$collection)}</div>)
            else <h3>Select Date</h3>  
        else ()}</div>)
else if($browse:view = 'map') then browse:get-map($node, $model)
else 
    <div class="col-md-12">
        { (
        if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else(),
        browse:browse-abc-menu(),
        <h3>{(
            if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then 
                (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
            else attribute class {"label"},
                if($browse:sort != '') then $browse:sort else 'A')}</h3>,
        <div class="{if($browse:lang = 'syr' or $browse:lang = 'ar') then 'syr-list' else 'en-list'}">
            {browse:get-data($node,$model,$collection)}
        </div>
        )
        }
    </div>
};

declare function browse:get-map($node as node(), $model as map(*)){
    <div class="col-md-12 map-lg">
        {geo:build-map($model("browse-data")//tei:geo, '', '')}
    </div>
};

declare function browse:parse-persName($persName){
if($persName/child::*) then 
    string-join(for $namePart in $persName/child::*
    order by $namePart/@sort
    return $namePart/text(),' ')
else $persName/text()
};
(:
 : Sorts and outputs results set
 : @param $coll from html template
:)
declare function browse:get-data($node as node(), $model as map(*), $collection as xs:string*) as node()*{
(
if($browse:view = 'map' or $browse:view = 'type') then
        if($model("browse-refine")//tei:geo) then
            <div class="map-sm inline-map well">{geo:build-map($model("browse-refine")//tei:geo, '', '')}</div>
        else ()        
else (),
for $data in $model("browse-refine")
let $rec-id := tokenize(replace($data/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei|/source',''),'/')[last()]
let $title := if($browse:lang != '' and $browse:lang != 'en') then 
                     if($collection = ('persons','sbd','saints','q','authors')) then 
                        browse:parse-persName($data/ancestor::tei:TEI/descendant::tei:person/tei:persName[@xml:lang = $browse:lang][1])
                     else if($collection = 'places') then 
                        string-join($data/ancestor::tei:TEI/descendant::tei:place/tei:placeName[@xml:lang = $browse:lang][1]/text(),' ')
                     else 
                        string-join($data/ancestor::tei:TEI/descendant::tei:body/child::tei:title[@xml:lang = $browse:lang][1]/text(),' ')
              else
                if($data/self::tei:title) then string-join($data/text(),' ')
                else if($data/self::tei:div) then string-join($data/text(),' ')
                else string-join($data/ancestor::tei:TEI/descendant::tei:title[1]/text(),' ')               
let $browse-title := browse:build-sort-string($title)
order by 
    if($browse:view = 'numeric') then xs:integer($rec-id) 
    else 
        $browse-title collation "?lang=en&lt;syr&amp;decomposition=full"   
return 
    if($collection = "manuscripts") then 
        let $title := $data/descendant::tei:titleStmt/tei:title[1]/text()
        let $id := $data/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][2]/text()
        return 
            <div>
                <a href="manuscript.html?id={$id}">{$title}</a>
            </div>
    else 
        if($collection = 'spear') then $data (:rec:display-recs-short-view($data,''):) 
        else if($browse:view = 'syr') then 
            rec:display-recs-short-view($data,'syr') 
        else rec:display-recs-short-view($data/ancestor::tei:TEI, $browse:lang)      
) 
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
                    <li><a href="?lang={$browse:lang}&amp;sort={$letter}">{$letter}</a></li>
        }
        </ul>
    </div>
};

declare function browse:browse-type($node as node(), $model as map(*), $collection){  
    <ul class="nav nav-tabs nav-stacked">
        {
            if($collection = ('places','geo')) then 
                for $types in $model("browse-data")//tei:place
                    group by $place-types := $types/@type
                    order by $place-types ascending
                    return
                        <li> {if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                            </a> 
                        </li>
            else             
                 for $types in $model("browse-data")//tei:person
                 group by $pers-types := $types/@ana
                 order by $pers-types ascending
                 return
                     let $pers-types-labels := if($pers-types) then replace(string($pers-types),'#syriaca-','') else 'unknown'
                     return
                         <li>{if($browse:type = $pers-types-labels) then attribute class {'active'} else '' }
                             <a href="?view=type&amp;type={$pers-types-labels}">
                             {if(string($pers-types) = '') then 'unknown' else replace(string($pers-types),'#syriaca-','')}  <span class="count"> ({count($types)})</span>
                             </a>
                         </li>
        }
    </ul>

};

(:
 : Browse by date
 : Precomputed values
 : NOTE: would be nice to use facets, however, it is currently inefficient 
:)
declare function browse:browse-date(){
    <ul class="nav nav-tabs nav-stacked pull-left type-nav">
        {   
            let $all-dates := 'BC dates, 0-100, 100-200, 200-300, 300-400, 400-500, 500-600, 700-800, 800-900, 900-1000, 1100-1200, 1200-1300, 1300-1400, 1400-1500, 1500-1600, 1600-1700, 1700-1800, 1800-1900, 1900-2000, 2000-'
            for $date in tokenize($all-dates,', ')
            return
                    <li>{if($browse:date = $date) then attribute class {'active'} else '' }
                        <a href="?view=date&amp;date={$date}">
                            {$date}  <!--<span class="count"> ({count($types)})</span>-->
                        </a>
                    </li>
            }
    </ul>
};

(:
 : Build Language Tabs dynamically.
 : @param $value from template
 : @param $language from template
 : @param $sort-letter from template
:)
declare %templates:wrap function browse:tabs($node as node(), $model as map(*), $value as xs:string?, $language as xs:string?, $sort-letter as xs:string?){
let $s := if($sort-letter != '') then $sort-letter else 'A'
return
    <li>{
        if($language = $browse:lang) then attribute class {'active'}
        else if($browse:lang = '' and $browse:view = '' and $language = 'en') then attribute class {'active'}
        else ()
        }
        <a href="browse.html?lang={$language}&amp;sort={$sort-letter}">
        {if($language = 'syr' or $language = 'ar') then (attribute lang {$language},attribute dir {'ltr'}) else ()}
        {$value}</a>
    </li> 
};
(:~
 : @depreciated
 : Browse Tabs - Eng
 : Choose which functions to include with each browse. 
 : Note: should this be done with javascript? possibly. 
:)
declare  %templates:wrap function browse:build-tabs-en($node, $model){
    <li>{if(not($browse:view) and not($browse:lang)) then attribute class {'active'} 
         else if($browse:lang = 'en') then attribute class {'active'} 
         else '' }
         <a href="browse.html?lang=en&amp;sort=A">English</a>
    </li>   
};

(:~
 : Browse Tabs - Syr
:)
declare  %templates:wrap function browse:build-tabs-syr($node, $model){
    <li>{if($browse:view = 'syr') then attribute class {'active'} 
         else '' }<a href="browse.html?lang=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
    </li>   
};

(:~
 : Browse Tabs - Transliteration
:)
declare  %templates:wrap function browse:build-tabs-transliteration($node, $model){
    <li>{if($browse:lang = 'en-x-gedsh') then attribute class {'active'} 
         else '' }<a href="browse.html?lang=en-x-gedsh&amp;sort=A">Transliteration</a>
    </li>   
};

(:~
 : Browse Tabs - Type  
:)
declare  %templates:wrap function browse:build-tabs-type($node, $model){
    <li>{if($browse:view = 'type') then attribute class {'active'}
         else '' }<a href="browse.html?view=type">Type</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-date($node, $model){
    <li>{if($browse:view = 'date') then attribute class {'active'} 
         else '' }<a href="browse.html?view=date">Date</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-map($node, $model){
    <li>{if($browse:view = 'map') then attribute class {'active'} 
         else '' }<a href="browse.html?view=map">Map</a>
    </li>
};

(:~
 : Browse Tabs - SPEAR
:)
declare  %templates:wrap function browse:build-tabs-spear($node, $model){    
    bs:build-tabs-spear($node, $model)
};
