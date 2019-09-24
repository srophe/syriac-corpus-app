xquery version "3.1";
(:~  
 : Builds HTML browse pages for Srophe Collections and sub-collections 
 : Alphabetical English and Syriac Browse lists, browse by type, browse by date, map browse. 
 :)
module namespace browse="http://syriaca.org/srophe/browse";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import Srophe application modules. :)
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "global.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "data.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";
import module namespace maps="http://syriaca.org/srophe/maps" at "maps.xqm";
import module namespace page="http://syriaca.org/srophe/page" at "paging.xqm";

(: Namespaces :)
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(: Global Variables :)
declare variable $browse:alpha-filter {for $r in request:get-parameter('alpha-filter', '')[1] return $r};
declare variable $browse:lang {for $r in request:get-parameter('lang', '')[1] return $r};
declare variable $browse:view {for $r in request:get-parameter('view', '')[1] return $r};
declare variable $browse:start {for $r in request:get-parameter('start', 1)[1] return $r cast as xs:integer};
declare variable $browse:perpage {for $r in request:get-parameter('perpage', 10)[1] return $r cast as xs:integer};

(:~
 : Build initial browse results based on parameters
 : Calls data function data:get-records(collection as xs:string*, $element as xs:string?)
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
 : @param $element element used to filter browse results, passed from html
 : @param $facets facet xml file name, relative to collection directory
:)  
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string*, $element as xs:string?, $facets as xs:string?){
    let $hits := 
        if($browse:view = 'title') then
            data:get-records($collection, 'tei:titleStmt/tei:title[1]')
        else if($browse:lang = 'syr') then 
            data:get-records($collection, 'tei:titleStmt/tei:title[1]/tei:foreign')
        else data:get-records($collection, "tei:titleStmt/tei:author[1]")
    return map{"hits" := $hits }   
};

(:
 : Main HTML display of browse results
 : @param $collection passed from html 
:)
declare function browse:show-hits($node as node(), $model as map(*), $collection, $sort-options as xs:string*, $facets as xs:string?){
  if($browse:view = 'map') then 
        let $hits := $model("hits")
        return 
            <div class="col-md-12 map-lg">{browse:get-map($hits)}</div>
   else if($browse:view = 'title' or  $browse:lang = 'syr') then
       let $hits := $model("hits")
       let $facet-config := global:facet-definition-file($collection)
       return
            if($browse:view = 'all' or $browse:view = 'ܐ-ܬ' or $browse:view = 'ا-ي' or $browse:view = 'other') then 
                <div class="col-md-12">
                    <div>{page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options)}</div>
                    <div>{browse:display-hits($hits)}</div>
                </div>
            else 
                <div class="col-md-12">
                    <div class="container">
                        <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right"}">
                            <div>{page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options)}</div>
                        </div>
                        <span>{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else()}
                            {browse:browse-abc-menu()}
                        </span>
                    </div>
                    <div class="row">
                        {if(not(empty($facet-config))) then 
                           <div class="col-md-4">{facet:html-list-facets-as-buttons(facet:count($hits, $facet-config/descendant::facet:facet-definition))}</div>
                         else ()}
                        <div class="{if($facet-config != '') then 'col-md-8' else 'col-md-12'}">
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
    let $authors := $model("group-by-authors")
    let $hits := $model("hits")
    return
        <div>
            {(
                if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else(),
                    <div class="float-container">
                         <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right"}">
                             <div>{page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options)}</div>
                         </div>{browse:browse-abc-menu()}
                    </div>,
                    <div class="row">
                    <div class="col-md-1 text-center"><h3 class="label">{(if($browse:alpha-filter != '') then $browse:alpha-filter else 'ALL')}</h3></div>
                    <div class="col-md-11" style="margin-top:1em;">
                        {                 
                         for $author at $p in subsequence($authors, $browse:start,$browse:perpage)
                         let $name := string($author/@name)
                         let $works := $hits[descendant::tei:titleStmt//tei:author = $name]
                         let $count-works := count($works)
                         where $count-works gt 0
                         return 
                            if(request:get-parameter('author-exact', '')) then
                                <div xmlns="http://www.w3.org/1999/xhtml" style="margin:.71em 0; border-bottom:1px dotted #eee; padding:.25em 0;" class="short-rec-result">
                                    <a class="togglelink text-info"  
                                    data-toggle="collapse" data-target="#show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}" 
                                    href="#show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}" data-text-swap=" - "> + </a>&#160; 
                                    <span class="browse-author-name">{string($name)}</span> ({$count-works} works)
                                    <div class="indent collapse in" style="background-color:#F7F7F9;" id="show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}">{
                                         for $r in $works
                                         let $id := replace($r/descendant::tei:idno[1],'/tei','')
                                         return 
                                            <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view($r, '', $id)}</div>
                                    }</div>
                                </div>
                            else 
                            <div xmlns="http://www.w3.org/1999/xhtml" style="margin:.71em 0; border-bottom:1px dotted #eee; padding:.25em 0;" class="short-rec-result">
                                <a class="togglelink text-info"  
                                data-toggle="collapse" data-target="#show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}" 
                                href="#show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}" data-text-swap=" - "> + </a>&#160; 
                                <span class="browse-author-name">{string($name)}</span> ({$count-works} works)
                                <div class="indent collapse" style="background-color:#F7F7F9;" id="show{replace($name,'\s|,|\.|\[|\]|\(|\)|\-|\?','')}">{
                                    (for $r in subsequence($works, 1,5)
                                    let $id := replace($r/descendant::tei:idno[1],'/tei','')
                                    return 
                                        <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view($r, '', $id)}</div>,
                                    if($count-works gt 20) then
                                        <div class="indent"><a href="browse.html?author-exact={string($name)}">Show all works</a></div>
                                    else ()
                                        )
                                }</div>
                            </div>
                         }
                    </div>
                    </div>
                 )}
        </div>
};

