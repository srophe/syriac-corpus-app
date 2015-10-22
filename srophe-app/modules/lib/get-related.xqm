xquery version "3.0";
(: Global app variables and functions. :)
module namespace rel="http://syriaca.org/related";
import module namespace global="http://syriaca.org/global" at "global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


declare function rel:get-names($uris as xs:string?){
    for $uri in tokenize($uris,' ')
    let $rec :=  global:get-rec($uri)
    let $name := string-join($rec/descendant::*[starts-with(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^en')][1]/text(),' ')
    return 
        <a href="{global:internal-links($uri)}">{$name}</a>
};

(:
    will need a function to "decript" @name attributes and create logical sentances from them
:)

declare function rel:decode-relatiohship($name as xs:string*){
if($name = 'dcterms:subject') then
    ' about '
else replace($name,'-|:',' ')
};

(: Subject (passive) predicate (name) object(active) :)
declare function rel:construct-relation-text($related){
    <span class="relation">
          {(
            rel:get-names($related/@passive/string()), 
            rel:decode-relatiohship($related/@name/string()),
            rel:get-names($related/@active/string())
            )}       
    </span>
};

declare function rel:build-relationships($node){ 
<div class="relation well">
    <h3>Relationships</h3>
    <div>
    {   
        for $related in $node//tei:relation 
        let $desc := $related/tei:desc
        return 
            <div>{rel:construct-relation-text($related)}</div>
        }
    </div>
</div>
};