xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "../modules/lib/global.xqm";
import module namespace jsonld="http://syriaca.org/jsonld" at "../modules/lib/jsonld.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "sparql.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

(:declare namespace sparql="http://www.w3.org/2005/sparql-results#";:)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $qname {request:get-parameter('qname', '')};
declare variable $id {request:get-parameter('id', '')};

if(request:get-parameter('sparql', '')) then
    let $results := sparql:query(request:get-parameter('sparql', ''))
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then              
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else (response:set-header("Access-Control-Allow-Origin", "*"),
              response:set-header("Access-Control-Allow-Methods", "GET, POST"),
              $results)
else if(request:get-parameter('query', '')) then 
    let $results := sparql:query(request:get-parameter('query', ''))
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then             
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "text/xml"),
            $results)  
else if(not(empty(request:get-data()))) then
    let $results := sparql:query(request:get-data())
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then             
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "application/json"),
            jsonld:jsonld($results))
        else
            (response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "GET, POST"),
            response:set-header("Content-Type", "text/xml"),
            $results)                   
else <message>No query data submitted</message>
