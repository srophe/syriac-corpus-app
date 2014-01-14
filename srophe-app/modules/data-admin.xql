xquery version "3.0";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $option {request:get-parameter('option', '')};
declare variable $editor {request:get-parameter('editor', '')};

(:~
 : Insert custom generated dates
 : Takes @notBefore, @notAfter, @to, @from, and @when and adds a syriaca computed date 
 : attribute for searching. 
 :)
                        
declare function local:add-custom-dates(){
   for $doc in collection('/db/apps/srophe/data/places/tei')//tei:place 
   return 
    (local:notAfter($doc),local:notBefore($doc),local:to($doc),local:from($doc),local:when($doc))                     
};

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
 : Edit as needed
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
             <location type="gps" source="#bib{$place-id}-{$bibNo}">
                    <geo>{concat($lat,' ',$long)}</geo>
             </location>
             <bibl xml:id="bib{$place-id}-{$bibNo}">
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
        for $place in collection('/db/apps/srophe/data/places/tei')/id($id)[1]
        let $place-id := substring-after($id,'place-')
        let $bibNo := count($place//tei:bibl) + 1
        let $lat := $places/Latitude
        let $long := $places/Longitude
        let $pleiades-id := string($places/Pleiades_ID)
        return (
             try {
                   (update insert 
                           <location xmlns="http://www.tei-c.org/ns/1.0" type="gps" source="#bib{$place-id}-{$bibNo}">
                             <geo>{concat($lat,' ',$long)}</geo>
                           </location>
                   following $place//tei:desc[last()],
                   update insert
                         <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$place-id}-{$bibNo}">
                           <title>http://pleiades.stoa.org/places/{$pleiades-id}</title>
                           <ptr target="http://pleiades.stoa.org/places/{$pleiades-id}"/>
                      </bibl>
                   following $place//tei:bibl[last()]
                   )
                 } catch * {
                     <p>{
                         (string($id), "Error:", $err:code)
                     }</p>
                 },
                local:add-change-log($place))
                
};
(:
NEEDS to be tested does not need a button
:)
declare function local:link-related-names(){
    for $place in collection('/db/apps/srophe/data/places/tei')//tei:place[@type='diocese']
    let $place-name := $place/tei:placeName[1]/text()
    let $place-id := $place/@xml:id
    return 
        for $place-rel in collection('/db/apps/srophe/data/places/tei')//tei:place[tei:placeName[1] = $place-name]
        let $place-rel-id := $place-rel/@xml:id
        let $place-rel-name := $place-rel/tei:placeName[1]/text()
        return
            <div>
                <p id="{$place-id}">{$place-name}</p>
                <p id="{$place-rel-id}">{$place-rel-name}</p>
            </div>
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
:)
declare function local:add-change-log($place){
(:/TEI/teiHeader/fileDesc/publicationStmt/date:)
       (update insert 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/editors.xml#{$editor}" when="{current-dateTime()}">ADDED: latitude and longitude from Pleiades</change>
          preceding $place/ancestor::*//tei:teiHeader/tei:revisionDesc/tei:change[1],
          update value $place/ancestor::*//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-dateTime()
          )
};

let $cache := 'cache'
(: Need to add a sucess message if no error codes. 
xmldb:get-current-user() 
:)
return <div>{local:link-related-names()}</div> 
(:
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
        <title>Data Admin</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <link rel="shortcut icon" href="/exist/apps/srophe/resources/images/favicon.ico"/>
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap.min.css"/>
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap-responsive.min.css"/>
        <link rel="stylesheet" type="text/css" href="/exist/apps/srophe/resources/css/style.css"/>
        <link rel="stylesheet" type="text/css" media="print" href="/exist/apps/srophe/resources/css/print.css"/>
        <script type="text/javascript" src="$shared/resources/scripts/loadsource.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/bootstrap.min.js"/>
        <script type="text/javascript" src="/exist/apps/srophe/resources/js/main.js"/>
        <script type="text/javascript" src="/exist/apps/srophe/resources/js/vendor/modernizr-2.6.2-respond-1.1.0.min.js"/>
        <script src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js" type="text/javascript"/>
        <script src="http://isawnyu.github.com/awld-js/awld.js?autoinit" type="text/javascript"/>
        <link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet-0.6.4/leaflet.css"/>
    </head>
    <body id="body">
        <div class="navbar navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a data-template="config:app-title" class="brand" href="/exist/apps/srophe/places/index.html">The Syriac Gazetteer: Data Admin</a>
                </div>
            </div>
        </div>
        <div id="content">
        <div class="row-fluid" style="margin:4em;">
            <div class="span12">
                <form>
                    <button type="text" name="option" value="dates" class="btn btn-info">Run Syriac Computed Dates</button>
                    <p class="text-info">
                        Inserts Syriac computed dates into data for search by date function.</p>
                   <div class="well" style="display:block; width:70%;font-size:.75em; margin:.5em 1em 1em; padding:.5em;">
                        Adds @syriac-computed-start generated from @when, @from, and @notBefore<br/>
                        Adds @syriac-computed-end generated from @to and @notAfter
                    </div>
                    <button type="text" name="option" value="pleiades-loc" class="btn btn-info">Insert Pleiades Location Data</button>
                    <p class="text-info">
                        Inserts Pleiades location data. Generated from /data/places/Pleiades-Grabber-Results-Edited.xml.</p>

<pre style="display:block; width:70%;font-size:.7em; margin:.5em;padding:.5em;">   &lt;location type="gps" source="#bibPLACEID-BIBNO"&gt;
        &lt;geo&gt;LAT LONG&lt;/geo&gt;
    &lt;/location&gt;
    &lt;bibl xml:id="bibPLACEID-BIBNO"&gt;
        &lt;title&gt;http://pleiades.stoa.org/places/PLEIADESID&lt;/title&gt;
        &lt;ptr target="http://pleiades.stoa.org/places/PLEIADESID"/&gt;
    &lt;/bibl&gt;
    &lt;change who="http://syriaca.org/editors.xml#EDITOR" when="CURRENT_DATE"&gt;
        ADDED: latitude and longitude from Pleiades
    &lt;/change&gt;
</pre>

                </form>
                {
                    if(exists($option) and $option = 'dates') then local:add-custom-dates()
                    else if(exists($option) and $option = 'pleiades-loc') then local:update-locations()
                    else ''
                }            
            </div>
        </div>
        </div>
        <div class="container-fluid">
            <div class="row-fluid">
                <div class="span10 offset1 text-center">
                    <p>
                        <a rel="license" href="http://creativecommons.org/licenses/by/3.0/deed.en_US">
                            <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by/3.0/80x15.png"/>
                        </a>
                        <br/>This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/deed.en_US">Creative Commons Attribution 3.0 Unported License</a>.
                        <br/>Copyright holding name(s) 2012.</p>.
                </div>
            </div>
        </div>
    </body>
</html>
:)