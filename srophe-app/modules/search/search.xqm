xquery version "3.0";

module namespace search="http://syriaca.org//search";
import module namespace facets="http://syriaca.org//facets" at "../lib/facets.xqm";
import module namespace app="http://syriaca.org//templates" at "../app.xql";
import module namespace persons="http://syriaca.org//persons" at "persons-search.xqm";
import module namespace places="http://syriaca.org//places" at "places-search.xqm";
import module namespace spears="http://syriaca.org//spears" at "spear-search.xqm";
import module namespace ms="http://syriaca.org//ms" at "ms-search.xqm";
import module namespace common="http://syriaca.org//common" at "common.xqm";
import module namespace geo="http://syriaca.org//geojson" at "../lib/geojson.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Shared global parameters for building search paging function
:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:perpage {request:get-parameter('perpage', 1) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};


(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string := 
                        if($coll = 'persons') then persons:query-string()
                        else if($coll ='saints') then persons:saints-query-string()
                        else if($coll ='spear') then spears:query-string()
                        else if($coll = 'places') then places:query-string()
                        else if($coll = 'manuscripts') then ms:query-string()
                        else search:query-string($collection)
    return                         
    map {"hits" := 
                let $hits := util:eval($eval-string)    
                for $hit in $hits
                order by ft:score($hit) descending
                return $hit
         }
};

(:~
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
concat("collection('",$config:app-root,"/data/",$collection,"')//tei:body",
    places:keyword(),
    places:place-name(),
    persons:name()
    )
};

declare function search:search-api($q,$place,$person){
let $keyword-string := 
    if(exists($q) and $q != '') then concat("[ft:query(.,'",common:clean-string($q),"',common:options())]")
    else ()    
let $place-name := 
    if(exists($place) and $place != '') then concat("[ft:query(descendant::tei:placeName,'",common:clean-string($place),"',common:options())]")
    else ()
let $pers-name := 
    if(exists($person) and $person != '') then concat("[ft:query(descendant::tei:persName,'",common:clean-string($person),"',common:options())]")
    else ()
let $query-string := 
    concat("collection('/db/apps/srophe/data')//tei:body",
    $keyword-string,$pers-name,$place-name)
return $query-string
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    if($collection = 'persons') then persons:search-string()
    else if($collection ='spear') then spears:search-string()
    else places:search-string()
};

declare %templates:wrap function search:spear-facets($node as node(), $model as map(*)){
if(exists(request:get-parameter-names())) then 
    <div>
     <h4>Browse by</h4>
     {
        let $facet-nodes := $model('hits')
        let $facets := $facet-nodes//tei:persName | $facet-nodes//tei:placeName | $facet-nodes//tei:event 
        | $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt[1]/tei:title[1]
        return facets:facets($facets)
     }
    </div>
else ()    
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?){
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
        <div class="row" xmlns="http://www.w3.org/1999/xhtml">
            <div class="col-sm-5">
            <h4>Search results:</h4>
                <p class="col-md-offset-1">{$total-result-count} matches for {search:search-string($collection)}.</p>
                <!-- for debugging xpath <br/>{persons:query-string()}-->
            </div>
            {if(search:hit-count($node, $model) gt $perpage) then 
              <div class="col-md-7">
                       <ul class="pagination  pull-right">
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
             else '' 
             }
        </div>    

return 
   if(exists(request:get-parameter-names())) then $pagination-links
   else ()
};

declare function search:build-geojson($node as node()*, $model as map(*)){
let $geo-hits := $model("hits")//tei:geo
return
    if(count($geo-hits) gt 1) then
         (<div id="map" style="height: 250px;"/>,
         <div class="pull-right">*{count($geo-hits)} of {search:hit-count($node,$model)} places have coordinates and are shown on this map. 
         <button class="btn btn-link" data-toggle="modal" data-target="#map-selection" id="mapFAQ">Read more...</button>
         </div>,
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>,
         <script type="text/javascript">
                <![CDATA[
                    $('#mapFAQ').click(function(){
                            $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                            $('#map-selection').modal({show:true});
                        });
                     });   
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
                        
                        var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 4});
                        
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
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ''
    else 
        if($collection = 'persons') then <div>{persons:search-form()}</div>
        else if($collection = 'saints') then <div>{persons:search-form()}</div>
        else if($collection ='spear') then <div>{spears:search-form()}</div>
        else if($collection ='manuscripts') then <div>{ms:search-form()}</div>
        else <div>{places:search-form()}</div>
};

(:~
 : Generic search output   
:)
declare function search:results-node($hit){
    let $root := $hit    
    let $title := $root/ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title
    let $id := 
        if($hit//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')]) then
                string($hit//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1])
        else string($hit//tei:div[1]/@uri)    
    return
        <p style="font-weight:bold padding:.5em;">
            <a href="{$id}">{app:tei2html($title)}</a>
        </p>
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="well" style="background-color:white;">
<div>{search:build-geojson($node,$model)}</div>
{
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    return
        <div class="row" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="col-md-10 col-md-offset-1">
                <div class="result">
                  <div class="col-md-1" style="margin-right:-1em;">
                    <span class="label label-default">{$search:start + $p - 1}</span>
                  </div>
                  <div class="col-md-9"> 
                    {
                    if($collection = 'persons') then persons:results-node($hit)
                    else if($collection = 'saints') then persons:saints-results-node($hit)
                    else if($collection ='spear') then spears:results-node($hit)
                    else if($collection ='manuscripts') then ms:results-node($hit)
                    else search:results-node($hit)} 
                    <div style="margin-bottom:1em; margin-top:-1em; padding-left:1em;">
                        {$hit//tei:desc[starts-with(@xml:id,'abstract')]/descendant-or-self::text()}
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
declare %templates:wrap function search:build-page($node as node()*, $model as map(*), $collection as xs:string?) {
    if(exists(request:get-parameter-names())) then search:show-hits($node, $model, $collection)
    else ()
};