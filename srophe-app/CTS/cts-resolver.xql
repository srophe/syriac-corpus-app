xquery version "3.1";

(:~
 : Bare-bones resolution service for CTS URNs for Syriaca.org and The Oxford-BYU Syriac Corpus
 : @author Syriaca.org
 : @param $urn The CTS URN to be resolved.
 : @param $action The return type. 
    Available actions: 
        - 'html' [Returns the html referenced text block]
        - 'xml' [Returns the xml referenced text block]
        - 'redirect' [Sends users to HTML page]
 :)
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace http="http://expath.org/ns/http-client";
declare namespace html="http://www.w3.org/1999/xhtml";
declare option exist:serialize "method=html5 media-type=text/html";

declare variable $cts-registry := doc('cts-registry.xml');

(: Note, we may want to retain a 'registry' for namespaces, either in xml or json :)
(: Get base URL from namespace resolver :)
declare function local:resolve-namespace($ref as xs:string?){
let $namespace := tokenize($ref,':')[3]
return 
    if($cts-registry//namespace[@value = $namespace]) then
        string($cts-registry//namespace[@value = $namespace]/@resolvesTo)
    else <error>ERROR: Failed to resolve namespace {$namespace}. No matching repository in the Syriaca.org registry.</error>
    (:
    if($namespace = 'syriacLit') then (:'http://syriaccorpus.org/':) 'http://localhost:8080/exist/apps/syriac-corpus/'
    else <error>ERROR: Failed to resolve namespace {$namespace}. No matching repository in the Syriaca.org registry.</error>
    :)
};

(:~ 
 : Uses cts registry.xml to resolve base uris to actionable urls 
 : @param $repo the part of the CTS URN representing the repository
 :)
declare function local:resolve-base-uri($repo as xs:string?){
    if($cts-registry//workIdentifiers[@value = $repo]) then
        string($cts-registry//workIdentifiers[@value = $repo]/@resolvesTo)
    else <error>ERROR: Failed to resolve base uri {$repo}. No matching repository in the Syriaca.org registry. </error>
};

(:~
 : Resolve the final part of the urn, the passage reference
 : @param $ref the full urn
:)
declare function local:resolve-passage($ref){
let $passage := tokenize($ref,':')[5]
return
    if($passage != '') then 
        concat('#id.',replace($passage,'@','.')) 
    else ()
};

(:~
 : Build the request url
 : @param $ref the full urn
:)
declare function local:build-request($ref){
let $work := tokenize($ref,':')[4]
let $workref := tokenize($work,'\.')[last()]
let $repo := replace(replace($workref,'(\D*)(\d*)','$1'),'\s','')
let $idno := replace($workref,'(\D*)(\d*)','$2')
let $url := concat(local:resolve-base-uri($repo),$idno,local:resolve-passage($ref))
return 
    (: Will need error handling :)
    if($repo = 'nhsl') then concat(local:resolve-namespace($ref),'search.html?nhsl-edition=',$url)
    else if($repo = 'bibl') then concat(local:resolve-namespace($ref),'search.html?bibl-edition=',$url)  
    else concat(local:resolve-namespace($ref),tokenize($url,'/')[4]) 
 
};

let $ref := request:get-parameter("urn",())
let $action := request:get-parameter("action",())
let $passage := replace(local:resolve-passage($ref),'#','')
return 
    if($action = 'html') then
        try {
            let $rec := http:send-request(<http:request http-version="1.1" href="{xs:anyURI(local:build-request($ref))}" method="get"/>)[2]
            return 
                (: Note, switch id's around in xslt so id="Head-id.1" is in an empty span (for toc) and the real id is the surrounding div. for cts:)
                if($passage != '') then $rec//*[@id = $passage]/parent::*[1]
                else $rec//html:div[@class="body"]
            } catch *{
                 <response status="fail">
                     <message>Failed find resource: {concat($err:code, ": ", $err:description)}</message>
                 </response>
        }
    else if($action = 'xml') then
        try {
            let $url := local:build-request($ref)
            let $url := if(contains($url,'#')) then concat(substring-before($url,'#'),'/tei') else concat($url,'/tei')
            let $rec := http:send-request(<http:request http-version="1.1" href="{xs:anyURI($url)}" method="get"/>)[2]
            return (:('URL ',$url, ' Passage: ',$passage, ' pid:',substring-after($passage,'.')):)
                if($passage != '') then $rec//*[@n = substring-after($passage,'.')]
                else $rec
            } catch *{
                 <response status="fail">
                     <message>Failed find resource: {concat($err:code, ": ", $err:description)}</message>
                 </response>
        }                
    else if($ref != '') then 
        try {
                 response:redirect-to(local:build-request($ref))
        } catch *{
                 <response status="fail">
                     <message>Failed find resource: {concat($err:code, ": ", $err:description)}</message>
                 </response>
        }
       
    else <error>ERROR: no data recieved. </error>
    
(: TEST records
let $t1 := 'urn:cts:syriacLit:nhsl8501'
let $t2 := 'urn:cts:syriacLit:nhsl8501.nhsl8503'
let $t3 := 'urn:cts:syriacLit:nhsl8501.nhsl8503.syriacCorpus1'
let $t4 := 'urn:cts:syriacLit:nhsl8501.nhsl8503.syriacCorpus1:3.5'
let $t5 := 'urn:cts:syriacLit:nhsl70.nhsl75.syriacCorpus121:5@10'
rn:cts:syriacLit:nhsl70.nhsl75.syriacCorpus121:4.10
let $t6 := 'urn:cts:syriacLit:nhsl8528.nhsl8602.bibl1765'
let $t6alt := 'urn:cts:syriacLit:nhsl8528.nhsl8602.bibl1765 = urn:cts:syriacLit:nhsl8528.nhsl8602.syriacCorpus101'
:)
