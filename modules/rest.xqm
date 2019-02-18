xquery version "3.0";

(: Syriaca.org restxq file. :)
module namespace api="http://syriaca.org/api";
(: Syriaca.org modules :)
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace cntneg="http://syriaca.org/srophe/cntneg" at "content-negotiation/content-negotiation.xqm";

(:eXist modules:)
import module namespace req="http://exquery.org/ns/request";

(: eXist SPARQL module for SPARQL endpoint, comment out if not using SPARQL module :)
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

(: For output annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Establish API endpoints :)

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as geoJSON
:)
declare
    %rest:GET
    %rest:path("/syriac-corpus/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:coordinates($type as xs:string*, $collection as xs:string*) {
    cntneg:content-negotiation(api:get-records-with-coordinates($type, $collection), 'geojson',())
};

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as KML
:)
declare
    %rest:GET
    %rest:path("/syriac-corpus/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:coordinates($type as xs:string*, $collection as xs:string*) {
    cntneg:content-negotiation(api:get-records-with-coordinates($type, $collection), 'kml',())
};

(:~
 : Search API, returns JSON
 : @param $element element to be searched. Accepts:
 :   persName,placeName,title,author,note,event,desc,location,idno
 : @param $collection see repo.xml for accepted values
 : @param $lang any valid ISO lang tag, most common in this collection: en, syr, ar, fr
 : @param $author accepts string value. May only be used when $element = 'title'     
:)
declare
    %rest:GET
    %rest:path("/syriac-corpus/api/search")
    %rest:query-param("q", "{$q}", "")
    %rest:query-param("element", "{$element}", "")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:query-param("author", "{$author}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("limit", "{$limit}", 25)
    %rest:header-param("Content-Type", "{$content-type}")
function api:search(
    $q as xs:string*, 
    $element as xs:string*, 
    $collection as xs:string*, 
    $lang as xs:string*, 
    $author as xs:string*, 
    $format as xs:string*,
    $start as xs:integer*,
    $limit as xs:integer*,
    $content-type as item()*
    ) {
    let $collection := if($collection != '') then concat("[.//tei:title = '",$collection,"']") else ()
    let $options :=                  
        "<options>
            <default-operator>and</default-operator>
            <phrase-slop>1</phrase-slop>
            <leading-wildcard>yes</leading-wildcard>
            <filter-rewrite>yes</filter-rewrite>
        </options>"                          
    let $lang := if($lang != '') then concat("[@xml:lang = '",$lang,"']") else ()
    let $author := if($author != '') then  concat("[ft:query(.//tei:author,'",$author,"',",$options,")]") else () 
    let $eval-string := if($element != '') then
                            concat("collection('",$global:data-root,"')//tei:TEI[ft:query(.//tei:",$element,",'",$q,"*',",$options,")]",$lang,$collection,$author)    
                        else concat("collection('",$global:data-root,"')//tei:TEI[ft:query(.//tei:body,'",$q,"*',",$options,")]",$lang,$collection,$author)    
    let $hits := if($q != '') then util:eval($eval-string) else <results-set>No query submitted</results-set>
    let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'json'
    let $results := 
        if($q != '') then
            <results-set>
                <id>0</id>
                <action>{$q}</action>
                <info>hits: {count($hits)}</info>
                <start>1</start>
                <results>
                    {
                        for $hit in subsequence($hits,$start,$limit)
                        let $id := replace($hit/descendant::tei:publicationStmt/descendant::tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei','')
                        let $kwic := util:expand($hit)                   
                        return
                        <result>
                            <id>{$id}</id>
                            {tei2html:output-kwic($kwic,$id)}
                        </result>
                    }
                </results>
            </results-set>
        else $hits
    return cntneg:content-negotiation($results, $request-format, ())
};

(:
 : SPARQL endpoint GET
 : @param $query SPARQL query
 : @param $format Format for results, json or xml
:)(:
declare
    %rest:GET
    %rest:path("/syriac-corpus/api/sparql")
    %rest:query-param("query", "{$query}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:header-param("Content-Type", "{$content-type}")
function api:coordinates($query as xs:string*, $format as xs:string*, $content-type as item()*) {
   let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
   return
   (<rest:response> 
        <http:response status="200"> 
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Access-Control-Allow-Methods" value="GET, POST"/>
        </http:response> 
      </rest:response>,sparql:query($query))
     (:cntneg:content-negotiation(sparql:query($query), $request-format,())):)
};
:)

(:
 : SPARQL endpoint POST 
 : NOTE having trouble with POST, using controller for SPARQL endpoint instead.
:)
(:
declare
    %rest:POST('{$data}')
    %rest:path("/syriac-corpus/api/sparql")
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-serialize($data as item()*, $content-type as item()*) {
   (<rest:response> 
        <http:response status="200"> 
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response> 
      </rest:response>,sparql:query($data))
};
:)

(:
 : Data dump for all records
 : @param $collection filter on collection - see repo-config.xml for collection names
 : @param $format -supported formats rdf/ttl/xml/html/json
 : @param $start
 : @param $limit
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:GET
    %rest:path("/syriac-corpus/api/data")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("limit", "{$limit}", 50)
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-dump(
    $type as xs:string*, 
    $collection as xs:string*, 
    $format as xs:string*, 
    $start as xs:integer*,
    $limit as xs:integer*,
    $content-type as item()*) {
    let $data := if($collection != '') then
                    collection($global:data-root || '/' || $collection)
                 else collection($global:data-root)
    let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
    return cntneg:content-negotiation(subsequence($data, $start, $limit), $request-format,())
};

(:
 : Data dump for any results set may be posted to this endpoint for serialization
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:POST('{$data}')
    %rest:path('/syriac-corpus/api/data/serialize')
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-serialize($data as item()*, $content-type as item()*) {
   cntneg:content-negotiation($data, $content-type,())
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @note extension is passed in with $page parameter, parsed out after .
  :)
declare
    %rest:GET
    %rest:path("/syriac-corpus/{$page}")
    %rest:header-param("Content-Type", "{$content-type}")
function api:get-page($page as xs:string?, $content-type as item()*) {
    let $path := concat('/',$page)      
    return  
        let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[1]/@record-URI-pattern,$page)
        let $data := if(api:get-tei($id) != '') then api:get-tei($id) else api:not-found($id)
        return cntneg:content-negotiation($data, $content-type, $path) 
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @param $extension record extension
  :)
declare
    %rest:GET
    %rest:path("/syriac-corpus/{$page}/{$extension}")
    %rest:header-param("Content-Type", "{$content-type}")
function api:get-page($page as xs:string?, $extension as xs:string, $content-type as item()*) {
    let $path := concat('/',$page,'.',$extension)
    return  
            let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[1]/@record-URI-pattern,$page)
            let $data := if(api:get-tei($id) != '') then api:get-tei($id) else api:not-found($id)
            return cntneg:content-negotiation($data, $extension, ()) 
}; 

(: Helper functions :)

(: Function to generate a 404 Not found response 
response:redirect-to()
:)
declare function api:not-found($path as xs:string?){
  (<rest:response>
    <http:response status="404" message="Not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <path>{$path}</path>
  (:<rest:forward>{ xs:anyURI(concat($global:nav-base, '/404.html')) }</rest:forward>:)
  )
};

(:~
 : Get TEI record based on $id
 : Builds full uri based on repo.xml
:)
declare function api:get-tei($id){
    collection($global:data-root)//tei:TEI[descendant::tei:idno[. = $id]]
};

(:~
 : Get all records with coordinates
 : @param $type 
 : @param $collection
 :)
declare function api:get-records-with-coordinates($type as xs:string*, $collection as xs:string*){
    if($type) then
        if(contains($type,',')) then 
            let $types := 
                if(contains($type,',')) then  string-join(for $type-string in tokenize($type,',') return concat('"',$type-string,'"'),',')
                else $type
            let $path := concat("collection('",$global:data-root,"/places/tei')//tei:place[@type = (",$types,")]//tei:geo") 
            for $recs in util:eval($path) 
            return $recs 
        else collection($global:data-root || "/places/tei")//tei:place[@type=$type]
    else collection($global:data-root || "/places/tei")//tei:geo/ancestor::tei:TEI
};