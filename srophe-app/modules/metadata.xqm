xquery version "3.0";

(:~
 : Provides html metadata. Passes data to page.html via config.xqm
 :)
module namespace metadata="http://syriaca.org//metadata";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $metadata:id {request:get-parameter('id', '')};

(:~
 : Builds page title
 : If id parameter is present use place data to generate title
 : Otherwise build based on page url
 : @param $metadata:id gets place id from url
 :)
declare function metadata:get-title($node, $model){
    for $title in tokenize(request:get-uri(), '/')[last()]
    return
     if (starts-with($title,'place')) then place:get-place-title()
     else if(starts-with($title,'index')) then 'The Syriac Gazetteer'
     else concat('The Syriac Gazetteer: ',substring-before($title,'.html'))
};

(:~
 : Builds Dublin Core metadata
 : If id parameter is present use place data to generate metadata
 : @param $metadata:id gets place id from url
 :) 
declare function metadata:get-dc-metadata(){
    if(exists($metadata:id)) then place:get-metadata()
    else ''
};
