xquery version "3.0";
(: Build relationships. :)
module namespace rel="http://syriaca.org/related";
import module namespace rec="http://syriaca.org/short-rec-view" at "short-rec-view.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


(: Get names/titles for each uri :)
declare function rel:get-names($uris as xs:string?) as element(a)*{
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $names := $rec
    return 
        rec:display-recs-short-view($names, '')
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
                else replace($rec/descendant::tei:titleStmt/tei:title[1]/text(),'—',' ')
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