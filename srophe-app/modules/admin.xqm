xquery version "3.0";

module namespace admin="http://syriaca.org//admin";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $admin:file {request:get-parameter("fileUpload", ())};
(:
    Need to work on authentication and add logout feature
:)
(:~
 : Check current user. 
:)

declare function admin:current-user($node as node(), $model as map(*)) {
    let $user := request:get-attribute("org.exist.demo.login.user")
    return 
        if ($user) then
            (<li><a href="#">Current user: {$user}</a></li>,
            <li><a href="login.html" id="logout">Logout</a></li>)
        else
            "Not logged in"
};
(: NOT WORKING :)
declare function admin:bad-user($node as node(), $model as map(*)) {
    let $user := request:get-attribute("org.exist.demo.login.user")
    return 
        if ($user) then
            ($user,
            <a href="login.html" id="logout">Logout</a>)
        else
            "Not logged in"
};
declare function admin:browse-places($node as node(), $model as map(*)){
    for $place in collection($config:app-root || '/admin/data/places')
    let $title := $place//tei:titleStmt/tei:title[1]/node()
    let $id := substring-after($place//tei:place/@xml:id,'place-')
    return 
        <li><a href="place.html?status=inprocess&amp;id={$id}">{$title}</a></li>
};
