xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)

module namespace nav="http://syriaca.org//nav";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~
 : Builds nav 
 : If id parameter is present use place data to generate title
 : Otherwise build based on page url
 : @param $metadata:id gets place id from url                  
 :) 
declare function nav:build-nav($node as node(), $model as map(*)){
    for $active-page in tokenize(request:get-uri(), '/')[last()]
    return
     if (contains(request:get-uri(),'help')) then 
        (<a data-template="config:app-title" class="brand" href="../index.html">The Syriac Gazetteer</a>,
        <ul class="nav">
            <li><a href="../browse.html">index</a></li>
            <li><a href="../about.html">about</a></li>
            <li class="active"><a href="index.html">help</a></li>
        </ul>)
     else if (starts-with($active-page,'browse')) then
      (<a data-template="config:app-title" class="brand" href="index.html">The Syriac Gazetteer</a>,
        <ul class="nav">
            <li class="active"><a href="browse.html">index</a></li>
            <li><a href="about.html">about</a></li>
            <li><a href="help/index.html">help</a></li>
        </ul>)
     else if(starts-with($active-page,'about')) then 
      (<a data-template="config:app-title" class="brand" href="index.html">The Syriac Gazetteer</a>,
         <ul class="nav">
             <li><a href="browse.html">index</a></li>
             <li class="active"><a href="about.html">about</a></li>
             <li><a href="help/index.html">help</a></li>
         </ul>)
     else 
      (<a data-template="config:app-title" class="brand" href="index.html">The Syriac Gazetteer</a>,
        <ul class="nav">
            <li><a href="browse.html">index</a></li>
            <li><a href="about.html">about</a></li>
            <li><a href="help/index.html">help</a></li>
        </ul>)
};
