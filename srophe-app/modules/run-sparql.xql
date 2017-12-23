xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "lib/sparql.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $qname {request:get-parameter('qname', '')};
declare variable $id {request:get-parameter('id', '')};

if($qname != '') then
    if($qname = 'related-subjects-count') then
        sprql-queries:related-subjects-count($id)
    else if($qname = 'related-citations-count') then
        sprql-queries:related-citations-count($id) 
    else if($qname = 'label') then
        sprql-queries:label($id) 
    else <message>Submitted query is not a valid Syriaca.org named query. Please use the qname paramater to submit a custom SPARQL query. {$qname}</message>
else if(request:get-parameter('sparql', '')) then
    sprql-queries:run-query(request:get-parameter('sparql', ''))
else if(not(empty(request:get-data()))) then 
    sprql-queries:run-query(request:get-data())
else <message>No query data submitted</message>
