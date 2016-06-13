xquery version "3.0";
(: Build relationships. :)
module namespace rel="http://syriaca.org/related";
import module namespace page="http://syriaca.org/page" at "paging.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


(:~ 
 : Get names/titles for each uri
 : @param $uris passed as string, can contain multiple uris
 : @param $idno for parent record, can be blank. Used to filter current record from results list. 
 :)
declare function rel:get-names($uris as xs:string*, $idno) as element(a)*{
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $names := $rec
    where $uri != $idno
    return 
       global:display-recs-short-view($names, '')
};

(:~ 
 : Get names/titles for each uri, for json output
 : @param $uris passed as string, can contain multiple uris
 :)
declare function rel:get-names-json($uris as xs:string?) as node()*{
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $name := 
                if(contains($uris,'/spear/')) then
                    let $string := normalize-space(string-join($rec/descendant::text(),' '))
                    let $last-words := tokenize($string, '\W+')[position() = 5]
                    return concat(substring-before($string, $last-words),'...')
                else replace(string-join($rec/descendant::tei:titleStmt/tei:title[1]/text(),' '),'—',' ')
    return <name>{$name}</name>     
};

(:~ 
 : Describe relationship using tei:description or @name
 : @param $related relationship element 
 :)
declare function rel:decode-relationship($related as node()*){
 <span class="srp-label label">
    {
     if($related/tei:desc != '') then
        $related/tei:desc
     else 
        let $name := $related/@name
        let $subject-type := rel:get-subject-type($related/@passive)
        return 
            if($name = 'dcterms:subject') then 
                concat($subject-type, ' highlighted: ')
            else if($name = 'syriaca:commemorated') then
                concat($subject-type,' commemorated:  ')    
            else  string-join(
                for $w in tokenize(replace($name,'-|:',' '),' ')
                return functx:capitalize-first($w),' ')
     }
 </span>
};

(:~ 
 : Subject type, based on uri of @passive uris
 : @param 'passive' $relationship attribute
:)
declare function rel:get-subject-type($passive as xs:string*) as xs:string*{
    if(contains($passive,'person') and contains($passive,'place')) then 'Records '
    else if(contains($passive,'person')) then 'Persons '
    else if(contains($passive,'place')) then 'Places '
    else ()
};

(:~ 
 : Get 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:get-cited($idno){
    for $recs in collection($global:data-root)//tei:TEI[descendant::tei:ptr[@target=replace($idno,'/tei','')]]
    let $headword := $recs/descendant::tei:body/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1]
    let $sort := global:parse-name($headword)
    let $sort := global:build-sort-string($sort,'')
    order by $sort collation "?lang=en&lt;syr&amp;decomposition=full"
    return $recs
};

(:~ 
 : HTML display of 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:cited($idno, $start,$perpage){
    let $perpage := if($perpage) then $perpage else 5
    let $hits := rel:get-cited($idno)
    let $count := count($hits)
    return
        if(exists($hits)) then 
            <div class="well relation">
                <h4>Cited in:</h4>
                <span class="caveat">{$count} record(s) cite this work.</span> 
                {
                    for $recs in subsequence($hits,$start,$perpage)
                    return global:display-recs-short-view($recs,'')
                }
                {
                     if($count gt 5) then 
                        <div class="row">
                            <div class="col-sm-12">{page:pageination($hits, $start, $perpage, false())}</div>
                        </div>
                     else ()
                 }
            </div>
        else ()
        
};

(:
 : HTML display of 'subject headings' using 'cited by' relationships
 : @param $idno bibl idno
:)
declare function rel:subject-headings($idno){
    let $hits := rel:get-cited($idno)
    let $total := count($hits)
    return 
        if(exists($hits)) then 
        <div class="well relation">
            <h4>Subject Headings:</h4> 
            {
                <div>
                {(
                for $recs in subsequence($hits,1,20)
                let $headword := $recs/descendant::tei:body/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1]
                let $subject-idno := replace($recs/descendant::tei:idno[1],'/tei','')
                return 
                   <span class="sh pers-label badge">{string($headword)} <a href="search.html?subject={$subject-idno}" class="sh-search"><span class="glyphicon glyphicon-search" aria-hidden="true"></span></a></span>,
                if($total gt 20) then 
                    <div>
                        
                        <div class="collapse" id="showAllSH">
                            {
                            for $recs in subsequence($hits,20,$total)
                            let $headword := $recs/descendant::tei:body/descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'en')]
                            let $subject-idno := replace($recs/descendant::tei:idno[1],'/tei','')
                            return 
                               <span class="sh pers-label badge">{global:tei2html($headword)} <a href="search.html?subject={$subject-idno}" class="sh-search"><span class="glyphicon glyphicon-search" aria-hidden="true"></span></a></span>
                            }
                        </div>
                        <a class="togglelink pull-right btn-link" data-toggle="collapse" data-target="#showAllSH" data-text-swap="Hide"> <span class="glyphicon glyphicon-plus" aria-hidden="true"></span> Show All </a>
                    </div>                  
                  else ()
                  )}
                 </div>
                  

                (:
                    <a href="{replace($idno,$global:base-uri,$global:app-root)}">{
                    (:global:tei2html($headword):)
                    $headword
                    }</a>
                    :)
            }
        </div>
    else ()
};

(:~ 
 : Main div for HTML display 
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-relationships($node,$idno){ 
<div class="relation well">
    <h3>Relationships</h3>
    <div>
    {   
        for $related in $node/descendant-or-self::tei:relation
        let $count := count(rel:get-names(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno))
        let $rel-id := index-of($node, $related)
        group by $relationship := $related/@name
        return 
            <div>
            {(
                rel:decode-relationship($related),
                <span>
                    <span class="collapse" id="showRel-{$rel-id}">{rel:get-names(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno)}</span>
                    <a class="togglelink btn-link" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide">See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                </span>  

            )}
            </div>
        }
    </div>
</div>
};