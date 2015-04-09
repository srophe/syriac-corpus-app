xquery version "3.0";

module namespace sutil="http://srophe.org/ns/srophe-util";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $sutil:resource-uri {request:get-parameter('resource', '')};

(:~
 : Insert custom generated dates
 : Takes @notBefore, @notAfter, @to, @from, and @when and adds a syriaca computed date attribute for searching.
 : @param $resource-uri path to resource or collection  
 :)    
 (:
declare function sutil:add-custom-dates(){
   if(ends-with($sutil:resource-uri),'.xml') then sutil:custom-dates-doc($sutil:resource-uri)
   else sutil:custom-dates-coll($sutil:resource-uri)
                            
};
:)
declare function sutil:custom-dates-coll($resource-uri, $comment, $editor){
for $doc in collection('/db/apps/srophe/data/spear/tei')//tei:body 
return 
    (
            sutil:notAfter($doc),
            sutil:notBefore($doc),
            sutil:to($doc),
            sutil:from($doc),
            sutil:when($doc),
            if(sutil:notAfter($doc) = 'success') then
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:notBefore($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:to($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:from($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:when($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else () 
    ) 
};

declare function sutil:custom-dates-doc($resource-uri, $comment, $editor){
for $doc in doc($resource-uri)//tei:body 
return 
    (
            sutil:notAfter($doc),
            sutil:notBefore($doc),
            sutil:to($doc),
            sutil:from($doc),
            sutil:when($doc),
            if(sutil:notAfter($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:notBefore($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:to($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:from($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else if(sutil:when($doc) = 'success') then 
                sutil:add-change-log($doc,$comment, $editor)
            else ()    
    ) 
};

(:~
 : Take data from @notAfter, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
 : @param $doc document node
:)
declare function sutil:notAfter($doc){
    for $date in $doc/descendant-or-self::*/@notAfter
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-end]) then 'exists'
        else   
            try {
                    (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*,'success')
                } 
            catch * 
                {
                    <date place="{$doc/@xml:id}">{(string($date-norm), "Error:", $err:code)}</date>
                }     
};

(:~
 : Take data from @notBefore, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
 : @param $doc document node
:)
declare function sutil:notBefore($doc){
    for $date in $doc/descendant-or-self::*/@notBefore
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @to, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
 : @param $doc document node
:)
declare function sutil:to($doc){
    for $date in $doc/descendant-or-self::*/@to
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-end]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @from, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
 : @param $doc document node
:)
declare function sutil:from($doc){
    for $date in $doc/descendant-or-self::*/@from
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*,'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Take data from @when, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
:)
declare function sutil:when($doc){
    for $date in $doc/descendant-or-self::*/@when
    let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
    return 
        if($date[@syriaca-computed-start]) then 'exists'
        else   try {
                        (update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*, 'success')
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~
 : Insert new change element and change publication date
 : @param $editor from form and $comment from form
 : ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
 : ADDED: latitude and longitude from Pleiades
:)
declare function sutil:add-change-log($doc, $comment, $editor){
       (update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#wsalesky" when="{current-date()}">
                ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
            </change>
          preceding $doc/ancestor::*//tei:teiHeader/tei:revisionDesc/tei:change[1],
          update value $doc/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
          )
};
