xquery version "3.0";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";


(: update insert attribute when-custom {'{xs:date($date-norm)}'} into $date 
when-custom
to-custom
from-custom
notBefore-custom
notAfter-custom
:)
                        
declare function local:add-custom-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
   (:add test for when-custom so I don't add it repeatedly:)
        for $date in $doc/descendant-or-self::*/@notAfter
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@notAfter-custom]) then 'exists'
              else   try {
                        update insert attribute notAfter-custom {xs:date($date-norm)} into $date/parent::*
                     } catch * {
                         <date>{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }

};

declare function local:remove-attributes(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
   (:add test for when-custom so I don't add it repeatedly:)
        for $date in $doc/descendant-or-self::*/@when-custom
        return update delete $date

};

declare function local:test-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
        for $date in $doc/descendant-or-self::*/@notAfter-custom
        return 
            <date>{$date}</date>
};

let $cache := 'cache'
return 
<div>
    {local:test-dates()}
</div>