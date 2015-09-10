xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
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

(: Name of logo, not currently used dynamically :)
declare variable $global:app-logo := $global:get-config//logo/text();

(: Map rendering, google or leaflet :)
declare variable $global:app-map-option := $global:get-config//maps/option[@selected='true']/text();

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
                        {$node/@* except $node/@action, $node/node()}
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
    </parameters>
    )
};


