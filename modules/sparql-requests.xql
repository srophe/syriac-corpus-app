xquery version "3.1";

import module namespace http="http://expath.org/ns/http-client";
(:~
 : Take posted SPARQL query and send it to the Syriaca.org SPARQL endpoint
 : Returns JSON
:)
let $query := 
            if(request:get-parameter('query', '')) then  request:get-parameter('query', '') 
            else if(not(empty(request:get-data()))) then request:get-data()  
            else () 
let $results := 
    try{
        if($query != '') then 
            util:base64-decode(http:send-request(<http:request href="http://wwwb.library.vanderbilt.edu/exist/apps/srophe/api/sparql?format=json&amp;query={fn:encode-for-uri($query)}" method="get"/>)[2])
        else <message>No query data</message>
    } catch * {
        <error>Caught error {$err:code}: {$err:description}</error>
    } 
return (response:set-header("Content-Type", "application/json"), $results)
 