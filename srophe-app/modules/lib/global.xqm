xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(: Find app root, borrowed from config.xqm :)
declare variable $global:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
    ;
(: Get config.xml to parse global varaibles :)
declare variable $global:get-config := doc($global:app-root || '/config.xml');

(: Establish data app root :)
declare variable $global:data-root := 
    let $app-root := $global:get-config//app-root/text()  
    let $data-root := concat($global:get-config//data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;

(: Establish main navigation for app, used in templates for absolute links :)
declare variable $global:nav-base := 
    if($global:get-config//nav-base/text() != '') then $global:get-config//nav-base/text()
    else concat('/exist/apps/',$global:app-root);

(: Base URI used in tei:idno :)
declare variable $global:base-uri := $global:get-config//base_uri/text();

declare variable $global:app-title := $global:get-config//title/text();

declare variable $global:app-url := $global:get-config//url/text();

(: Name of logo, not currently used dynamically :)
declare variable $global:app-logo := $global:get-config//logo/text();

(: Map rendering, google or leaflet :)
declare variable $global:app-map-option := $global:get-config//maps/option[@selected='true']/text();

(: Sub in relative paths based on base-url variable :)
declare function global:internal-links($uri){
    replace($uri,$global:base-uri,$global:nav-base)
};

(:
 : Addapted from https://github.com/eXistSolutions/hsg-shell
 : Recurse through menu output absolute urls based on config.xml values. 
:)
declare function global:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(html:a) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element(html:form) return
                let $action := replace($node/@action, "\$app-root", $global:nav-base)
                return
                    <form action="{$action}">
                        {$node/@* except $node/@action, global:fix-links($node/node())}
                    </form>      
            case element() return
                element { node-name($node) } {
                    $node/@*, global:fix-links($node/node())
                }
            default return
                $node
};

(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
  transform:transform($nodes, doc($global:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
    </parameters>
    )
};

(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : Should handle all data types, and eliminate the need for 
 : data type specific display functions eg: persons:saints-results-node()
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : Used by search.xqm, browse.xqm and get-related.xqm
:)
declare function global:display-recs-short-view($node, $lang, $recid) as node()*{
  transform:transform($node, doc($global:app-root || '/resources/xsl/rec-short-view.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="lang" value="{$lang}"/>
        <param name="recid" value="{$recid}"/>
    </parameters>
    )
};


(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : Should handle all data types, and eliminate the need for 
 : data type specific display functions eg: persons:saints-results-node()
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : Used by search.xqm, browse.xqm and get-related.xqm
:)
declare function global:display-recs-short-view($node, $lang) as node()*{
  transform:transform($node, doc($global:app-root || '/resources/xsl/rec-short-view.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="lang" value="{$lang}"/>
    </parameters>
    )
};

(:
 : Generic get record function
 : Manuscripts and SPEAR recieve special treatment as individule parts may be treated as full records. 
 : @param $id syriaca.org uri for record or part. 
:)
declare function global:get-rec($id as xs:string){  
    if(contains($id,'/spear/')) then 
        for $rec in collection($global:data-root)//tei:div[@uri = $id]
        return 
            <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec}</tei:TEI>   
    else if(contains($id,'/manuscript/')) then
    (: Descrepency in how id's are handled, why dont the msPart id's have '/tei'?  :)
        for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = $id]
        return 
            if($rec/ancestor::tei:msPart) then
               <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec/ancestor::tei:msPart}</tei:TEI>
            else $rec/ancestor::tei:TEI
    else 
        for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = concat($id,'/tei')]/ancestor::tei:TEI
        return $rec 
};

(:~ 
 : Parse persNames to take advantage of sort attribute in display. 
 : Returns a sorted string
 : @param $name persName element 
 :)
declare function global:parse-name($name as node()*) as xs:string* {
if($name/child::*) then 
    string-join(for $part in $name/child::*
    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
    return $part/text(),' ')
else $name/text()
};

(:~
 : Strips english titles of non-sort characters as established by Syriaca.org
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:build-sort-string($titlestring as xs:string?, $lang as xs:string?) as xs:string* {
    if($lang = 'ar') then global:ar-sort-string($titlestring)
    else replace($titlestring,'^\s+|^al-|^On\s+|^The\s+|^A\s+|^''De |^[|^‘|^ʻ|^ʿ|^]','')
};

(:~
 : Strips Arabic titles of non-sort characters as established by Syriaca.org
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:ar-sort-string($titlestring as xs:string?) as xs:string* {
    replace(replace(replace(replace($titlestring,'^\s+',''),'^(\sابن|\sإبن|\sبن)',''),'(ال|أل|ٱل)',''),'^[U064B - U0656]','')
};
