xquery version "3.0";

module namespace global="http://syriaca.org//global";

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
    
declare variable $global:data-root := 
    let $app-root := doc('../config.xml')//app-root/text() 
    let $data-root := concat(doc('../config.xml')//data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;
