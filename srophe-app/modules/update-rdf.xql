xquery version "3.1";
(:~
 : XQuery RDF generation
 : Checks for updates since last modified version using:
     eXistdb's xmldb:find-last-modified-since($node-set as node()*, $since as xs:dateTime) as node()*
 : Converts TEI records to RDF using $global:public-view-base/modules/lib/rei2rdf.xqm 
 : Adds new RDF records to RDF store.
 :
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm ";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: Can I store the last modified date in the script? :)
declare variable $rdf-config := if(doc('config.xml')) then doc('zotero-config.xml') else ();
declare variable $last-modified-version := $rdf-config//rdf/last-modified/text();

(: Update RDF :)
declare function local:update-rdf(){
let $action := request:get-parameter('action', '')
let $collection := request:get-parameter('collection', '')
return 
    if($action = 'initiate') then
        local:get-records($action,$collection,())
    else if(request:get-parameter('action', '') = 'update') then
        <response status="200">
            <message>Update!</message>
        </response>
    else 
        <response status="400">
            <message>You did not give me any directions.</message>
        </response>
};

declare function local:get-records($action as xs:string?, $collection as xs:string?, $date as xs:dateTime?){
    if($action = 'initiate') then
        let $records := 
            if($collection != '') then 
                collection($global:data-root || '/' || $collection)/tei:TEI 
            else collection($global:data-root)/tei:TEI
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            <response status="200">
                <message>{('Total: ', $total, ' perpage: ', $perpage, ' pages:', $pages, ' collection:', $collection, 'data root: ',$global:data-root)}</message>
                <output>{local:process-results($records, $total, $start, $perpage)}</output>
            </response>
    else if($action = 'update') then 
        let $records := 
            if($collection != '') then 
                collection($global:data-root || '/' || $collection)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))] 
            else collection($global:data-root)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))]
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            <response status="200">
                <message>{('Total: ', $total, ' perpage: ', $perpage, ' pages:', $pages, ' collection:', $collection, 'data root: ',$global:data-root)}</message>
                <output>{local:process-results($records, $total, $start, $perpage)}</output>
            </response>            
    else 
        <response status="200">
            <message>There is no other hand.</message>
        </response>
};

declare function local:process-results($records as item()*, $total, $start, $perpage){
    let $end := $start + $perpage
    return
        (
         for $r in subsequence($records,$start,$perpage)
         let $uri := document-uri(root($r))
         let $rdf := tei2rdf:rdf-output($r)
         let $file-name := substring-before(tokenize($uri,'/')[last()],'.xml')
         let $collection := substring-before($uri, $file-name)
         let $rdf-collection := replace(replace(substring(substring-after($collection, $global:data-root),2),'tei','rdf'),'/','-')
         let $rdf-filename := concat($rdf-collection,$file-name,'.rdf')
         return 
             try {
                 <response status="200">
                     <message>{xmldb:store('/db/rdftest', xmldb:encode-uri($rdf-filename), $rdf)}</message>
                 </response>
                 } catch *{
                 <response status="fail">
                     <message>Failed to add resource {$rdf-filename}: {concat($err:code, ": ", $err:description)}</message>
                 </response>
                 },
         if($total gt $end) then 
             local:process-results($records, $total, $end, $perpage)
         else <message>end of the line end: {$end} total: {$total} start {$start} perpage: {$perpage}</message>
         )            
};

(: Create rdf collection if it does not exist. :)
declare function local:build-collection(){
    let $rdftest-coll := xmldb:create-collection("/db", "rdftest")
    let $rdftest-conf-coll := xmldb:create-collection("/db/system/config/db", "rdftest")
    let $rdf-conf :=
        <collection xmlns="http://exist-db.org/collection-config/1.0">
           <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
              <rdf />
           </index>
        </collection>
    return xmldb:store($rdftest-conf-coll, "collection.xconf", $rdf-conf)
};

(:~
 : Check action parameter, if empty, return contents of config.xml
 : If $action is not empty, check for specified collection, create if it does not exist. 
 : Run Zotero request. 
:)
if(request:get-parameter('action', '') != '') then
    if(xmldb:collection-available('/db/rdftest')) then
        local:update-rdf()
    else (local:build-collection(),local:update-rdf())
else 
    <div>
        <p><label>Last Updated: </label> {$last-modified-version}</p>
    </div>