xquery version "3.0";

module namespace places="http://syriaca.org//places";
import module namespace search-form="http://syriaca.org//search-form" at "search-form.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $places:q {request:get-parameter('q', '')};
declare variable $places:p {request:get-parameter('p', '')};
declare variable $places:type {request:get-parameter('type', '')};

declare variable $places:loc {request:get-parameter('loc', '')};
declare variable $places:lat {request:get-parameter('lat', '')};
declare variable $places:long {request:get-parameter('long', '')};

declare variable $places:e {request:get-parameter('e', '')};
declare variable $places:eds {request:get-parameter('eds', '')};
declare variable $places:ede {request:get-parameter('ede', '')};

declare variable $places:a {request:get-parameter('a', '')};
declare variable $places:ads {request:get-parameter('ads', '')};
declare variable $places:ade {request:get-parameter('ade', '')};

declare variable $places:c {request:get-parameter('c', '')};
declare variable $places:cds {request:get-parameter('cds', '')};
declare variable $places:cde {request:get-parameter('cde', '')};

declare variable $places:exist {request:get-parameter('exist', '')};
declare variable $places:existds {request:get-parameter('existds', '')};
declare variable $places:existde {request:get-parameter('existde', '')};

declare variable $places:en {request:get-parameter('en', '')};
declare variable $places:syr {request:get-parameter('syr', '')};
declare variable $places:ar {request:get-parameter('ar', '')};

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
:)
declare function places:clean-string($param-string){
    replace ($param-string, "[&amp;&quot;!@#$%^+=_]", "")
};

(:~
 : Build full-text keyword search over all tei:place data
 : @q full text query
 descendant-or-self::* or . testing which is most correct
 
:)
declare function places:keyword(){
    if(exists($places:q) and $places:q != '') then concat('[ft:query(descendant-or-self::*,"',places:clean-string($places:q),'")]')
    else ''    
};

(:~
 : Build full-text keyword search over all tei:placeName data
 : @p full text query
:)
declare function places:place-name(){
    if(exists($places:p) and $places:p != '') then concat('[ft:query(tei:placeName,"',places:clean-string($places:p),'")]')
    else ''    
};

(:~
 : Build range search on tei:place/@type data
 : @type full text query
:)
declare function places:type(){
    if(exists($places:type) and $places:type != '') then string(concat('[@type = "',places:clean-string($places:type),'"]'))
    else '' 
};

