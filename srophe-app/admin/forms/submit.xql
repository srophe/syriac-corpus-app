xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";



(:~
    Process user and password passed from the login form.
    Returns a pair of (user, password) if the credentials are
    valid, an empty sequence if not.
:)

declare function local:update(){
let $results := request:get-data()
let $newData := $results
return 
    <dummy>
        <test>{$newData}</test>
    </dummy>    
};

let $cache := 'change value to force refresh: 344'
return local:update()   