(:
 : Page through browse results
:)
declare function browse:display-hits($hits){
    for $hit in subsequence($hits, $browse:start,$browse:perpage)
    let $sort-title := 
        if($browse:lang = '' and $browse:view = 'title') then () 
        else if($hit/@sort-title != '') then 
            <span lang="{$browse:lang}">{string($hit/@sort-title)}</span> 
        else ()  
    let $uri := replace($hit/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" class="result">
            {($sort-title, tei2html:summary-view($hit, $browse:lang, $uri))}
        </div>
};

(:
 : Display map from HTML page 
 : For place records map coordinates
 : For other records, check for place relationships
 : @param $collection passed from html 
:)
declare function browse:display-map($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
let $hits := $model("browse-data")
return browse:get-map($hits)                    
};

(:~ 
 : Display maps for data with coordinates in tei:geo
 :)
declare function browse:get-map($hits as node()*){
    if($hits/descendant::tei:body/tei:listPlace/descendant::tei:geo) then 
            maps:build-map($hits[descendant::tei:geo], count($hits))
    else if($hits//tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]) then
        let $related := 
                for $r in $hits//tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]
                let $title := string($r/ancestor::tei:TEI/descendant::tei:title[1])
                let $rid := string($r/ancestor::tei:TEI/descendant::tei:idno[1])
                let $relation := string($r/@name)
                let $places := for $p in tokenize(string-join(($r/@passive,$r/@active,$r/@mutual),' '),' ')[contains(.,'/place/')] return <placeName xmlns="http://www.tei-c.org/ns/1.0">{$p}</placeName>
                return 
                    <record xmlns="http://www.tei-c.org/ns/1.0">
                        <title xmlns="http://www.tei-c.org/ns/1.0" name="{$relation}" id="{replace($rid,'/tei','')}">{$title}</title>
                            {$places}
                    </record>
        let $places := distinct-values($related/descendant::tei:placeName/text()) 
        let $locations := 
            for $id in $places
            for $geo in collection($config:data-root || '/places/tei')//tei:idno[. = $id][ancestor::tei:TEI[descendant::tei:geo]]
            let $title := $geo/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
            let $type := string($geo/ancestor::tei:TEI/descendant::tei:place/@type)
            let $geo := $geo/ancestor::tei:TEI/descendant::tei:geo
            return 
                <place xmlns="http://www.tei-c.org/ns/1.0">
                    <idno>{$id}</idno>
                    <title>{concat(normalize-space($title), ' - ', $type)}</title>
                    <desc>Related:
                    {
                        for $p in $related[child::tei:placeName[. = $id]]/tei:title
                        return concat('<br/><a href="',string($p/@id),'">',normalize-space($p),'</a>')
                    }
                    </desc>
                    <location>{$geo}</location>  
                </place>
        return 
            if(not(empty($locations))) then 
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">Related places</h3>
                    </div>
                    <div class="panel-body">
                        {maps:build-map($locations,count($places))}
                    </div>
                </div>
             else()
    else ()
};

(:~
 : Browse Alphabetical Menus
 : Currently include Syriac, Arabic, Russian and English
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable" xmlns="http://www.w3.org/1999/xhtml">
        <ul class="list-inline">
        {
            if(($browse:lang = 'syr')) then  
                for $letter in tokenize('ALL ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    <li class="syr-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="syr"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            else if(($browse:lang = 'ar')) then  
                for $letter in tokenize('ALL ا ب ت ث ج ح  خ  د  ذ  ر  ز  س  ش  ص  ض  ط  ظ  ع  غ  ف  ق  ك ل م ن ه  و ي', ' ')
                return 
                    <li class="ar-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="ar"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            else if($browse:lang = 'ru') then 
                for $letter in tokenize('А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я ALL',' ')
                return 
                <li>{if($browse:alpha-filter = $letter) then attribute class {"selected badge"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>            
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ALL', ' ')
                return
                    <li>{if($browse:alpha-filter = $letter) then attribute class {"selected badge"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
        }
        </ul>
    </div>
};

(: Syriac Corpus Customizations :)
declare function browse:group-results($node as node(), $model as map(*), $collection as xs:string?){
    let $hits := 
                if(request:get-parameter('author-exact', '') != '') then
                    $model("hits")//*[descendant::tei:author//text() = request:get-parameter('author-exact', '')]
                else $model("hits")
    let $authors := distinct-values($hits//tei:author) 
    return 
        map {"group-by-authors" := 
                if(request:get-parameter('author-exact', '')) then 
                   for $author in $authors[. = request:get-parameter('author-exact', '')]
                   order by global:build-sort-string($author,'')
                   return 
                        <author xmlns="http://www.w3.org/1999/xhtml" name="{normalize-space(string-join($author,' '))}"/>
                else 
                    for $author in $authors
                    order by global:build-sort-string($author,'') 
                    return 
                        <author xmlns="http://www.w3.org/1999/xhtml" name="{normalize-space(string-join($author,' '))}"/>
       }    
};