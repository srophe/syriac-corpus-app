xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
declare namespace repo="http://exist-db.org/xquery/repo";
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
(: Get repo.xml to parse global varaibles :)
declare variable $global:get-config := doc($global:app-root || '/repo.xml');

(: Establish data app root :)
declare variable $global:data-root := 
    let $app-root := $global:get-config//repo:app-root/text()  
    let $data-root := concat($global:get-config//repo:data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;

(: Establish main navigation for app, used in templates for absolute links. Syriaca.org uses a development and production server which each have different root directories.  :)
declare variable $global:nav-base := 
    if($global:get-config//repo:nav-base/text() != '') then $global:get-config//repo:nav-base/text()
    (: For app set to root '/' see syriaca.org production site. :)
    else if($global:get-config//repo:nav-base/text() = '/') then ''
    else concat('/exist/apps/',$global:app-root);

(: Base URI used in record tei:idno :)
declare variable $global:base-uri := $global:get-config//repo:base_uri/text();

declare variable $global:app-title := $global:get-config//repo:title/text();

declare variable $global:app-url := $global:get-config//repo:url/text();

(: Map rendering, google or leaflet :)
declare variable $global:app-map-option := $global:get-config//repo:maps/repo:option[@selected='true']/text();

(: Recaptcha Key, Store as environemnt variable. :)
declare variable $global:recaptcha := '6Lc8sQ4TAAAAAEDR5b52CLAsLnqZSQ1wzVPdl0rO';

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

(:~
 : Build uri from short id
 : @param $id from URL
:)
declare function global:resolve-id(){
let $id := request:get-parameter('id', '')
let $parse-id :=
    if(contains($id,$global:base-uri) or starts-with($id,'http://')) then $id
    else if(contains(request:get-uri(),$global:nav-base)) then replace(request:get-uri(),$global:nav-base, $global:base-uri)
    else if(contains(request:get-uri(),$global:base-uri)) then request:get-uri()
    else $id
let $final-id := if(ends-with($parse-id,'.html')) then substring-before($parse-id,'.html') else $parse-id
return $final-id
};

(:
 : Generic get record function
 : Manuscripts and SPEAR recieve special treatment as individule parts may be treated as full records. 
 : @param $id syriaca.org uri for record or part. 
:)
declare function global:get-rec($id as xs:string){  
    for $rec in collection($global:data-root)//tei:TEI[.//tei:idno[@type='URI'][text() = $id]]
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
    else replace($titlestring,'^\s+|^al-|^On\s+|^The\s+|^A\s+|^''De |^[|^‘|^ʻ|^ʿ|^]|^\d*\W','')
};

(:~
 : Strips Arabic titles of non-sort characters as established by Syriaca.org
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:ar-sort-string($titlestring as xs:string?) as xs:string* {
    replace(replace(replace(replace($titlestring,'^\s+',''),'^(\sابن|\sإبن|\sبن)',''),'(ال|أل|ٱل)',''),'[U064B-U0656]','')
};

(:
 : example: global:odd2text($rec/descendant::tei:bibl[1],string($rec/descendant::tei:bibl[1]/@type))
:)
declare function global:odd2text($element as element()?, $label as xs:string?) as xs:string* {
    let $odd := util:parse(util:binary-to-string(util:binary-doc($global:app-root || '/documentation/syriaca-tei-main.odd')))
    return 
        if($odd/descendant::tei:elementSpec[@ident = name($element)]/descendant::tei:valItem[@ident=$label]/tei:gloss/text()) then
            $odd/descendant::tei:elementSpec[@ident = name($element)]/descendant::tei:valItem[@ident=$label]/tei:gloss/text()
        else ''  

};


(:~
 : Configure dropdown menu for keyboard layouts for input boxes
 : Options are defined in repo.xml
 : @param $input-id input id used by javascript to select correct keyboard layout.  
 :)
declare function global:keyboard-select-menu($input-id as xs:string){
    (: Could have lange options set in config :)
    if($global:get-config//repo:keyboard-options/child::*) then 
        <ul xmlns="http://www.w3.org/1999/xhtml" class="dropdown-menu" test="TEST">
            {
            for $layout in $global:get-config//repo:keyboard-options/repo:option
            return  
                <li xmlns="http://www.w3.org/1999/xhtml"><a href="#" class="keyboard-select" id="{$layout/@id}" data-keyboard-id="{$input-id}">{$layout/text()}</a></li>
            }
        </ul>
    else ()       
};