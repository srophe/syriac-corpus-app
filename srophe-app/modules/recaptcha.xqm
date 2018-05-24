xquery version "3.1";

module namespace recap="http://www.exist-db.org/xquery/util/recapture";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare variable $recap:VALIDATE_URI as xs:anyURI := xs:anyURI("https://www.google.com/recaptcha/api/siteverify");

(:~
: Module for working with reCaptcha
:)
declare function recap:validate($private-key as xs:string, $recaptcha-response as xs:string) 
{
let $client-ip := request:get-header("X-Real-IP") 
let $response := http:send-request(<http:request http-version="1.1" href="{xs:anyURI($recap:VALIDATE_URI)}" method="post">
                                        <http:body media-type="application/x-www-form-urlencoded">secret={$private-key}&amp;response={$recaptcha-response}&amp;remoteip={$client-ip}
                                        </http:body>
                                    </http:request>)[2]
let $payload := util:base64-decode($response)
(:  :let $json-data := parse-json($payload):)
return if(string(contains($payload,'success: true'))) then true()
       else false()
(: 
    if($json-data?success = true()) then true()
    else (:false():)$payload:)
};