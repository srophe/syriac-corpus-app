xquery version "3.0";

module namespace api="http://syriaca.org/api";

(: Syriaca.org modules :)
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
import module namespace tei2ttl="http://syriaca.org/tei2ttl" at "lib/tei2ttl.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
import module namespace geojson="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace geokml="http://syriaca.org/geokml" at "lib/geokml.xqm";
import module namespace feed="http://syriaca.org/atom" at "lib/atom.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "lib/sparql.xqm";

(: eXistdb modules:)
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace req="http://exquery.org/ns/request";

(: Namespaces :)
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client";

(: Establish root directory for restxq :)
declare variable $api:repo {replace($global:app-root, '/db/apps/','')};


(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as JSON
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "json")
    %output:media-type("application/json")
    %output:method("json")
function api:get-geo-json($api:repo as xs:string?, $type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/json; charset=utf-8"/>
    <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/>
  </http:response> 
</rest:response>, 
     api:get-geojson-node($type,$output)
) 
};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as KML
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "kml")
    %output:media-type("application/vnd.google-earth.kmz")
    %output:method("xml")
function api:get-geo-kml($api:repo as xs:string?, $type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     api:get-geojson-node($type,$output) 
) 
};

(:~
 Search API, returns JSON
 @param $element element to be searched. Accepts:
    persName,placeName,title,author,note,event,desc,location,idno
 @param $collection see repo.xml for accepted values
  @param $lang accepts:
    en, syr, ar, syr-Syrj, grc, la, 
    fr, en-x-gedsh, de, fr-x-bhs, it, syr-Syrn, 
    el, ar-Syrc, eng, ara-syrc, lat, fr-x-zanetti,
    fr-x-fiey, fr-x-bhsyre, syr-Syrc, cop, es, 
    nl, hy, ka, cu, gez, ru, ru-Latn-iso9r95, syr-pal, 
    pt, sog, pl, el-Latn-iso843
  @param $author accepts string value. May only be used when $element = 'title'    
  @note - Still to do: 
    add disabmiguation information (dates for persNames)
    Add addtional format options? OAI,ATOM,TEI?
    Add general search option for all tei (body)
    NOTE make lang and collection accept multiple values. (rework xpath accept multiple values.) 
    May need to add distinct values
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/api/search/{$element}")
    %rest:query-param("q", "{$q}", "")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:query-param("author", "{$author}", "")
    %output:method("json")
function api:search-element($api:repo as xs:string?, $element as xs:string?, $q as xs:string*, $collection as xs:string*, $lang as xs:string*, $author as xs:string*){
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
    let $eval-string := concat("collection('",$global:data-root,"')//tei:TEI[ft:query(.//tei:",$element,",'",$q,"*',",$options,")]",$lang,$collection,$author)
    let $hits := util:eval($eval-string)
    return 
        if(count($hits) gt 0) then 
            <json:value>
                (
                    <id>0</id>,
                    <action>{$q}</action>,
                    <info>hits: {count($hits)}</info>,
                    <start>1</start>
               <results>
               {
                for $hit in $hits
                let $id := replace($hit/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
                let $dates := 
                    if($element = 'persName') then 
                        string-join($hit/descendant::tei:body/descendant::tei:birth/descendant-or-self::text() 
                        | $hit/descendant::tei:body/descendant::tei:death/descendant-or-self::text() | 
                        $hit/descendant::tei:body/descendant::tei:floruit/descendant-or-self::text(),' ')
                    else ()
                let $element-text := util:eval(concat("$hit//tei:",$element,"[ft:query(.,'",$q,"*',",$options,")]"))                   
                return
                        <json:value json:array="true">
                            <id>{$id}</id>
                            {for $e in $element-text 
                             return 
                                element {xs:QName($element)} { normalize-space(string-join($e//text(),' ')) }}
                            {if($dates != '') then <dates>{normalize-space($dates)}</dates> else ()}
                        </json:value>
                }
                </results>)
            </json:value>
        else   
            <json:value>
                <json:value json:array="true">
                    <id>0</id>
                    <action>1</action>
                    <info>No results</info>
                    <start>1</start>
                </json:value>
            </json:value>
};


(:~
  : SPARQL endpoint 
  : Serialized as XML
:)
declare
    %rest:POST("{$data}")
    %rest:path("/{$api:repo}/api/sparql")
    %rest:consumes("application/xml", "text/xml")
    %rest:produces("application/xml")
    %output:method("xml")
function api:sparql-endpoint($api:repo as xs:string?, $data as item()*){
     <received>{$data}</received>
};

(:~
  : SPARQL endpoint 
  : Serialized as XML
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/api/sparql-queries")
    %rest:query-param("qname", "{$qname}", "")
    %rest:query-param("id", "{$id}", "")
    %rest:consumes("application/xml", "text/xml")
    %rest:produces("application/xml")
    %output:method("xml")
function api:sparql-endpoint($api:repo as xs:string, $qname as xs:string*, $id as item()*){
  if(not(empty($qname))) then
    if($qname = 'related-subjects-count') then
        sprql-queries:related-subjects-count($id)
    else if($qname = 'related-citations-count') then
        sprql-queries:related-citations-count($id) 
    else if($qname = 'label') then
        sprql-queries:label($id) 
    else <message>Submitted query is not a valid Syriaca.org named query. Please use the q paramater to submit a custom SPARQL query</message>
  else <message>No query data submitted</message>
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @note extension is passed in with $page parameter, parsed out after .
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/{$folder}/{$page}")
function api:get-page($api:repo as xs:string, $folder as xs:string?, $page as xs:string?) {
    api:content-negotiation($folder, $page, ())
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @param $extension record extension
:)
declare
    %rest:GET
    %rest:path("/{$api:repo}/{$folder}/{$page}/{$extension}")
function api:get-page($api:repo as xs:string, $folder as xs:string?, $page as xs:string?,$extension as xs:string) {
    api:content-negotiation($folder, $page, $extension)
}; 

(: API helper functions :)
(: Used to do content negotiation. Inspired by https://github.com/baskaufs/guid-o-matic :)
declare function api:content-negotiation($folder as xs:string?, $page as xs:string?, $extension as xs:string?){
let $content := concat('../',$folder,'/',$page)
    let $work-uris := 
        distinct-values(for $collection in $global:get-config//repo:collection
        let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
        return replace($short-path,'/',''))
    return 
        if($folder = $work-uris) then 
            let $extension := if($extension != '') then $extension else substring-after($page,".")
            let $response-media-type := api:determine-media-type($extension)
            let $flag := api:determine-type-flag($extension)
            let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,$page)
            return
                if($flag = ('tei','xml')) then 
                    (<rest:response> 
                        <http:response status="200"> 
                          <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='xml'/>
                            <output:media-type value='text/xml'/>
                        </output:serialization-parameters>
                      </rest:response>,
                      api:get-tei($id))
                else if($flag = 'atom') then <message>atom</message>
                else if($flag = 'rdf') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                            <http:header name="media-type" value="application/xml"/>
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='xml'/>
                            <output:media-type value='application/xml'/>
                        </output:serialization-parameters>
                      </rest:response>, 
                      tei2rdf:rdf-output(api:get-tei($id)))
                else if($flag = 'turtle') then 
                     (<rest:response> 
                        <http:response status="200"> 
                              <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
                              <http:header name="method" value="text"/>
                              <http:header name="media-type" value="text/plain"/>
                        </http:response>
                        <output:serialization-parameters>
                            <output:method value='text'/>
                            <output:media-type value='text/plain'/>
                        </output:serialization-parameters>
                        </rest:response>, 
                        tei2ttl:ttl-output(api:get-tei($id)))
                else if($flag = 'geojson') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/json; charset=utf-8"/>
                            <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/> 
                        </http:response> 
                      </rest:response>, 
                      geojson:geojson(api:get-tei($id)))
                else if($flag = 'kml') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='xml'/>
                            <output:media-type value='application/xml'/>
                        </output:serialization-parameters>                        
                      </rest:response>, 
                      geokml:kml(api:get-tei($id)))
                else if($flag = 'json') then <message>json</message>
                else 
                    let $collection := $global:get-config//repo:collection[contains(@record-URI-pattern,concat('/',$folder))]/@app-root
                    let $html-path := concat('../',$global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@app-root,'/record.html') 
                    return 
                    (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='html5'/>
                            <output:media-type value='text/html'/>
                        </output:serialization-parameters>                        
                      </rest:response>,
                        api:render-html($html-path,$id))
                    (:    <message>{$content} collection path: {string($collection)} html path {$html-path} id {$id}</message>:)                                     
        else (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='html5'/>
                            <output:media-type value='text/html'/>
                        </output:serialization-parameters>                        
                      </rest:response>,api:render-html($content,''))
};

(:~
 : Get TEI record based on $id and $collection
 : Builds full uri based on repo.xml
:)
declare function api:get-tei($id){
  data:get-rec($id)
  (:root(collection($global:data-root)//tei:idno[. = $id]):)
};

(:~
 : Process HTML templating from within a RestXQ function.
:)
declare function api:render-html($content, $id as xs:string?){
    <div>This feature is in process, see tcadrt app for full implementation</div>
};

(: Function to generate a 404 Not found response :)
declare function api:not-found(){
  <rest:response>
    <http:response status="404" message="Not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

(: Utility functions to set media type-dependent values :)

(: Functions used to set media type-specific values :)
declare function api:determine-extension($header){
    if (contains(string-join($header),"application/rdf+xml")) then "rdf"
    else if (contains(string-join($header),"text/turtle")) then "ttl"
    else if (contains(string-join($header),"application/ld+json") or contains(string-join($header),"application/json")) then "json"
    else if (contains(string-join($header),"application/tei+xml")) then "tei"
    else if (contains(string-join($header),"text/xml")) then "tei"
    else if (contains(string-join($header),"application/atom+xml")) then "atom"
    else if (contains(string-join($header),"application/vnd.google-earth.kmz")) then "kml"
    else if (contains(string-join($header),"application/geo+json")) then "geojson"
    else "html"
};

declare function api:determine-media-type($extension){
  switch($extension)
    case "rdf" return "application/rdf+xml"
    case "tei" return "application/tei+xml"
    case "tei" return "text/xml"
    case "atom" return "application/atom+xml"
    case "ttl" return "text/turtle"
    case "json" return "application/ld+json"
    case "kml" return "application/vnd.google-earth.kmz"
    case "geojson" return "application/geo+json"
    default return "text/html"
};

(: NOTE: not sure this is needed:)
declare function api:determine-type-flag($extension){
  switch($extension)
    case "rdf" return "rdf"
    case "atom" return "atom"
    case "tei" return "xml"
    case "xml" return "xml"
    case "ttl" return "turtle"
    case "json" return "json"
    case "kml" return "kml"
    case "geojson" return "geojson"
    default return "html"
};

(:~
 : Build selects coordinates for geojson and kml output
:)
declare function api:get-geojson-node($type,$output){
let $geo-map :=
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
return
    if($output = 'json') then geojson:json-wrapper($geo-map)
    else geokml:kml($geo-map)
};