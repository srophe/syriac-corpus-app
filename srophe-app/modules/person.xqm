(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace person="http://syriaca.org//person";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $person:id {request:get-parameter('id', '')};

(:~
 : Retrieve persons record
 : Adds persons data to map function
 : @param $id persons id
 :)
declare function person:get-persons($node as node(), $model as map(*)){
    let $personsid := concat('person-',$person:id)
    for $recs in collection($config:app-root || "/data/persons/tei")/id($personsid)
    let $rec := $recs/ancestor::tei:TEI
    return map {"persons-data" := $rec}
};

(:~
 : Get related items     
:)
declare function person:get-related-places($rec as node()*){
    <related-items>
        {
            for $related in $rec//tei:relation 
            let $item-uri := string($related/@passive)
            let $desc := $related/tei:desc
            return 
                <relation uri="{$item-uri}">
                    {(for $att in $related/@*
                      return attribute {name($att)} {$att},
                        for $rel-item in collection($config:app-root || "/data")//tei:idno [. = $item-uri]
                        let $title := $rel-item/ancestor::tei:TEI//tei:titleStmt/tei:title[1]
                        return 
                            <item uri="{$item-uri}">{$title}</item>
                           ,
                           $desc
                           
                       )
                    }
                </relation>    
        }
     </related-items> 
};      
(:~ 
 : Pull together persons page data   
 : Adds related persons and nested locations to full TEI document
 : Passes xml to persons page.xsl for html transformation
:)
declare %templates:wrap function person:get-persons-data($node as node(), $model as map(*)){
   for $rec in $model("persons-data")
   let $buildRec :=
                <TEI
                    xml:lang="en"
                    xmlns:xi="http://www.w3.org/2001/XInclude"
                    xmlns:svg="http://www.w3.org/2000/svg"
                    xmlns:math="http://www.w3.org/1998/Math/MathML"
                    xmlns="http://www.tei-c.org/ns/1.0">
                    {
                       ($rec/child::*,person:get-related-places($rec) )
                    }
                    </TEI>
    let $cache :='Change value to force page refresh 90068'
    return
        (:$buildRec:)
       transform:transform($buildRec, doc('../resources/xsl/personspage.xsl'),() )
};
