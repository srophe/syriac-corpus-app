xquery version "3.0";

module namespace app="http://syriaca.org//templates";
(:~
 : General use xqueries for srophe app.
:)
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 : Grabs latest news for home page
 : http://syriaca.org/feed/
 :)
 
declare %templates:wrap function app:get-feed($node as node(), $model as map(*)){ 
   let $news := doc('http://syriaca.org/feed/')/child::*
   for $latest at $n in subsequence($news//item, 1, 5)
   return 
   <li>
        <a href="{$latest/link/text()}">{$latest/title/text()}</a> [{$latest/pubDate}]
   </li>
};

(:~
 : Typeswitch to transform confessions.xml into nested list.
 : @param $node   
:)
declare function app:transform($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return $node
            case element(tei:list) return element ul {app:transform($node/node())}
            case element(tei:item) return element li {app:transform($node/node())}
            case element(tei:label) return element span {app:transform($node/node())}
            default return app:transform($node/node())
};

(:~
 : Pull confession data for confessions.html
:)
declare %templates:wrap function app:build-confessions($node as node(), $model as map(*)){
    let $confession := doc('/db/apps/srophe/documentation/confessions.xml')//tei:body/child::*[1]
    return app:transform($confession)
};

(:~
 : get editors as distinct values
:)
declare function app:get-editors(){
distinct-values(
    (for $editors in collection('/db/apps/srophe/data/places/tei')//tei:respStmt/tei:name/@ref
     return substring-after($editors,'#'),
     for $editors-change in collection('/db/apps/srophe/data/places/tei')//tei:change/@who
     return substring-after($editors-change,'#'))
    )
};

(:~
 : Build editor list. Sort alphabeticaly
:)
declare %templates:wrap function app:build-editor-list($node as node(), $model as map(*)){
    let $editors := doc('/db/apps/srophe/documentation/editors.xml')//tei:listPerson
    for $editor in app:get-editors()
    let $name := 
        for $editor-name in $editors//tei:person[@xml:id = $editor]
        return concat($editor-name/tei:persName/tei:forename,' ',$editor-name/tei:persName/tei:addName,' ',$editor-name/tei:persName/tei:surname)
    let $sort-name :=
        for $editor-name in $editors//tei:person[@xml:id = $editor] return $editor-name/tei:persName/tei:surname
    order by $sort-name
    return
        if($editor != '') then 
          <li>{normalize-space($name)}</li>
        else ''  
};