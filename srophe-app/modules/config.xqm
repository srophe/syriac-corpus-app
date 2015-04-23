xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://syriaca.org//config";

import module namespace metadata="http://syriaca.org//metadata" at "metadata.xqm";
import module namespace place="http://syriaca.org//place" at "place.xqm";
import module namespace person="http://syriaca.org//person" at "person.xqm";
import module namespace mss="http://syriaca.org//manuscripts" at "manuscripts.xqm";
import module namespace spear="http://syriaca.org//spear" at "spear.xqm";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
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

declare variable $config:data-root := $config:app-root || "/data";

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};


declare %templates:wrap function config:app-title($node as node(), $model as map(*)) {
(:There are problems with view.xql, not passing params? or template params? Not working with shortend uris:)
    if(contains(request:get-uri(),'/geo/')) then 
        if(request:get-parameter('id', '')) then place:html-title() else 'Syriaca.org: The Syriac Gazetteer'
    else if(contains(request:get-uri(),'/place/')) then 
        if(request:get-parameter('id', '')) then place:html-title() else 'Syriaca.org: The Syriac Gazetteer'
    else if(contains(request:get-uri(),'/persons/')) then 
        if(request:get-parameter('id', '')) then person:html-title() else 'Syriaca.org: The Syriac Prosopography'
    else if(contains(request:get-uri(),'/person/')) then 
        if(request:get-parameter('id', '')) then person:html-title() else 'Syriaca.org: The Syriac Prosopography'        
    else if(contains(request:get-uri(),'/mss/')) then 
        if(request:get-parameter('id', '')) then mss:html-title() else 'Syriaca.org: A Digital Catalogue of Syriac Manuscripts in the British Library'
    else if(contains(request:get-uri(),'/manuscript/')) then 
        if(request:get-parameter('id', '')) then mss:html-title() else 'Syriaca.org: A Digital Catalogue of Syriac Manuscripts in the British Library'
    else if(contains(request:get-uri(),'/spear/')) then
        if(request:get-parameter('id', '')) then spear:html-title() else 'Syriaca.org: SPEAR'
    else if(contains(request:get-uri(),'/saints/')) then 'Syriaca.org: Qadishē: Guide to the Syriac Saints'
    else if(contains(request:get-uri(),'/authors/')) then 'Syriaca.org: A Guide to Syriac Authors'
    else 'Syriaca.org: The Syriac Reference Portal'
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};