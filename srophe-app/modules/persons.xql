(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace persons="http://syriaca.org//persons";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $persons:id {request:get-parameter('id', '')};

(:~
 : Retrieve persons record
 : Adds persons data to map function
 : @param $id persons id
 :)
declare function persons:get-persons($node as node(), $model as map(*)){
    let $personsid := concat('person-',$persons:id)
    for $recs in collection($config:app-root || "/data/persons/tei")/id($personsid)
    let $rec := $recs/ancestor::tei:TEI
    return map {"persons-data" := $rec}
};

(:~ 
 : Pull together persons page data   
 : Adds related persons and nested locations to full TEI document
 : Passes xml to persons page.xsl for html transformation
:)
declare %templates:wrap function persons:get-persons-data($node as node(), $model as map(*)){
   for $rec in $model("persons-data")
   let $buildRec :=
                <TEI
                    xml:lang="en"
                    xmlns:xi="http://www.w3.org/2001/XInclude"
                    xmlns:svg="http://www.w3.org/2000/svg"
                    xmlns:math="http://www.w3.org/1998/Math/MathML"
                    xmlns="http://www.tei-c.org/ns/1.0">
                    {
                        $rec/child::*
                    }
                    </TEI>
    let $cache :='Change value to force page refresh 90066887963'
    return
       (: $buildRec:)
       transform:transform($buildRec, doc('../resources/xsl/personspage.xsl'),() )
};
