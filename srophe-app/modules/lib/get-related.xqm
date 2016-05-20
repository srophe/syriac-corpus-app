xquery version "3.0";
(: Build relationships. :)
module namespace rel="http://syriaca.org/related";
import module namespace page="http://syriaca.org/page" at "paging.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


(: Get names/titles for each uri :)
declare function rel:get-names($uris as xs:string?) as element(a)*{
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $names := $rec
    return 
        global:display-recs-short-view($names, '')
};

(: Get names/titles for each uri :)
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

declare function rel:make-rel-string($relationships as xs:string*) as xs:string*{
    for $r in  $relationships
    return concat(substring-after($r,':'),' ')
};

(: Build list with appropriate punctuation :)
declare function rel:list-names($uris as xs:string?){
    rel:get-names($uris)
};

(: Subject type, based on uri of @passive uris:)
declare function rel:get-subject-type($passive as xs:string*) as xs:string*{
if(contains($passive,'person') and contains($passive,'place')) then 'Records '
else if(contains($passive,'person')) then 'Persons '
else if(contains($passive,'place')) then 'Places '
else ()
};

(: Translate relationships into readable strings :)
declare function rel:decode-relatiohship($name as xs:string*, $passive as xs:string*, $mutual as xs:string*){
if($name = 'dcterms:subject') then
    concat(rel:get-subject-type($passive), ' highlighted: ')
else if($name = 'syriaca:commemorated') then
    concat(rel:get-subject-type($passive),' commemorated:  ')    
else concat(rel:get-subject-type($passive),' ', replace($name,'-|:',' '),' ')
};

(: Subject (passive) predicate (name) object(active) :)
declare function rel:construct-relation-text($related){
    <span class="relation">
          {(
            rel:decode-relatiohship($related/@name/string(),$related/@passive/string(),$related/@mutual/string()),
            rel:list-names($related/@passive/string())
            (:rel:list-names($related/@active/string()):)
            )}       
    </span>
};

declare function rel:cited($idno, $start,$perpage){
let $perpage := if($perpage) then $perpage else 5
let $hits := collection($global:data-root)//tei:ptr[@target=replace($idno,'/tei','')]
let $count := count($hits)
return
    if(exists($hits)) then 
        <div class="well relation">
            <h4>Cited in:</h4>
            <span class="caveat">{$count} record(s) cite this work.</span> 
            {
                for $recs in subsequence($hits,$start,$perpage)
                let $parent := $recs/ancestor::tei:TEI
                return global:display-recs-short-view($parent,'')
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

declare function rel:subject-headings($idno){
let $hits := collection($global:data-root)//tei:ptr[@target=replace($idno,'/tei','')]
return 
    if(exists($hits)) then 
        <div class="well relation">
            <h4>Subject Headings:</h4> 
            {
                for $recs in $hits
                let $parent := $recs/ancestor::tei:TEI
                let $headword := $parent/descendant::tei:body/descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'en')]
                let $sort := global:parse-name($headword)
                let $sort := global:build-sort-string($sort,'')
                let $subject-idno := replace($parent/descendant::tei:idno[1],'/tei','')
                order by $sort collation "?lang=en&lt;syr&amp;decomposition=full"
                return 
                   <span class="sh pers-label badge">{global:tei2html($headword)}</span>
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
(: Main div for HTML display :)
declare function rel:build-relationships($node){ 
<div class="relation well">
    <h3>Relationships</h3>
    <div>
    {   
        for $related in $node//tei:relation 
        let $desc := $related/tei:desc
        group by $relationship := $related/@name
        return 
            <div>{rel:construct-relation-text($related)}</div>
        }
    </div>
</div>
};
