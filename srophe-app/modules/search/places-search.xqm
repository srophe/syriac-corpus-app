xquery version "3.0";

module namespace places="http://syriaca.org//places";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "../config.xqm";

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
    if(exists($places:q) and $places:q != '') then concat("[ft:query(descendant::*,'",places:clean-string($places:q),"')]")
    else ''    
};

(:~
 : Build full-text keyword search over all tei:placeName data
 : @p full text query
:)
declare function places:place-name(){
    if(exists($places:p) and $places:p != '') then concat("[ft:query(descendant::tei:place/tei:placeName,'",places:clean-string($places:p),"')]")
    else ''    
};

(:~
 : Build range search on tei:place/@type data
 : @type full text query
:)
declare function places:type(){
    if(exists($places:type) and $places:type != '') then string(concat("[descendant::tei:place/@type = '",places:clean-string($places:type),"']"))
    else '' 
};

(:~
 : Build full-text search on tei:place/tei:location data
 : @loc full text query
 : NOTE: need to understand location search better. 
:)
declare function places:location(){
    if(exists($places:loc) and $places:loc != '') then concat("[ft:query(descendant::tei:place/tei:location,'",places:clean-string($places:loc),"')]")
    else ''
};

(:~
 : Build full-text search on tei:event[@type != attestation] data
 NOTE: will probably have to build this into the date range, so they hold together as one AND predicate
 : @e full text query
:)
declare function places:event(){
    if(exists($places:e) and $places:e != '') then concat("[ft:query(descendant::tei:place/tei:event[@type != 'attestation' or not(@type)],'",places:clean-string($places:e),"')]")
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
            concat("[descendant::tei:event[@type != 'attestation' or not(@type)]
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:eds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:ede),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:eds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:event[@type != 'attestation' or not(@type)][@syriaca-computed-start gt '",places:do-date($places:eds),"' or @syriaca-computed-end gt '",places:do-date($places:eds),"']]")
    else if (exists($places:ede) and $places:ede != '') then 
        concat("[descendant::tei:event[@type != 'attestation' or not(@type)][@syriaca-computed-end lt '",places:do-date($places:ede),"' or @syriaca-computed-start lt '",places:do-date($places:ede),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Build full-text search on tei:event[@type = attestation] data
 : @e full text query
:)
declare function places:attestation(){
    if(exists($places:a) and $places:a != '') then concat("[ft:query(descendant::tei:place/tei:event[@type = 'attestation'],'",places:clean-string($places:a),"')]")
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
            concat("[descendant::tei:event[@type = 'attestation']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:ads),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:ade),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:ads),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:event[@type = 'attestation'][@syriaca-computed-start gt '",places:do-date($places:ads),"' or @syriaca-computed-end gt '",places:do-date($places:ads),"']]")
    else if (exists($places:ade) and $places:ade != '') then 
        concat("[descendant::tei:event[@type = 'attestation'][@syriaca-computed-end lt '",places:do-date($places:ade),"' or @syriaca-computed-start lt '",places:do-date($places:ade),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Build full-text search on tei:state[@type = confession] data
 : @e full text query
:)
declare function places:confession(){
    if(exists($places:c) and $places:c != '') then 
        if(exists($places:cds) and $places:cds != '' or exists($places:cde) and $places:cde != '') then 
            concat("[descendant::tei:state[@type = 'confession'][matches(tei:label,'",$places:c,"') and ",places:confession-text-w-dates(),"]]") 
        else concat("[matches(descendant::tei:state[@type = 'confession']/tei:label,'",$places:c,"')]")
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
            concat("[descendant::tei:state[@type = 'confession']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:cde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:state[@type = 'confession'][@syriaca-computed-start gt '",places:do-date($places:cds),"' or @syriaca-computed-end gt '",places:do-date($places:cds),"']]")
    else if (exists($places:cde) and $places:cde != '') then 
        concat("[descendant::tei:state[@type = 'confession'][@syriaca-computed-end lt '",places:do-date($places:cde),"' or @syriaca-computed-start lt '",places:do-date($places:cde),"' and not(@syriaca-computed-end)]]")
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
            concat("(
            (@syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:cde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and 
                not(exists(@syriaca-computed-end))
                )")
        else 
            concat("(@syriaca-computed-start gt '",places:do-date($places:cds),"') or (@syriaca-computed-end gt '",places:do-date($places:cds),"')")
    else if (exists($places:cde) and $places:cde != '') then 
        concat("((@syriaca-computed-end lt '",places:do-date($places:cde),"') or (@syriaca-computed-start lt '",places:do-date($places:cde),"' and not(@syriaca-computed-end)))")
    else ''
};

(:~
 : Build full-text search on tei:state[@type = ‘existence’] data
 : @e full text query
:)
declare function places:existence(){
    if(exists($places:exist) and $places:exist != '') then concat("[ft:query(descendant::tei:state[@type = 'existence'],'",places:clean-string($places:exist),"')]")
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
            concat("[descendant::tei:state[@type = 'existence']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:existds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:existde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:existds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:state[@type = 'existence'][@syriaca-computed-start gt '",places:do-date($places:existds),"' or @syriaca-computed-end gt '",places:do-date($places:existds),"']]")
    else if (exists($places:existde) and $places:existde != '') then 
        concat("[descendant::tei:state[@type = 'existence'][@syriaca-computed-end lt '",places:do-date($places:existde),"' or @syriaca-computed-start lt '",places:do-date($places:existde),"' and not(@syriaca-computed-end)]]")
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
    if(exists($places:en) and $places:en != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:en,"']")
    else ''
};

(:~
 : Limit by Syriac language
 :)
declare function places:limit-by-lang-syr(){
    if(exists($places:syr) and $places:syr != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:syr,"']")
    else ''
};

(:~
 : Limit by Arabic language
 :)
declare function places:limit-by-lang-ar(){
    if(exists($places:ar) and $places:ar != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:ar,"']")
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
    let $root := $hit//tei:place   
    let $title-en := $root/tei:placeName[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')][1]
    let $title-syr := 
                    if($root/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]) then 
                        (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                {$root/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]}
                            </bdi>)
                    else ''
    let $type := if($root/@type) then  
                    <bdi dir="ltr" lang="en" xml:lang="en"> ({string($root/@type)})</bdi>
                  else ''  
    let $id := substring-after($root/@xml:id,'place-')                        
    return
        <p style="font-weight:bold padding:.5em;">
            <a href="/place/{$id}.html">
                <bdi dir="ltr" lang="en" xml:lang="en">{$title-en}</bdi>
                {$type,$title-syr}
            </a>
        </p>
};

(:~
 : Builds advanced search form
 :)
declare function places:search-form() {   
<form method="get" action="search.html" style="margin-top:2em;">
    <div class="well well-small">
        <div class="navbar-inner" style="margin:-.75em -.75em 1em;">
            <h3>Advanced Search</h3>
        </div>
        <div class="well well-small" style="background-color:white;">
            <div class="row-fluid">
                <div class="span8" style="border-right:1px solid #ccc;">
                    <div class="row-fluid" style="margin-top:1em;">
                    <div class="span3">Keyword: </div>
                    <div class="span9"><input type="text" name="q"/></div>
                    </div>
                    <!-- Place Name-->
                    <div class="row-fluid">
                        <div class="span3">Place Name: </div>
                        <div class="span9"><input type="text" name="p"/></div>
                    </div>
                    <!-- Location -->    
                    <div class="row-fluid">
                        <div class="span3">Location: </div>
                        <div class="span9"><input type="text" name="loc"/></div>
                        <!-- Will need to be worked out so a range can be searched 
                                        <label>Coords: </label>
                                        <input type="text" name="lat"/> - <input type="text" name="long"/> 
                                        --> 
                    </div>
                    <hr/>
                    <div class="row-fluid">
                         <div class="span3">Events: </div>
                         <div class="span9"><input type="text" name="e"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="eds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="ede" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Attestations -->
                     <div class="row-fluid">
                         <div class="span3">Attestations: </div>
                         <div class="span9"><input type="text" name="a"/></div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="ads" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="ade" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Confessions -->
                     <div class="row-fluid">
                         <div class="span3">Religious Communities: </div>
                         <div class="span9">
                         <select name="c">
                            <option value="">-- Select --</option>
                                {for $confession in doc('/db/apps/srophe/documentation/confessions.xml')//tei:item
                                 return 
                                 <option value="{$confession/child::tei:label}">
                                 {
                                    (for $confession-parent in $confession/ancestor::tei:item return '&#160;',
                                     $confession/child::tei:label)
                                 }
                                 </option>
                                }
                                
                        </select>
                         </div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">    
                             <input type="text" name="cds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="cde" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     <hr/>
                     <!-- Existence -->
                     <div class="row-fluid">
                        <div class="span3">Existence </div>
                     </div>
                     <div class="row-fluid">
                         <div class="span3">Dates: </div>
                         <div class="span9 form-inline">
                             <input type="text" name="existds" placeholder="Start Date" class="input-small"/>&#160;
                             <input type="text" name="existde" placeholder="End Date" class="input-small"/>
                             <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                         </div>
                     </div>
                     
                </div>
                <div class="span4">
                      <!-- Place Type -->
                    <div style="margin-top:1em; padding-left:.5em;">
                        <label>Place Type:</label>
                            <!-- Values from controlled vocab in https://docs.google.com/spreadsheet/ccc?key=0AnhFTnX2Mw6YdGFieExCX0xIQ3Q0WnBOQmlnclo0WlE&usp=sharing#gid=1-->
                            <select name="type" class="input-medium">
                                <option value="">- Select -</option>
                                <option value="building">building</option>
                                <option value="church">church</option>
                                <option value="diocese">diocese</option>
                                <option value="fortification">fortification</option>
                                <option value="island">island</option>
                                <option value="madrasa">madrasa</option>
                                <option value="monastery">monastery</option>
                                <option value="mosque">mosque</option>
                                <option value="mountain">mountain</option>
                                <option value="open-water">open-water</option>
                                <option value="parish">parish</option>
                                <option value="province">province</option>
                                <option value="quarter">quarter</option>
                                <option value="region">region</option>
                                <option value="river">river</option>
                                <option value="settlement">settlement</option>
                                <option value="state">state</option>
                                <option value="synagogue">synagogue</option>
                                <option value="temple">temple</option>
                                <option value="unknown">unknown</option>
                            </select>
                    <hr/>
                    <!-- Language -->
                        <label>Language: </label>
                        <div class="offset1">
                            <input type="checkbox" name="en" value="en"/> English<br/>
                            <input type="checkbox" name="ar" value="ar"/> Arabic<br/>
                            <input type="checkbox" name="syr" value="syr"/> Syriac<br/>
                        </div>

                    </div>
                </div>
            </div>
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};
