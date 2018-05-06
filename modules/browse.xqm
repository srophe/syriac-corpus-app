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
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
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
 : Add initial browse results function to be passed to display and refine functions
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
:)  
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string*, $element as xs:string?){
    let $hits := 
        if($browse:view = 'title') then
            data:get-browse-data($collection, 'tei:titleStmt/tei:title[@level="s"][@ref]')
        else if($browse:lang = 'syr') then 
            data:get-browse-data($collection, 'tei:titleStmt/tei:title[@level="s"][@ref]/tei:foreign')
        else data:get-browse-data($collection, "tei:titleStmt/tei:author[1]")
    return map{"browse-data" := $hits }    
};

declare function browse:group-results($node as node(), $model as map(*), $collection as xs:string?){
    let $hits := $model("browse-data")
    let $groups := distinct-values($hits//tei:author)
    return 
        map {"group-by-authors" :=            
            for $rec in $hits 
            let $author := $rec/descendant::tei:author
            group by $facet-grp-p := $author[1]
            order by $facet-grp-p
            return  
                if($author != '') then 
                    <div xmlns="http://www.w3.org/1999/xhtml" style="margin:.71em 0; border-bottom:1px dotted #eee; padding:.25em 0;" class="short-rec-result">
                            <a class="togglelink text-info" 
                            data-toggle="collapse" data-target="#show{replace($facet-grp-p,'\s|,|\.','')}" 
                            href="#show{replace($facet-grp-p,'\s|,|\.','')}" data-text-swap=" - "> + </a>&#160; 
                            <span class="browse-author-name">{$facet-grp-p}</span> ({count($rec)} works)
                            <div class="indent collapse" style="background-color:#F7F7F9;" id="show{replace($facet-grp-p,'\s|,|\.','')}">{
                                for $r in $rec
                                let $id := replace($r/descendant::tei:idno[1],'/tei','')
                                let $sort := if($r/descendant::tei:titleStmt/tei:title[1]/@n) then xs:integer($r/descendant::tei:titleStmt/tei:title[1]/@n) else 0                                
                                order by $sort, global:build-sort-string($r/descendant::tei:titleStmt/tei:title[1],'')
                                return 
                                    <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view(root($r), '', $id)}</div>
                            }</div>
                    </div>
                else if($author = '' or not($author)) then
                    for $r in $rec
                    let $id := replace($r/descendant::tei:idno[1],'/tei','')
                    return
                        if($groups[. = $id]) then () 
                        else 
                            <div class="col-md-11" style="margin-right:-1em; padding-top:.5em;">
                                 {tei2html:summary-view(root($r), '', $id)}
                            </div>
                else ()
        } 
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
 : Display facets from HTML page 
 : @param $collection passed from html 
 : @param $facet relative (from collection root) path to facet definition 
:)
declare function browse:display-facets($node as node(), $model as map(*), $collection as xs:string?, $facets as xs:string?){
let $hits := $model("browse-data")
let $facet-config := doc(concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/',$facets))
return 
    if($facet-config) then 
        facet:html-list-facets-as-buttons(facet:count($hits, $facet-config/descendant::facet:facet-definition))
    else if(exists(facet-defs:facet-definition($collection))) then 
        facet:html-list-facets-as-buttons(facet:count($hits, facet-defs:facet-definition($collection)/child::*))
    else ()               
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $collection passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
   if($browse:view = 'map') then 
        let $hits := $model("browse-data")
        return 
            <div class="col-md-12 map-lg">{browse:get-map($hits)}</div>
   else if($browse:view = 'title' or  $browse:lang = 'syr') then
       let $hits := $model("browse-data")
       let $facet-config := facet:facet-definition((),())/child::*
       return
            if($browse:view = 'all' or $browse:view = 'ܐ-ܬ' or $browse:view = 'ا-ي' or $browse:view = 'other') then 
                <div class="col-md-12">
                    <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                    <div>{browse:display-hits($hits)}</div>
                </div>
            else 
                <div>{
                        <div class="float-container">
                            {if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else()}
                            <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right"}">
                                 <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                            </div>
                            {browse:browse-abc-menu()}
                        </div>}
                    <div class="row">
                        {if($facet-config != '') then
                            <div class="col-md-4">{facet:html-list-facets-as-buttons(facet:count($hits, $facet-config))}</div>    
                        else ()}
                        <div  class="{if($facet-config != '') then 'col-md-8' else 'col-md-12'}">
                           <h3>{(
                            if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then 
                                (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
                            else attribute class {"label"},
                                if($browse:alpha-filter != '') then $browse:alpha-filter else 'ALL')}</h3>    
                            <div class="{if($browse:lang = 'syr' or $browse:lang = 'ar') then 'syr-list' else 'en-list'}">
                                {browse:display-hits($hits)}
                            </div>
                        </div>
                    </div>
                </div>
   else 
    let $hits := $model("group-by-authors")
    return
        <div>
            {(
                if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else(),
                    <div class="float-container">
                         <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right"}">
                             <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                         </div>{browse:browse-abc-menu()}
                    </div>,
                    <div class="row">
                    <div class="col-md-1 text-center"><h3 class="label">{(if($browse:alpha-filter != '') then $browse:alpha-filter else 'ALL')}</h3></div>
                    <div class="col-md-11" style="margin-top:1em;">
                        {                 
                         for $hit at $p in subsequence($hits, $browse:start,$browse:perpage)
                         return $hit 
                         }
                    </div>
                    </div>
                 )}
        </div>
};

declare function browse:display-hits($hits){
    for $data in subsequence($hits, $browse:start,$browse:perpage)
    let $sort-title := if($data/@sort-title != '') then string($data/@sort-title) else () 
    let $uri :=  $data/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em" class="short-rec-result">
            {($sort-title, tei2html:summary-view($data, (), $uri)) }
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
                for $letter in tokenize('ALL ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    <li class="syr-menu" lang="{if($letter = 'ALL') then 'en' else 'syr'}"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}">{$letter}</a></li>
            else if(($browse:lang = 'ar')) then  
                for $letter in tokenize('ALL ا ب ت ث ج ح  خ  د  ذ  ر  ز  س  ش  ص  ض  ط  ظ  ع  غ  ف  ق  ك ل م ن ه  و ي', ' ')
                return 
                    <li class="ar-menu" lang="{if($letter = 'ALL') then 'en' else 'ar'}"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}">{$letter}</a></li>
            else if($browse:lang = 'ru') then 
                for $letter in tokenize('А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я',' ')
                return 
                <li><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}">{$letter}</a></li>
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ALL', ' ')
                return
                    <li><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else '&amp;view=author'}">{$letter}</a></li>
        }
        </ul>
    </div>
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
        if($default = 'true' and $browse:view = '' and $browse:lang = '') then  attribute class {'active'} 
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

(: Syrica Corpus Specific functions :)
(:~
 : Browse by Author
:)
declare function browse:group-by-authors($hits){
    for $records in $hits
    let $author := $records/descendant::tei:titleStmt/tei:author[starts-with(@ref, 'http://syriaca.org/')]
    group by $facet-grp := $author
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em" class="short-rec-result">
            <label>{$facet-grp} {count($author)}</label>
        </div>
};