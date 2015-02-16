xquery version "3.0";

import module namespace facets="http://syriaca.org//facets" at "facets.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $q {request:get-parameter('q', '') cast as xs:string?};

(:~
 : Build query string to pass to search.xqm 
:)
declare function local:query-string() as xs:string? {
 concat("collection('/db/apps/srophe/data')//tei:body",
    local:keyword-search(),
    facets:facet-filter()
    )
};

declare function local:keyword-search() as xs:string?{
    if($q != '') then concat("[ft:query(.,'",local:clean-string($q),"')]")
    else ()    
};

declare function local:clean-string($param-string as xs:string?) as xs:string?{
    replace(replace(replace($param-string, "(^|\W\*)|(^|\W\?)|[!@#$%^+=_]:", ""), '&amp;', '&amp;amp;'), '''', '&amp;apos;')
};

let $hits := util:eval(local:query-string())
return 
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <!-- Latest compiled and minified CSS -->
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css"/>
        
        <!-- Optional theme -->
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css"/>
        
        <!-- Latest compiled and minified JavaScript -->
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
    </head>
    <body style="margin:2em;">
        <h1>Facets demo:</h1>
        <div class="row">
           <div class="col-md-2">
               {
                let $facet-nodes := $hits
                let $facets := $facet-nodes//tei:persName | $facet-nodes//tei:placeName | $facet-nodes//tei:event
                return facets:facets($facets)
                (:facets:facets($facets):)
               }
           </div>
           <div class="col-md-10">
               {
               for $hit in $hits
               order by ft:score($hit) descending
               return 
               <div style="margin:.5em;border-bottom:1px solid #ccc;">{$hit}</div>
               }
           </div>
        </div>
    </body>
</html>