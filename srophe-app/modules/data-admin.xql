xquery version "3.0";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";


(: update insert attribute when-custom {'{xs:date($date-norm)}'} into $date 
check to see which dates should be searched on. All?
when
to
from
notBefore
notAfter

syriaca-computed-to
add changes to change log at bottom of tei
:)
                        
declare function local:add-custom-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place 
   return 
    (local:notAfter($doc),local:notBefore($doc),local:to($doc),local:from($doc),local:when($doc))                     
};

declare function local:notAfter($doc){
        for $date in $doc/descendant-or-self::*/@notAfter
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-end]) then 'exists'
              else   try {
                        (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*, 'added')
                     } catch * {
                         <date>{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
                     
};

declare function local:notBefore($doc){
        for $date in $doc/descendant-or-self::*/@notBefore
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*, 'added')
                     } catch * {
                         <date>{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

declare function local:to($doc){
        for $date in $doc/descendant-or-self::*/@to
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-end]) then 'exists'
              else   try {
                        (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*, 'added')
                     } catch * {
                         <date>{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

declare function local:from($doc){
        for $date in $doc/descendant-or-self::*/@from
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*, 'added')
                     } catch * {
                         <date>{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

declare function local:when($doc){
        for $date in $doc/descendant-or-self::*/@when
        let $date-norm := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*, 'added')
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
        for $date in $doc/descendant-or-self::*/@from-custom
        return update delete $date

};
(:
descendant::tei:event[@type != "attestation"][@syriaca-computed-start
:)
declare function local:test-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
        for $date in $doc/descendant-or-self::tei:state[@type = "confession"]
        return 
            <date parent="{$doc/tei:placeName[@xml:lang='en'][1]}">{$date}</date>
};

let $cache := 'cache'
return 
<div>
<p>show</p>
    {local:test-dates()}
</div>