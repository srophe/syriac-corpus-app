xquery version "3.0";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $option {request:get-parameter('option', '')};

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
            <div class="span12 offset">
                <form>
                    <p>Run Syriac Computed Dates to add @syriac-computed-start and @syriac-computed-end dates. </p>
                    <button type="text" name="option" value="dates" class="btn btn-info">Run Syriac Computed Dates</button>
                </form>
                {
                    if(exists($option) and $option = 'dates') then local:add-custom-dates()
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
