xquery version "3.0";

module namespace item="http://localhost:8080/exist/apps/srophe/item";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://localhost:8080/exist/apps/srophe/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 :  Get place record use id parameter passed from url
 :)
declare function item:get-place($node as node(), $model as map(*), $id as xs:string){
     map { "place-data" := collection($config:app-root || "/data/places/tei")/tei:body/tei:text/tei:listPlace/tei:place[substring-after(@xml:id,'place-') = $id] }
};

declare %templates:wrap function item:get-place-data($node as node(), $model as map(*)){ 
    for $place in $model("place-data")
    return $place
};
