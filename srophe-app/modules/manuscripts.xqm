(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace ms="http://syriaca.org//manuscripts";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";

import module namespace timeline="http://syriaca.org//timeline" at "timeline.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $ms:id {request:get-parameter('id', '')};

(:~
 : Build persons view
 : @param $id persons URI
 :)
declare %templates:wrap function ms:get-data($node as node(), $model as map(*), $view){
    map {"data" := collection($config:app-root || "/data/manuscripts/tei")//tei:idno[@type='URI'][. = $ms:id]}            
};

declare %templates:wrap function ms:uri($node as node(), $model as map(*)){
    string($ms:id)
};

(:~
 : Build Manuscript title
:)
declare %templates:wrap function ms:h1($node as node(), $model as map(*)){
    let $rec := $model("data")/ancestor::tei:teiHeader
    let $title := $rec//tei:titleStmt/tei:title
    let $id := $rec//tei:idno[@type="URI"][.=$ms:id]
    return app:tei2html(<srophe-title  xmlns="http://www.tei-c.org/ns/1.0">{($title,$id)}</srophe-title>)
};

(:~
 : Pull together front matter  
:)
declare %templates:wrap function ms:front-matter($node as node(), $model as map(*)){
let $rec := $model("data")/ancestor::tei:teiHeader//tei:sourceDesc/tei:msDesc
let $history := $rec/descendant::tei:history
let $lang := $rec/descendant::tei:textLang[@mainLang]
return 
<div>
    <div class="well">
        {app:tei2html(($rec/tei:msIdentifier,$lang))}
    </div>
    <div class="well">
        {app:tei2html($rec/tei:physDesc)}
    </div>
     <div class="well">
        {app:tei2html(($history, $rec/tei:additional, $rec/tei:encodingDesc))}
    </div>
</div>
};

(:~ 
 : Output msItems transformed via tei2html xslt   
 : Pull in names from persons database for author information
:)
declare function ms:msItems($node as node(), $model as map(*)){
let $rec := $model("data")/ancestor::tei:teiHeader//tei:sourceDesc/tei:msDesc/tei:msContents 
let $authors := 
    <tei:msAuthors xmlns="http://www.tei-c.org/ns/1.0">
    {
    for $auth in  $rec//tei:author
    let $ref := string($auth/@ref)
    let $author := collection($config:app-root || "/data/persons/tei")//tei:idno[@type='URI'][. = $ref]
    return
        <tei:msAuthor id="{$ref}">{$author/parent::*/tei:persName[@syriaca-tags='#syriaca-headword'][1]}</tei:msAuthor>
    }
    </tei:msAuthors>
    
return
    (<div>
        <h3>Manuscript Contents</h3>
        <p style="margin:0 2em;" class="well">This manuscript contains {count($rec//tei:msItem)} items {if($rec//tei:msItem/tei:msItem) then 'including nested subsections' else ()}. 
        N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
    </div>,
    app:tei2html(($authors,$rec)))
};
