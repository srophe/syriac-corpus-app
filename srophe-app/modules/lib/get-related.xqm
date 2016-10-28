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
declare function rel:get-uris($uris as xs:string*, $idno) as xs:string*{
    for $uri in distinct-values(tokenize($uris,' '))
    where ($uri != $idno and not(starts-with($uri,'#')))  
    return $uri
};

declare function rel:display($uri as xs:string*) as element(a)*{
    let $rec :=  global:get-rec($uri)  
    return global:display-recs-short-view($rec, '')
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
                else substring-before($rec/descendant::tei:titleStmt/tei:title[1]/text(),'—')
    return <name>{normalize-space($name)}</name>     
};

(:~ 
 : Describe relationship using tei:description or @name
 : @param $related relationship element 
 :)
declare function rel:decode-relationship($related as node()*){
 <span class="srp-label">
    {
     if($related/tei:desc != '') then
        distinct-values($related/tei:desc/text())[1]
     else 
        let $name := $related/@name | $related/@ref
        for $name in $name[1]
        let $subject-type := rel:get-subject-type($related/@passive)
        return 
            if($name = 'dcterms:subject') then 
                concat($subject-type, ' highlighted: ')
            else if($name = 'syriaca:commemorated') then
                concat($subject-type,' commemorated:  ')    
            else  string-join(
                for $w in tokenize($name,' ')
                return functx:capitalize-first(substring-after(functx:camel-case-to-words($w,' '),':')),' ')
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
    for $r in collection($global:data-root)//@target[. = replace($idno,'/tei','')]
    let $headword := $r/ancestor::tei:TEI/descendant::tei:title[1]
    let $id := $r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][1]
    let $sort := global:parse-name($headword)
    let $sort := global:build-sort-string($sort,'')
    order by $sort collation "?lang=en&lt;syr&amp;decomposition=full"
    return <TEI xml:ns="http://www.tei-c.org/ns/1.0">{$headword, $id}</TEI>      
};

(:~ 
 : HTML display of 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:cited($idno, $start,$perpage){
    let $perpage := if($perpage) then $perpage else 5
    let $hits := rel:get-cited(replace($idno/text(),'/tei',''))
    let $count := count($hits)
    return
        if(exists($hits)) then 
            <div class="well relation">
                <h4>Cited in:</h4>
                <span class="caveat">{$count} record(s) cite this work.</span> 
                {   
                    if($count gt 5) then
                        for $recs in subsequence($hits,$start,$perpage)
                        return global:display-recs-short-view(collection($global:data-root)//tei:idno[@type='URI'][. = $hits//tei:idno]/ancestor::tei:TEI,'')                        
                    else 
                        for $recs in $hits
                        return global:display-recs-short-view(collection($global:data-root)//tei:idno[@type='URI'][. = $hits//tei:idno]/ancestor::tei:TEI,'')
                }
                {
                     if($count gt 5) then 
                        <div class="row">
                            <div class="col-sm-12">{page:pages($hits, $start, $perpage,'', '')}</div>
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
    let $hits := rel:get-cited(replace($idno/text(),'/tei',''))
    let $total := count($hits)
    return 
        if(exists($hits)) then
            <div class="well relation">
                <h4>Subject Headings:</h4>
                {
                    (
                    for $recs in subsequence($hits,1,20)
                    let $headword := $recs/tei:title
                    let $subject-idno := replace($recs/tei:idno,'/tei','')
                    return 
                        <span class="sh pers-label badge">{replace($headword/text(),' — ','')} 
                        <a href="search.html?subject={$subject-idno}" class="sh-search">
                        <span class="glyphicon glyphicon-search" aria-hidden="true"></span>
                        </a></span>,
                    if($total gt 20) then
                        (<div class="collapse" id="showAllSH">
                            {
                            for $recs in subsequence($hits,20,$total)
                            let $headword := $recs/tei:title
                            let $subject-idno := replace($recs/tei:idno,'/tei','')
                            return 
                               <span class="sh pers-label badge">{replace($headword/text(),' — ','')} 
                               <a href="search.html?subject={$subject-idno}" class="sh-search"> 
                               <span class="glyphicon glyphicon-search" aria-hidden="true">
                               </span></a></span>
                            }
                        </div>,
                        <a class="togglelink pull-right btn-link" data-toggle="collapse" data-target="#showAllSH" data-text-swap="Hide"> <span class="glyphicon glyphicon-plus" aria-hidden="true"></span> Show All </a>
                        )
                    else ()
                    )
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
        let $names := rel:get-uris(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno)
        let $count := count($names)
        let $rel-id := index-of($node, $related[1])
        group by $relationship := $related/@name
        return 
            <div>
            {(
                rel:decode-relationship($related),
                for $r in subsequence($names,1,2)
                return rel:display($r),
                if($count gt 2) then
                    <span>
                        <span class="collapse" id="showRel-{$rel-id}">{
                            for $r in subsequence($names,3,$count)
                            return rel:display($r)
                        }</span>
                        <a class="togglelink btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                    </span>
                else ()
            )}
            </div>
        }
    </div>
</div>
};