(:~
 : Build full-text search on tei:place/tei:location data
 : @loc full text query
 : NOTE: need to understand location search better. 
:)
declare function places:location(){
    if(exists($places:loc) and $places:loc != '') then concat('[ft:query(tei:location,"',places:clean-string($places:loc),'")]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type != attestation] data
 NOTE: will probably have to build this into the date range, so they hold together as one AND predicate
 : @e full text query
:)
declare function places:event(){
    if(exists($places:e) and $places:e != '') then concat('[ft:query(tei:event[@type != "attestation" or not(@type)],"',places:clean-string($places:e),'")]')
    else ''
};

(:~
 : Build date range for event 
 : tei:event[@type != attestation]
 : @eds event start range index
 : @ede event end range index
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][(@syriaca-computed-start gt "',places:do-date($places:eds),'" and @syriaca-computed-end lt "',places:do-date($places:ede),'") or (@syriaca-computed-start gt "',places:do-date($places:eds),'" and not(@syriaca-computed-end))]]')
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',places:do-date($places:eds),'"]]')
:)
declare function places:event-dates(){
    if(exists($places:eds) and $places:eds != '') then 
        if(exists($places:ede) and $places:ede != '') then 
            concat('[descendant::tei:event[@type != "attestation" or not(@type)]
            [(
            @syriaca-computed-start gt 
                "',places:do-date($places:eds),'" 
                and @syriaca-computed-end lt 
                "',places:do-date($places:ede),'"
                ) or (
                @syriaca-computed-start gt 
                "',places:do-date($places:eds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',places:do-date($places:eds),'" or @syriaca-computed-end gt "',places:do-date($places:eds),'"]]')
    else if (exists($places:ede) and $places:ede != '') then 
        concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-end lt "',places:do-date($places:ede),'" or @syriaca-computed-start lt "',places:do-date($places:ede),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type = attestation] data
 : @e full text query
:)
declare function places:attestation(){
    if(exists($places:a) and $places:a != '') then concat('[ft:query(tei:event[@type = "attestation"],"',places:clean-string($places:a),'")]')
    else ''
};

(:~
 : Build date range for attestation
 : tei:event[@type = attestation]
 : @ads attestation start range index
 : @ade attestation end range index
:)
declare function places:attestation-dates(){
    if(exists($places:ads) and $places:ads != '') then 
        if(exists($places:ade) and $places:ade != '') then 
            concat('[descendant::tei:event[@type = "attestation"]
            [(
            @syriaca-computed-start gt 
                "',places:do-date($places:ads),'" 
                and @syriaca-computed-end lt 
                "',places:do-date($places:ade),'"
                ) or (
                @syriaca-computed-start gt 
                "',places:do-date($places:ads),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-start gt "',places:do-date($places:ads),'" or @syriaca-computed-end gt "',places:do-date($places:ads),'"]]')
    else if (exists($places:ade) and $places:ade != '') then 
        concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-end lt "',places:do-date($places:ade),'" or @syriaca-computed-start lt "',places:do-date($places:ade),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = confession] data
 : @e full text query
:)
declare function places:confession(){
    if(exists($places:c) and $places:c != '') then 
        if(exists($places:cds) and $places:cds != '' or exists($places:cde) and $places:cde != '') then 
            concat('[descendant::tei:state[@type = "confession"][matches(tei:label,"',$places:c,'") and ',places:confession-text-w-dates(),']]') 
        else concat('[matches(descendant::tei:state[@type = "confession"]/tei:label,"',$places:c,'")]')
    else if(exists($places:cds) and $places:cds != '' or exists($places:cde) and $places:cde != '') then places:confession-dates()
    else ''
};

(:~
 : Build date range for confession
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',places:do-date($places:cde),'"]]')
:)
declare function places:confession-dates(){
if(exists($places:cds) and $places:cds != '') then 
        if(exists($places:cde) and $places:cde != '') then 
            concat('[descendant::tei:state[@type = "confession"]
            [(
            @syriaca-computed-start gt 
                "',places:do-date($places:cds),'" 
                and @syriaca-computed-end lt 
                "',places:do-date($places:cde),'"
                ) or (
                @syriaca-computed-start gt 
                "',places:do-date($places:cds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',places:do-date($places:cds),'" or @syriaca-computed-end gt "',places:do-date($places:cds),'"]]')
    else if (exists($places:cde) and $places:cde != '') then 
        concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',places:do-date($places:cde),'" or @syriaca-computed-start lt "',places:do-date($places:cde),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build date range for confession with confession text
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',places:do-date($places:cde),'"]]')
:)
declare function places:confession-text-w-dates(){
if(exists($places:cds) and $places:cds != '') then 
        if(exists($places:cde) and $places:cde != '') then 
            concat('(
            (@syriaca-computed-start gt 
                "',places:do-date($places:cds),'" 
                and @syriaca-computed-end lt 
                "',places:do-date($places:cde),'"
                ) or (
                @syriaca-computed-start gt 
                "',places:do-date($places:cds),'" 
                and 
                not(exists(@syriaca-computed-end))
                )')
        else 
            concat('(@syriaca-computed-start gt "',places:do-date($places:cds),'") or (@syriaca-computed-end gt "',places:do-date($places:cds),'")')
    else if (exists($places:cde) and $places:cde != '') then 
        concat('((@syriaca-computed-end lt "',places:do-date($places:cde),'") or (@syriaca-computed-start lt "',places:do-date($places:cde),'" and not(@syriaca-computed-end)))')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = ‘existence’] data
 : @e full text query
:)
declare function places:existence(){
    if(exists($places:exist) and $places:exist != '') then concat('[ft:query(descendant::tei:state[@type = "existence"],"',places:clean-string($places:exist),'")]')
    else ''
};

(:~
 : Build date range for existence
 : tei:state[@type = existence]
 : @existds confession start range index
 : @existde confession end range index
:)
declare function places:existence-dates(){
if(exists($places:existds) and $places:existds != '') then 
        if(exists($places:existde) and $places:existde != '') then 
            concat('[descendant::tei:state[@type = "existence"]
            [(
            @syriaca-computed-start gt 
                "',places:do-date($places:existds),'" 
                and @syriaca-computed-end lt 
                "',places:do-date($places:existde),'"
                ) or (
                @syriaca-computed-start gt 
                "',places:do-date($places:existds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',places:do-date($places:existds),'" or @syriaca-computed-end gt "',places:do-date($places:existds),'"]]')
    else if (exists($places:existde) and $places:existde != '') then 
        concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-end lt "',places:do-date($places:existde),'" or @syriaca-computed-start lt "',places:do-date($places:existde),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Function to cast dates strings from url to xs:date
 : Tests string length, may need something more sophisticated to test dates, 
 : or form validation via js before submit. 
 : @param $date passed to function from parent function
:)
declare function places:do-date($date){
let $date-format := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 3) then concat('0',string($date),'-01-01')
                    else if(string-length($date) eq 2) then concat('00',string($date),'-01-01')
                    else if(string-length($date) eq 1) then concat('000',string($date),'-01-01')
                    else string($date)
let $final-date := xs:date($date-format) 
return $final-date
};

(:~
 : Limit by English language
 :)
declare function places:limit-by-lang-en(){
    if(exists($places:en) and $places:en != '') then concat('[child::*/@xml:lang = "',$places:en,'"]')
    else ''
};

(:~
 : Limit by Syriac language
 :)
declare function places:limit-by-lang-syr(){
    if(exists($places:syr) and $places:syr != '') then concat('[child::*/@xml:lang = "',$places:syr,'"]')
    else ''
};

(:~
 : Limit by Arabic language
 :)
declare function places:limit-by-lang-ar(){
    if(exists($places:ar) and $places:ar != '') then concat('[child::*/@xml:lang = "',$places:ar,'"]')
    else ''
};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
:)
declare function places:query-string() as xs:string?{
    concat("collection('/db/apps/srophe/data/places/tei')//tei:body",
    places:keyword(),
    places:type(),
    places:place-name(),
    places:location(),
    places:event(),places:event-dates(),
    places:attestation(), places:attestation-dates(), 
    places:existence(),places:existence-dates(),
    places:confession(),
    places:limit-by-lang-en(),places:limit-by-lang-syr(),places:limit-by-lang-ar()
    )
};

(:~
 : Build search parameter string for search results page
:)
declare function places:search-string(){
    let $q-string := if(exists($places:q) and $places:q != '') then (<span class="param">Keyword: </span>,<span class="match">{places:clean-string($places:q)}&#160;</span>)
                     else ''
    let $p-string := if(exists($places:p) and $places:p != '') then (<span class="param">Place Name: </span>,<span class="match">{places:clean-string($places:p)} &#160;</span>)
                        else ''                            
    let $type-string := if(exists($places:type) and $places:type != '') then (<span class="param">Type: </span>,<span class="match">{places:clean-string($places:type)} &#160;</span>)
                        else ''     
    let $loc-string := if(exists($places:loc) and $places:loc != '') then (<span class="param">Location: </span>,<span class="match">{places:clean-string($places:loc)} &#160;</span>)
                        else ''     
    let $e-string := if(exists($places:e) and $places:e != '') then (<span class="param">Event: </span>, <span class="match">{places:clean-string($places:e)} &#160;</span>)
                     else ''                             
    let $eds-string := if(exists($places:eds) and $places:eds != '') then (<span class="param">Event Start Date: </span>, <span class="match">{places:clean-string($places:eds)} &#160;</span>)
                     else ''     
    let $ede-string := if(exists($places:ede) and $places:ede != '') then (<span class="param">Event End Date: </span>, <span class="match">{places:clean-string($places:ede)} &#160;</span>)
                     else ''                   
    let $a-string := if(exists($places:a) and $places:a != '') then (<span class="param">Attestations: </span>, <span class="match">{places:clean-string($places:a)}&#160; </span>)
                     else ''     
    let $ads-string := if(exists($places:ads) and $places:ads != '') then (<span class="param">Attestations Start Date: </span>, <span class="match">{places:clean-string($places:ads)}&#160;</span>)
                     else ''     
    let $ade-string := if(exists($places:ade) and $places:ade != '') then (<span class="param">Attestations End Date: </span>, <span class="match">{places:clean-string($places:ade)} &#160;</span>)
                     else ''                   
    let $c-string := if(exists($places:c) and $places:c != '') then (<span class="param">Religious Communities: </span>, <span class="match">{places:clean-string($places:c)} &#160;</span>)
                     else ''     
    let $cds-string := if(exists($places:cds) and $places:cds != '') then (<span class="param">Religious Communities Start Date: </span>, <span class="match">{places:clean-string($places:cds)} &#160;</span>)
                     else ''     
    let $cde-string := if(exists($places:cde) and $places:cde != '') then (<span class="param">Religious Communities End Date: </span>, <span class="match">{places:clean-string($places:cde)} &#160;</span>)
                     else ''                       
    let $existds-string := if(exists($places:existds) and $places:existds != '') then (<span class="param">Existence Start Date: </span>, <span class="match">{places:clean-string($places:existds)}&#160; </span>)
                     else ''     
    let $existde-string := if(exists($places:existde) and $places:existde != '') then (<span class="param">Existence End Date: </span>, <span class="match">{places:clean-string($places:existde)}&#160; </span>)
                     else ''                    
    let $en-lang-string := if(exists($places:en) and $places:en != '') then <span class="param">English </span>
                     else ''
    let $syr-lang-string := if(exists($places:syr) and $places:syr != '') then <span class="param">Syriac </span>
                     else ''
    let $ar-lang-string := if(exists($places:ar) and $places:ar != '') then <span class="param">Arabic </span>
                     else ''           

    return ($q-string,$p-string,$type-string,$loc-string,$e-string,$eds-string,$ede-string,$a-string,$ads-string,$ade-string,$c-string,$cds-string,$cde-string,$existds-string,$existde-string,$en-lang-string,$ar-lang-string,$syr-lang-string)                                          
};

declare function places:results-node($hit){
    let $title-en := $hit/tei:placeName[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')][1]
    let $title-syr := 
                    if($hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]) then 
                        (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                {$hit/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]}
                            </bdi>)
                    else ''
    let $type := if($hit//tei:place/@type) then  
                    <bdi dir="ltr" lang="en" xml:lang="en"> ({replace($hit//tei:person/@ana,'#syriaca-','')})</bdi>
                  else ''  
    let $id := substring-after($hit//tei:place/@xml:id,'person-')                        
    return
        <p style="font-weight:bold padding:.5em;">
            <a href="/place/{$id}.html">
                <bdi dir="ltr" lang="en" xml:lang="en">{$title-en}</bdi>
                {$type,$title-syr}
            </a>
        </p>
};
