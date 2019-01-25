xquery version "3.0";

import module namespace http="http://expath.org/ns/http-client";

(:
 : Take posted SPARQL query and send it to Syriaca.org sparql endpoint
 : Returns JSON
 : This will hopefully get around the javascript issues with http/https and same origin.
:)
let $query := if(request:get-parameter('query', '')) then  request:get-parameter('query', '')
              else if(not(empty(request:get-data()))) then request:get-data()
              else ()
let $subject-sparql-results := 
    try{
        util:base64-decode(http:send-request(<http:request href="http://wwwb.library.vanderbilt.edu/exist/apps/srophe/api/sparql?format=json&amp;query={fn:encode-for-uri($query)}" method="get"/>)[2])
    } catch * {<error>Caught error {$err:code}: {$err:description}</error>}       
              
return (response:set-header("Content-Type", "application/json"),$subject-sparql-results)
 