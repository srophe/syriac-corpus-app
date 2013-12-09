xquery version "3.0";

module namespace app="http://syriaca.org//templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 http://syriaca.org/feed/
 :)
 


declare %templates:wrap function app:get-feed($node as node(), $model as map(*)){ 
   let $news := doc('http://syriaca.org/feed/')/child::*
   for $latest at $n in subsequence($news//item, 1, 5)
   return 
   <li>
        <a href="{$latest/link/text()}">{$latest/title/text()}</a> [{$latest/pubDate}]
   </li>
};