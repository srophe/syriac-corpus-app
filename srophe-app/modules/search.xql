xquery version "3.0";

module namespace search="http://syriaca.org//search";
import module namespace search-form="http://syriaca.org//search-form" at "search-form.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $search:q {request:get-parameter('q', '')};
declare variable $search:p {request:get-parameter('p', '')};
declare variable $search:type {request:get-parameter('type', '')};

declare variable $search:loc {request:get-parameter('loc', '')};
declare variable $search:lat {request:get-parameter('lat', '')};
declare variable $search:long {request:get-parameter('long', '')};

declare variable $search:e {request:get-parameter('e', '')};
declare variable $search:eds {request:get-parameter('eds', '')};
declare variable $search:ede {request:get-parameter('ede', '')};

declare variable $search:a {request:get-parameter('a', '')};
declare variable $search:ads {request:get-parameter('ads', '')};
declare variable $search:ade {request:get-parameter('ade', '')};

declare variable $search:c {request:get-parameter('c', '')};
declare variable $search:cds {request:get-parameter('cds', '')};
declare variable $search:cde {request:get-parameter('cde', '')};

declare variable $search:exist {request:get-parameter('exist', '')};
declare variable $search:existds {request:get-parameter('existds', '')};
declare variable $search:existde {request:get-parameter('existde', '')};

declare variable $search:en {request:get-parameter('en', '')};
declare variable $search:syr {request:get-parameter('syr', '')};
declare variable $search:ar {request:get-parameter('ar', '')};

declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
:)
declare function search:clean-string($param-string){
    replace ($param-string, "[&amp;&quot;!@#$%^+=_]", "")
};

(:~
 : Build full-text keyword search over all tei:place data
 : @q full text query
 descendant-or-self::* or . testing which is most correct
 
:)
declare function search:keyword(){
    if(exists($search:q) and $search:q != '') then concat('[ft:query(descendant-or-self::*,"',search:clean-string($search:q),'")]')
    else ''    
};

(:~
 : Build full-text keyword search over all tei:placeName data
 : @p full text query
:)
declare function search:place-name(){
    if(exists($search:p) and $search:p != '') then concat('[ft:query(tei:placeName,"',search:clean-string($search:p),'")]')
    else ''    
};

(:~
 : Build range search on tei:place/@type data
 : @type full text query
:)
declare function search:type(){
    if(exists($search:type) and $search:type != '') then string(concat('[@type = "',search:clean-string($search:type),'"]'))
    else '' 
};

