(:~  
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace mss="http://syriaca.org/manuscripts";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $mss:id {request:get-parameter('id', '')};

(:~
 : Holding place
 : Value passed through metadata:page-title() 
:)
declare function mss:html-title(){
    let $mssURI :=
        if(contains($mss:id,$global:base-uri)) then $mss:id 
        else concat($global:base-uri,'/manuscript/',$mss:id)
    let $title := collection($global:data-root || "/manuscripts/tei")//tei:idno[@type='URI'][. = $mssURI]/ancestor::tei:TEI/descendant::tei:title[1]
    return normalize-space($title)
};

(:~
 : Traverse main nav and "fix" links based on values in config.xml 
:)
declare
    %templates:wrap
function mss:fix-links($node as node(), $model as map(*)) {
    templates:process(global:fix-links($node/node()), $model)
};

(:~
 : Build manuscripts view
 : @param $id mss URI
 :)
declare %templates:wrap function mss:get-data($node as node(), $model as map(*), $collection as xs:string?){
    app:get-rec($node, $model, $collection)
};

declare %templates:wrap function mss:uri($node as node(), $model as map(*)){
    string($mss:id)
};

(:~       
 : Build Manuscript title
:)
declare %templates:wrap function mss:h1($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $title := $rec/descendant::tei:title[1]
    let $id := $rec/descendant::tei:idno[@type='URI'][1]
    return global:tei2html(<srophe-title  xmlns="http://www.tei-c.org/ns/1.0">{($title,$id)}</srophe-title>)
};

(:~
 : Pull together front matter  
:)
declare %templates:wrap function mss:front-matter($node as node(), $model as map(*)){
let $rec := $model("data")/descendant::tei:sourceDesc/tei:msDesc
let $history := $rec/child::tei:history
let $lang := $rec/child::tei:textLang[@mainLang]
return 
<div>
    <div class="well">
        {global:tei2html(($rec/tei:msIdentifier,$lang))}
    </div>
    <div>
        {global:tei2html($rec/tei:physDesc)}
    </div>
     <div class="well">
        {global:tei2html(($history, $rec/tei:additional, $rec/tei:encodingDesc))}
    </div>
</div>
};

(:~ 
 : Output msItems transformed via tei2html xslt    
 : Pull in names from persons database for author information
:)
declare function mss:msItems($node as node(), $model as map(*)){
let $rec := $model("data")/descendant::tei:msContents | $model("data")/ancestor::tei:teiHeader/descendant::tei:msPart 
let $authors := 
    <tei:msAuthors xmlns="http://www.tei-c.org/ns/1.0">
    {
    for $auth in  $rec//tei:author
    let $ref := string($auth/@ref)
    let $author := collection($global:data-root || "/persons/tei")//tei:idno[@type='URI'][. = $ref]
    return
        <tei:msAuthor id="{$ref}">{global:parse-name($author/parent::*/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang = 'en'][1])}</tei:msAuthor>
    }
    </tei:msAuthors>
    
return
    (<div>
        <h3>Manuscript Contents</h3>
        <p style="margin:0 2em;" class="well">This manuscript contains {count($rec//tei:msItem)} items {if($rec//tei:msItem/tei:msItem) then 'including nested subsections' else ()}. 
        N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
    </div>,
    global:tei2html(($authors,$rec)))
};
