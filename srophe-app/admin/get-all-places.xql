xquery version "3.0";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $option {request:get-parameter('option', '')};
declare variable $editor {request:get-parameter('editor', '')};
declare variable $comment {request:get-parameter('comment', '')};

(:~
 : Return all places for printing
 :)                       
declare function local:add-custom-dates(){
    for $recs in collection("/db/apps/srophe/data/places/tei") 
    return $recs                     
};