(:~
 : Build full-text search on tei:place/tei:location data
 : @loc full text query
 : NOTE: need to understand location search better. 
:)
declare function search:location(){
    if(exists($search:loc) and $search:loc != '') then concat('[ft:query(tei:location,"',search:clean-string($search:loc),'")]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type != attestation] data
 NOTE: will probably have to build this into the date range, so they hold together as one AND predicate
 : @e full text query
:)
declare function search:event(){
    if(exists($search:e) and $search:e != '') then concat('[ft:query(tei:event[@type != "attestation" or not(@type)],"',search:clean-string($search:e),'")]')
    else ''
};

(:~
 : Build date range for event 
 : tei:event[@type != attestation]
 : @eds event start range index
 : @ede event end range index
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][(@syriaca-computed-start gt "',search:do-date($search:eds),'" and @syriaca-computed-end lt "',search:do-date($search:ede),'") or (@syriaca-computed-start gt "',search:do-date($search:eds),'" and not(@syriaca-computed-end))]]')
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',search:do-date($search:eds),'"]]')
:)
declare function search:event-dates(){
    if(exists($search:eds) and $search:eds != '') then 
        if(exists($search:ede) and $search:ede != '') then 
            concat('[descendant::tei:event[@type != "attestation" or not(@type)]
            [(
            @syriaca-computed-start gt 
                "',search:do-date($search:eds),'" 
                and @syriaca-computed-end lt 
                "',search:do-date($search:ede),'"
                ) or (
                @syriaca-computed-start gt 
                "',search:do-date($search:eds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',search:do-date($search:eds),'" or @syriaca-computed-end gt "',search:do-date($search:eds),'"]]')
    else if (exists($search:ede) and $search:ede != '') then 
        concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-end lt "',search:do-date($search:ede),'" or @syriaca-computed-start lt "',search:do-date($search:ede),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build full-text search on tei:event[@type = attestation] data
 : @e full text query
:)
declare function search:attestation(){
    if(exists($search:a) and $search:a != '') then concat('[ft:query(tei:event[@type = "attestation"],"',search:clean-string($search:a),'")]')
    else ''
};

(:~
 : Build date range for attestation
 : tei:event[@type = attestation]
 : @ads attestation start range index
 : @ade attestation end range index
:)
declare function search:attestation-dates(){
    if(exists($search:ads) and $search:ads != '') then 
        if(exists($search:ade) and $search:ade != '') then 
            concat('[descendant::tei:event[@type = "attestation"]
            [(
            @syriaca-computed-start gt 
                "',search:do-date($search:ads),'" 
                and @syriaca-computed-end lt 
                "',search:do-date($search:ade),'"
                ) or (
                @syriaca-computed-start gt 
                "',search:do-date($search:ads),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-start gt "',search:do-date($search:ads),'" or @syriaca-computed-end gt "',search:do-date($search:ads),'"]]')
    else if (exists($search:ade) and $search:ade != '') then 
        concat('[descendant::tei:event[@type = "attestation"][@syriaca-computed-end lt "',search:do-date($search:ade),'" or @syriaca-computed-start lt "',search:do-date($search:ade),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = confession] data
 : @e full text query
:)
declare function search:confession(){
    if(exists($search:c) and $search:c != '') then 
        if(exists($search:cds) and $search:cds != '' or exists($search:cde) and $search:cde != '') then 
            concat('[descendant::tei:state[@type = "confession"][matches(tei:label,"',$search:c,'") and ',search:confession-text-w-dates(),']]') 
        else concat('[matches(descendant::tei:state[@type = "confession"]/tei:label,"',$search:c,'")]')
    else if(exists($search:cds) and $search:cds != '' or exists($search:cde) and $search:cde != '') then search:confession-dates()
    else ''
};

(:~
 : Build date range for confession
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',search:do-date($search:cde),'"]]')
:)
declare function search:confession-dates(){
if(exists($search:cds) and $search:cds != '') then 
        if(exists($search:cde) and $search:cde != '') then 
            concat('[descendant::tei:state[@type = "confession"]
            [(
            @syriaca-computed-start gt 
                "',search:do-date($search:cds),'" 
                and @syriaca-computed-end lt 
                "',search:do-date($search:cde),'"
                ) or (
                @syriaca-computed-start gt 
                "',search:do-date($search:cds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-start gt "',search:do-date($search:cds),'" or @syriaca-computed-end gt "',search:do-date($search:cds),'"]]')
    else if (exists($search:cde) and $search:cde != '') then 
        concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',search:do-date($search:cde),'" or @syriaca-computed-start lt "',search:do-date($search:cde),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Build date range for confession with confession text
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',search:do-date($search:cde),'"]]')
:)
declare function search:confession-text-w-dates(){
if(exists($search:cds) and $search:cds != '') then 
        if(exists($search:cde) and $search:cde != '') then 
            concat('(
            (@syriaca-computed-start gt 
                "',search:do-date($search:cds),'" 
                and @syriaca-computed-end lt 
                "',search:do-date($search:cde),'"
                ) or (
                @syriaca-computed-start gt 
                "',search:do-date($search:cds),'" 
                and 
                not(exists(@syriaca-computed-end))
                )')
        else 
            concat('(@syriaca-computed-start gt "',search:do-date($search:cds),'") or (@syriaca-computed-end gt "',search:do-date($search:cds),'")')
    else if (exists($search:cde) and $search:cde != '') then 
        concat('((@syriaca-computed-end lt "',search:do-date($search:cde),'") or (@syriaca-computed-start lt "',search:do-date($search:cde),'" and not(@syriaca-computed-end)))')
    else ''
};

(:~
 : Build full-text search on tei:state[@type = ‘existence’] data
 : @e full text query
:)
declare function search:existence(){
    if(exists($search:exist) and $search:exist != '') then concat('[ft:query(descendant::tei:state[@type = "existence"],"',search:clean-string($search:exist),'")]')
    else ''
};

(:~
 : Build date range for existence
 : tei:state[@type = existence]
 : @existds confession start range index
 : @existde confession end range index
:)
declare function search:existence-dates(){
if(exists($search:existds) and $search:existds != '') then 
        if(exists($search:existde) and $search:existde != '') then 
            concat('[descendant::tei:state[@type = "existence"]
            [(
            @syriaca-computed-start gt 
                "',search:do-date($search:existds),'" 
                and @syriaca-computed-end lt 
                "',search:do-date($search:existde),'"
                ) or (
                @syriaca-computed-start gt 
                "',search:do-date($search:existds),'" 
                and 
                not(exists(@syriaca-computed-end)))]]')
        else 
            concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-start gt "',search:do-date($search:existds),'" or @syriaca-computed-end gt "',search:do-date($search:existds),'"]]')
    else if (exists($search:existde) and $search:existde != '') then 
        concat('[descendant::tei:state[@type = "existence"][@syriaca-computed-end lt "',search:do-date($search:existde),'" or @syriaca-computed-start lt "',search:do-date($search:existde),'" and not(@syriaca-computed-end)]]')
    else ''
};

(:~
 : Function to cast dates strings from url to xs:date
 : Tests string length, may need something more sophisticated to test dates, 
 : or form validation via js before submit. 
 : @param $date passed to function from parent function
:)
declare function search:do-date($date){
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
declare function search:limit-by-lang-en(){
    if(exists($search:en) and $search:en != '') then concat('[child::*/@xml:lang = "',$search:en,'"]')
    else ''
};

(:~
 : Limit by Syriac language
 :)
declare function search:limit-by-lang-syr(){
    if(exists($search:syr) and $search:syr != '') then concat('[child::*/@xml:lang = "',$search:syr,'"]')
    else ''
};

(:~
 : Limit by Arabic language
 :)
declare function search:limit-by-lang-ar(){
    if(exists($search:ar) and $search:ar != '') then concat('[child::*/@xml:lang = "',$search:ar,'"]')
    else ''
};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*)){
    let $eval-string := concat("collection('/db/apps/srophe/data/places/tei')//tei:place",
    search:keyword(),
    search:type(),
    search:place-name(),
    search:location(),
    search:event(),search:event-dates(),
    search:attestation(), search:attestation-dates(), 
    search:existence(),search:existence-dates(),
    search:confession(),
    search:limit-by-lang-en(),search:limit-by-lang-syr(),search:limit-by-lang-ar()
    )
    return
    map {"hits" := 
                let $hits := util:eval($eval-string)    
                for $hit in $hits
                order by ft:score($hit) descending
                return $hit
    }
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build search parameter string for search results page
:)
declare function search:search-string(){
    let $q-string := if(exists($search:q) and $search:q != '') then (<span class="param">Keyword: </span>,<span class="match">{search:clean-string($search:q)}&#160;</span>)
                     else ''
    let $p-string := if(exists($search:p) and $search:p != '') then (<span class="param">Place Name: </span>,<span class="match">{search:clean-string($search:p)} &#160;</span>)
                        else ''                            
    let $type-string := if(exists($search:type) and $search:type != '') then (<span class="param">Type: </span>,<span class="match">{search:clean-string($search:type)} &#160;</span>)
                        else ''     
    let $loc-string := if(exists($search:loc) and $search:loc != '') then (<span class="param">Location: </span>,<span class="match">{search:clean-string($search:loc)} &#160;</span>)
                        else ''     
    let $e-string := if(exists($search:e) and $search:e != '') then (<span class="param">Event: </span>, <span class="match">{search:clean-string($search:e)} &#160;</span>)
                     else ''                             
    let $eds-string := if(exists($search:eds) and $search:eds != '') then (<span class="param">Event Start Date: </span>, <span class="match">{search:clean-string($search:eds)} &#160;</span>)
                     else ''     
    let $ede-string := if(exists($search:ede) and $search:ede != '') then (<span class="param">Event End Date: </span>, <span class="match">{search:clean-string($search:ede)} &#160;</span>)
                     else ''                   
    let $a-string := if(exists($search:a) and $search:a != '') then (<span class="param">Attestations: </span>, <span class="match">{search:clean-string($search:a)}&#160; </span>)
                     else ''     
    let $ads-string := if(exists($search:ads) and $search:ads != '') then (<span class="param">Attestations Start Date: </span>, <span class="match">{search:clean-string($search:ads)}&#160;</span>)
                     else ''     
    let $ade-string := if(exists($search:ade) and $search:ade != '') then (<span class="param">Attestations End Date: </span>, <span class="match">{search:clean-string($search:ade)} &#160;</span>)
                     else ''                   
    let $c-string := if(exists($search:c) and $search:c != '') then (<span class="param">Religious Communities: </span>, <span class="match">{search:clean-string($search:c)} &#160;</span>)
                     else ''     
    let $cds-string := if(exists($search:cds) and $search:cds != '') then (<span class="param">Religious Communities Start Date: </span>, <span class="match">{search:clean-string($search:cds)} &#160;</span>)
                     else ''     
    let $cde-string := if(exists($search:cde) and $search:cde != '') then (<span class="param">Religious Communities End Date: </span>, <span class="match">{search:clean-string($search:cde)} &#160;</span>)
                     else ''                       
    let $existds-string := if(exists($search:existds) and $search:existds != '') then (<span class="param">Existence Start Date: </span>, <span class="match">{search:clean-string($search:existds)}&#160; </span>)
                     else ''     
    let $existde-string := if(exists($search:existde) and $search:existde != '') then (<span class="param">Existence End Date: </span>, <span class="match">{search:clean-string($search:existde)}&#160; </span>)
                     else ''                    
    let $en-lang-string := if(exists($search:en) and $search:en != '') then <span class="param">English </span>
                     else ''
    let $syr-lang-string := if(exists($search:syr) and $search:syr != '') then <span class="param">Syriac </span>
                     else ''
    let $ar-lang-string := if(exists($search:ar) and $search:ar != '') then <span class="param">Arabic </span>
                     else ''           

    return ($q-string,$p-string,$type-string,$loc-string,$e-string,$eds-string,$ede-string,$a-string,$ads-string,$ade-string,$c-string,$cds-string,$cde-string,$existds-string,$existde-string,$en-lang-string,$ar-lang-string,$syr-lang-string)                                          
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*)){
let $perpage := 20
let $start := if($search:start) then $search:start else 1
let $total-result-count := search:hit-count($node, $model)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function:)
let $url-params := replace(request:get-query-string(), '&amp;start=\d+', '')
let $parameters :=  request:get-parameter-names()
let $search-string: = 
        for $parameter in $parameters
        return request:get-parameter($parameter, '')
        (:if($parameter = 'search' or starts-with($parameter,'start')) then ''
               else search:clean-string(request:get-parameter($parameter, '')):)
let $pagination-links := 
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml">
            <div class="span5">
            <h4>Search results:</h4>
                <p class="offset1">{$total-result-count} matches for {search:search-string()}.</p>
            </div>
            {if(search:hit-count($node, $model) gt $perpage) then 
              <div class="span7" style="text-align:right">
                  <div class="pagination" >
                      <ul style="margin-bottom:-2em; padding-bottom:0;">
                          {
                          (: Show 'Previous' for all but the 1st page of results :)
                              if ($current-page = 1) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $perpage * ($current-page - 2)) }">Prev</a></li>
                          }
                          {
                          (: Show links to each page of results :)
                              let $max-pages-to-show := 8
                              let $padding := xs:integer(round($max-pages-to-show div 2))
                              let $start-page := 
                                  if ($current-page le ($padding + 1)) then
                                      1
                                  else $current-page - $padding
                              let $end-page := 
                                  if ($number-of-pages le ($current-page + $padding)) then
                                      $number-of-pages
                                  else $current-page + $padding - 1
                              for $page in ($start-page to $end-page)
                              let $newstart := 
                                  if($page = 1) then 1 
                                  else $perpage * ($page - 1)
                              return
                                  (
                                  if ($newstart eq $start) then 
                                      (<li class="active"><a href="#" >{$page}</a></li>)
                                  else
                                      <li><a href="{concat('?', $url-params, '&amp;start=', $newstart)}">{$page}</a></li>
                                  )
                          }
           
                          {
                          (: Shows 'Next' for all but the last page of results :)
                              if ($start + $perpage ge $total-result-count) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $start + $perpage)}">Next</a></li>
                          }
                      </ul>
                  </div>
              </div>
             else'' 
              }
        </div>    

return 
   ($pagination-links,
   if(search:hit-count($node,$model) gt 0) then ''
   else <div>{search-form:show-form()}</div>
   )
};

declare function search:build-geojson($node as node()*, $model as map(*)){
let $geo-hits := $model("hits")//tei:geo
return
    if(count($geo-hits) gt 1) then
         (<div id="map" style="height: 250px;"/>,
         <div>*{count($geo-hits)} of {search:hit-count($node,$model)} places have coordinates and are shown on this map. 
         <a href="#map-selection" role="button"  data-toggle="modal">Read more...</a></div>,
         <div style="width: 750px; margin-left: -280px;" id="map-selection" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="faq-label" aria-hidden="true">
                <div class="modal-header" style="height:15px !important;">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true"> × </button>
                </div>
                <div class="modal-body">
                    <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                </div>
                <div class="modal-footer">
                    <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                    <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                </div>
            </div>,
            <script>
            <![CDATA[
                $('#map-selection').on('shown', function () {
                $( "#popup" ).load( "../documentation/faq.html #map-selection" );
                })
                ]]>
            </script>,
         <script type="text/javascript">
             <![CDATA[
                    var terrain = L.tileLayer(
                        'http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', 
                        {attribution: "ISAW, 2012"});
                        
                        /* Not added by default, only through user control action */
                    var streets = L.tileLayer(
                        'http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', 
                        {attribution: "ISAW, 2012"});
                        
                    var imperium = L.tileLayer(
                        'http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
                        attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC',
                        maxZoom: 11 });


              		var placesgeo =]]>
              		{geo:json-transform($geo-hits,'','')}
                     <![CDATA[

                        var geojson = L.geoJson(placesgeo, {
                        onEachFeature: function (feature, layer){
                        var popupContent = "<a href='" + feature.properties.uri + "'>" +
                        feature.properties.name + " - " + feature.properties.type + "</a>";
                        
                        layer.bindPopup(popupContent);
                        }
                        }) 
                        
                        var map = L.map('map').fitBounds(geojson.getBounds());
                        
                        terrain.addTo(map);
                        
                        L.control.layers({
                        "Terrain (default)": terrain,
                        "Streets": streets,
                        "Imperium": imperium }).addTo(map);
                        
                        geojson.addTo(map);
 
                     
                        ]]>
                    </script>)
               else ''
};

(:~
 : Builds search form, called from search-form.xqm
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*)) {   
    if(exists(request:get-parameter-names())) then ''
    else <div>{search-form:show-form()}</div>
};
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*)) {
<div class="well" style="background-color:white;">
<div>{search:build-geojson($node,$model)}</div>
{
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    let $kwic := kwic:summarize($hit, <config width="40" table="no"/>)
    let $id := substring-after($hit/@xml:id,'place-')
    return
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="span10 offset1">
                <div class="result">
                  <div class="span1" style="margin-right:-1em;">
                    <span class="label">{$search:start + $p - 1}</span>
                  </div>
                  <div class="span9">  
                    <p style="font-weight:bold padding:.5em;">
                        <a href="/place/{$id}.html">
                        <bdi dir="ltr" lang="en" xml:lang="en">
                            {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']}
                        </bdi>
                        <bdi dir="ltr" lang="en" xml:lang="en"> ({string($hit/@type)})</bdi>
                        {
                            if($hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']) then 
                                (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                                <bdi dir="rtl" lang="syr" xml:lang="syr">
                                    {$hit/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr']}
                                </bdi>)
                             else ''  
                        }
                        </a>
                    </p>
                    <div style="margin-bottom:1em; margin-top:-1em; padding-left:1em;">
                        {$hit/tei:desc[starts-with(@xml:id,'abstract')]/descendant-or-self::text()}
                    </div>
                  </div>
                </div>
            </div>
        </div>
   }
</div>
};

(:~
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*)) {
    if(exists(request:get-parameter-names())) then (search:pageination($node,$model),search:show-hits($node, $model))
    else ''
};