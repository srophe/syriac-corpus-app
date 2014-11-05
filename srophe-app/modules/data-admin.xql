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
 : Insert custom generated dates
 : Takes @notBefore, @notAfter, @to, @from, and @when and adds a syriaca computed date 
 : attribute for searching.  
 :)                       
declare function local:add-custom-dates(){
   for $doc in collection('/db/apps/srophe/data/persons/tei')//tei:person 
   return 
    (local:notAfter($doc),local:notBefore($doc),local:to($doc),local:from($doc),local:when($doc),local:add-change-log($doc))                     
};
(:~
 : Take data from @notAfter, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
:)
declare function local:notAfter($doc){
        for $date in $doc/descendant-or-self::*/@notAfter
        let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-end]) then 'exists'
              else   try {
                        update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
                     
};
(:~
 : Take data from @notBefore, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
:)
declare function local:notBefore($doc){
        for $date in $doc/descendant-or-self::*/@notBefore
        let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};
(:~
 : Take data from @to, check for existing @syriaca-computed-end
 : if none, format date and add @syriaca-computed-end as xs:date
:)
declare function local:to($doc){
        for $date in $doc/descendant-or-self::*/@to
        let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-end]) then 'exists'
              else   try {
                        update insert attribute syriaca-computed-end {xs:date($date-norm)} into $date/parent::*
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};
(:~
 : Take data from @from, check for existing @syriaca-computed-start
 : if none, format date and add @syriaca-computed-start as xs:date
:)
declare function local:from($doc){
        for $date in $doc/descendant-or-self::*/@from
        let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*
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
declare function local:when($doc){
        for $date in $doc/descendant-or-self::*/@when
        let $date-norm := if(starts-with($date,'0000') and string-length($date) eq 4) then '0001-01-01'
                          else if(string-length($date) eq 4) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                          else if(string-length($date) eq 7) then concat(string($date),'-01')
                          else string($date)
              return 
              (: $date-norm castable as xs:date :)
              if($date[@syriaca-computed-start]) then 'exists'
              else   try {
                        update insert attribute syriaca-computed-start {xs:date($date-norm)} into $date/parent::*
                     } catch * {
                         <date place="{$doc/@xml:id}">{
                             (string($date-norm), "Error:", $err:code)
                         }</date>
                     }
};

(:~ 
 : General function to remove attributes. 
 : Edit as needed, no public interface for this function 
:)
declare function local:remove-attributes(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
   (:add test for when-custom so I don't add it repeatedly:)
        for $date in $doc/descendant-or-self::*/@from-custom
        return update delete $date
};

(:~
 : General test function to inspect current dates
 : No public interface for this function
:)
declare function local:test-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place
   return 
        for $date in $doc/descendant-or-self::tei:state[@type = "confession"]
        return 
            <date parent="{$doc/tei:placeName[@xml:lang='en'][1]}">{$date}</date>
};

(: Add location data from Pleiades.xml 
 May not need a button for this, as it is a one time operation (in theory)
:)
(:~ Test data, uncomment to test
        <div>
             <location type="gps" source="#bib{$doc-id}-{$bibNo}">
                    <geo>{concat($lat,' ',$long)}</geo>
             </location>
             <bibl xml:id="bib{$doc-id}-{$bibNo}">
                  <title>http://pleiades.stoa.org/places/{$pleiades-id}</title>
                  <ptr target="http://pleiades.stoa.org/places/{$pleiades-id}"/>
             </bibl>
             <change who="http://syriaca.org/editors.xml#{$editor}" when="{current-dateTime()}">ADDED: latitude and longitude from Pleiades</change>
        </div>
:)
declare function local:update-locations(){
    for $places in doc('/db/apps/srophe/data/places/Pleiades-Grabber-Results-Edited.xml')//row[Match='UPDATED']
    let $id := concat('place-',$places/Place_ID)
    return 
        for $doc in collection('/db/apps/srophe/data/places/tei')/id($id)[1]
        let $doc-id := substring-after($id,'place-')
        let $bibNo := count($doc//tei:bibl) + 1
        let $lat := $places/Latitude
        let $long := $places/Longitude
        let $pleiades-id := string($places/Pleiades_ID)
        return (
             try {
                   (update insert 
                           <location xmlns="http://www.tei-c.org/ns/1.0" type="gps" source="#bib{$doc-id}-{$bibNo}">
                             <geo>{concat($lat,' ',$long)}</geo>
                           </location>
                   following $doc//tei:desc[last()],
                   update insert
                         <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$doc-id}-{$bibNo}">
                           <title>http://pleiades.stoa.org/places/{$pleiades-id}</title>
                           <ptr target="http://pleiades.stoa.org/places/{$pleiades-id}"/>
                      </bibl>
                   following $doc//tei:bibl[last()]
                   )
                 } catch * {
                     <p>{
                         (string($id), "Error:", $err:code)
                     }</p>
                 },
                local:add-change-log($doc),<p>{$doc-id}</p>)
                
};
(:
NEEDS to be tested does not need a button
Checking list to make sure it is correct before adding to data Will need to update fresh data to dev and run it.
        if(count(local:related-data($doc-id,$doc-name)) gt 0) then 
             <relation name="shares-name-with" mutual="#{(substring-after($doc-id,'place-'), local:related-data($doc-id,$doc-name))}"/>       
         else ''
:)

declare function local:related-data($doc-id,$doc-name){
    for $doc-rel in collection('/db/apps/srophe/data/places/tei')//tei:place[tei:placeName[@syriaca-tags='#syriaca-headword'] = $doc-name]
    let $doc-rel-id := $doc-rel/@xml:id
    let $doc-rel-name := $doc-rel/text()
    where not($doc-rel-id = $doc-id)
    return 
        concat(' http://syriaca.org/place/',substring-after($doc-rel-id,'place-')) 
};

declare function local:link-related-names(){
    let $docs-all := for $docs in collection('/db/apps/srophe/data/places/tei')//tei:place[tei:placeName[@syriaca-tags='#syriaca-headword']] return $docs
    for $doc at $p in subsequence($docs-all, 2600, 100)
    let $doc-name := $doc/tei:placeName[@syriaca-tags='#syriaca-headword'][1]/text()
    let $doc-id := $doc/@xml:id
    return 
        if(count(local:related-data($doc-id,$doc-name)) gt 0) then 
            (update insert 
                <relation xmlns="http://www.tei-c.org/ns/1.0" name="shares-name-with" mutual="#place{(substring-after($doc-id,'place-'), local:related-data($doc-id,$doc-name))}"/>
            following $doc, local:add-change-log($doc),<p>{$doc-id}</p>)       
         else ''
};          

(: 
  need to add in function to select who you are, add in latest date
    /TEI/teiHeader/fileDesc/publicationStmt/date
   test and add buttons 
   need to add a general form for selecting who is editing, and adding a comment to change log.
   needs to popup after submit, and before action is taken?
   save for later
:)

(:~
 : Insert new change element and change publication date
 : @param $editor from form and $comment from form
 : ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching
 : ADDED: latitude and longitude from Pleiades
:)
declare function local:add-change-log($doc){
(:/TEI/teiHeader/fileDesc/publicationStmt/date:)
       (update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#{$editor}" when="{current-date()}">
                {$comment}
            </change>
          preceding $doc/ancestor::*//tei:teiHeader/tei:revisionDesc/tei:change[1],
          update value $doc/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date()
          )
};

declare function local:remove-mutual(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:relation
   let $mutual := string($doc/@mutual)
   let $new-mutual-end := substring-after($mutual,' ')
   let $new-mutual-beging := substring-before(substring-after($mutual,'place'),' ')
   let $new-mutual := concat('#place-',$new-mutual-beging,' ',$new-mutual-end)
   where $doc[@name='shares-name-with']
   return
    (update value $doc/@name with 'share-a-name', update value $doc/@mutual with $new-mutual)

   
};

declare function local:change-computed-dates(){
for $doc in collection('/db/apps/srophe/data/persons/tei')//tei:person[descendant-or-self::*/@when]
return local:add-change-log($doc)
    
};

(: remove computed start and computed end replace negitive dates:)
let $cache := 'cache'
(: Need to add a sucess message if no error codes.

(session:create(),
xmldb:login('/db/apps/srophe/', 'admin', '', true()))

xmldb:get-current-user() 

local:add-custom-dates()
ADDED: syriaca-computed-start and syriaca-computed-end attributes for searching

local:update-locations()
ADDED: latitude and longitude from Pleiades

This one is run with paging because it is too memory intensive otherwise
local:link-related-names()
ADDED: relation element with shares-name-with attribute for all place headwords that share names
:)
return  
(:<div>You do not have permission to run this query</div>:)
(xmldb:login('/db/apps/srophe/', 'admin', '', true()),local:add-custom-dates())
