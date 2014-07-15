xquery version "3.0";

module namespace search="http://syriaca.org//search";
(:import module namespace search-form="http://syriaca.org//search-form" at "search-form.xqm";:)
import module namespace persons="http://syriaca.org//persons" at "persons-search.xqm";
import module namespace places="http://syriaca.org//places" at "places-search.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Shared global parameters for building search paging function
:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:perpage {request:get-parameter('perpage', 1) cast as xs:integer};


(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?){
    let $eval-string := 
                        if($collection = 'persons') then persons:query-string()
                        else places:query-string()
    return                         
    map {"hits" := 
                let $hits := util:eval($eval-string)    
                for $hit in $hits
                order by ft:score($hit) descending
                return $hit
    }
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    if($collection = 'persons') then persons:search-string()
    else places:search-string()
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
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml">
            <div class="span5">
            <h4>Search results:</h4>
                <p class="offset1">{$total-result-count} matches for {search:search-string($collection)}.</p>
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
             else '' 
             }
        </div>    

return 
   ($pagination-links,
   if(search:hit-count($node,$model) gt 0) then ''
   else <div>{search:show-form($node,$model, $collection)}</div>
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
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ''
    else 
        if($collection = 'persons') then <div>{persons:search-form()}</div> 
        else <div>{places:search-form()}</div>
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="well" style="background-color:white;">
<div>{search:build-geojson($node,$model), persons:query-string()}</div>
{
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    return
        <div class="row-fluid" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="span10 offset1">
                <div class="result">
                  <div class="span1" style="margin-right:-1em;">
                    <span class="label">{$search:start + $p - 1}</span>
                  </div>
                  <div class="span9"> 
                    {if($collection = 'persons') then persons:results-node($hit) else places:results-node($hit)} 
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
    if(exists(request:get-parameter-names())) then (search:pageination($node,$model, $collection),search:show-hits($node, $model, $collection))
    else ''
};