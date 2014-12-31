(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace ms="http://syriaca.org//manuscripts";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

import module namespace timeline="http://syriaca.org//timeline" at "timeline.xqm";
import module namespace tei2="http://syriaca.org//tei2html" at "tei2html.xqm";

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
 : Checks for record in Syriaca.org, uses connical record as title, otherwise uses spear data
:)
declare %templates:wrap function ms:h1($node as node(), $model as map(*)){
    let $rec := $model("data")/ancestor::tei:teiHeader//tei:sourceDesc/tei:msDesc/tei:msIdentifier
    let $title := $rec/tei:repository
    let $id := $rec/tei:idno[@type="URI"]
    let $altid := $rec/tei:altIdentifier[tei:idno[@type="BL-Shelfmark"]]
    return app:tei2html(
               <body xmlns="http://www.tei-c.org/ns/1.0">
                    <srophe-title>
                        {($title,$id,$altid)}
                    </srophe-title>
                </body>)
};

declare %templates:wrap function ms:front-matter($node as node(), $model as map(*)){
let $rec := $model("data")/ancestor::tei:teiHeader//tei:sourceDesc/tei:msDesc
let $history := $rec/descendant::tei:history
let $lang := $rec/descendant::tei:textLang[@mainLang]
return 
<div>
    {app:tei2html(($history,$lang))}
    <div>
        <h4>Contents</h4>
        <p>This manuscript contains {count($rec//tei:msItem)} items {if($rec//tei:msItem/tei:msItem) then 'including nested subsections' else ()}. 
        N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
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
return app:tei2html(($authors,$rec))
};
