(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace spear="http://syriaca.org//spear";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";
import module namespace d3="http://syriaca.org//d3" at "d3.xqm";

import module namespace timeline="http://syriaca.org//timeline" at "timeline.xqm";
import module namespace tei2="http://syriaca.org//tei2html" at "tei2html.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $spear:id {request:get-parameter('id', '')};
declare variable $spear:sort {request:get-parameter('sort', '') cast as xs:string};

(:~
 : Build persons view
 : @param $id persons URI
 :)
declare %templates:wrap function spear:get-spear-data($node as node(), $model as map(*), $view){
if($view = 'factoid') then 
    map {"spear-data" := collection($config:app-root || "/data/spear/tei")//tei:div[descendant::*[@ref=$spear:id]]}
else if($view = 'event') then
    map {"spear-data" := collection($config:app-root || "/data/spear/tei")//tei:div[tei:listEvent]}            
else ()
};

declare %templates:wrap function spear:uri($node as node(), $model as map(*)){
    string($spear:id)
};

(:~
 : Checks for record in Syriaca.org
:)
declare function spear:canonical-rec(){
    collection($config:app-root || "/data/")//tei:idno[. = $spear:id]
};

(:~
 : Checks for record in Syriaca.org, uses connical record as title, otherwise uses spear data
:)
declare %templates:wrap function spear:h1($node as node(), $model as map(*)){
    let $data := $model("spear-data")[1]
    let $rec-exists := spear:canonical-rec()  
    let $title :=  
        if($rec-exists) then $rec-exists/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"]
        else $data/tei:listPerson/descendant::tei:persName[1] | $data/descendant::tei:placeName[1]
    return app:tei2html(
               <body xmlns="http://www.tei-c.org/ns/1.0">
                    <srophe-title>
                        {$title}
                    </srophe-title>
                </body>)
};

(:~
 : Checks link to related record
    if(contains($spear:id,'person') then 'Persons databse' 
    else 'The Syriac Gazetteer'
    NOTE: wouldnt it be nice to pull map from person record here? , maybe even just with jquery... 
             <div class="related">
             <div id="related"></div>
              <script>
                <![CDATA[
                $( "#related" ).load( "]]>{$spear:id}<![CDATA[ #placenames" );
                ]]>
             </script>
             </div>
:)
declare %templates:wrap function spear:related-rec($node as node(), $model as map(*)){
    let $data := $model("spear-data")[1]
    let $rec-exists := spear:canonical-rec()  
    let $type := string($rec-exists/ancestor::tei:place/@type)
    let $geo := $rec-exists/ancestor::tei:body//tei:geo
    let $abstract := $rec-exists/ancestor::tei:body//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $rec-exists/ancestor::tei:body//tei:note[@type='abstract']
    return
        if($rec-exists) then
            <div class="well">
             <h3>{if(contains($spear:id,'person')) then 'From Persons database' else 'From The Syriac Gazetteer' }</h3>
                {
                (if($geo) then 
                    <div>
                        <div>
                            {geo:build-map($geo,'','')}
                        </div>
                        <div>
                            <div id="type">
                                 <p><strong>Place Type: </strong>
                                     <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
                                 </p>
                             </div>
                             {
                                if($data//tei:location) then
                                    <div id="location">
                                        <h4>Location</h4>
                                        <ul>
                                        {
                                            for $location in $data//tei:location
                                            return app:tei2html($location)
                                        }
                                        </ul>
                                    </div>
                                else ()
                                }
                        </div>    
                    </div>
                else (),
                app:tei2html($abstract)
                )
                }
               <p><hr/>View full entry in <a href="{$spear:id}">{if(contains($spear:id,'person')) then 'Persons database' else 'The Syriac Gazetteer' }</a></p>
            </div> 
        else ()    
};

declare %templates:wrap function spear:names($node as node(), $model as map(*)){
    for $persName in $model("spear-data")//tei:listPerson/tei:person/tei:persName
    return 
        if($persName/text() or $persName/child::*) then
            <span dir="ltr" class="label label-default pers-label">{app:tei2html($persName)}</span>
        else ()    
};

declare %templates:wrap function spear:timeline($node as node(), $model as map(*), $dates){
let $data := $model("spear-data")
return
    if($dates = 'personal') then 
        if($data//tei:birth[@when or @notBefore or @notAfter] or $data//death[@when or @notBefore or @notAfter] or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
                <div class="row">
                        <div class="col-md-9">
                            <div class="timeline">
                                <div>{timeline:timeline($data, 'Events Timeline')}</div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <h4>Dates</h4>
                            <ul class="list-unstyled">
                                {
                                 for $date in $data//tei:birth[@when] | $data//tei:birth[@notBefore] | $data//tei:birth[@notAfter] 
                                 | $data//tei:death[@when] |$data//tei:death[@notBefore] |$data//tei:death[@notAfter]| 
                                 $data//tei:floruit[@when] | $data//tei:floruit[@notBefore]| $data//tei:floruit[@notAfter] 
                                 | $data//tei:state[@when] | $data//tei:state[@notBefore] | $data//tei:state[@notAfter] | $data//tei:state[@from] | $data//tei:state[@to]
                                 return 
                                    <li>{app:tei2html($date)}</li>
                                }
                            </ul>
                        </div>
                    </div>
        else ()
     else if($dates = 'events') then
        <div class="timeline">
            <h3>Events</h3>
            <div>{timeline:timeline($data//tei:event, 'Events Timeline')}</div>
        </div>
     else ()
};

declare %templates:wrap function spear:dates($node as node(), $model as map(*)){
let $data := $model("spear-data")
return 
    if($data//tei:birth or $data//tei:death or $data//tei:floruit or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
        (
            <h4>Dates</h4>,
            <ul class="list-unstyled">
            {
                for $date in $data//tei:birth | $data//tei:death | $data//tei:floruit | $data//tei:state[@when or @notBefore or @notAfter or @to or @from]
                return 
                    <li>{app:tei2html($date)}</li>
                }
            </ul>
        )
    else ()
};


declare %templates:wrap function spear:bibl($node as node(), $model as map(*)){
let $sources := $model("spear-data")[1]
return app:tei2html($sources)
};

declare %templates:wrap function spear:citation($node as node(), $model as map(*)){
let $citation := $model("spear-data")[1]
return app:tei2html($citation)
}; 

(:
should make these specific to the main person, create new map with just main pers defs:
floruit, gender/sex, ethnic label, languages spoken, religious affiliation, and 
:)
declare %templates:wrap function spear:state($node as node(), $model as map(*)){
let $data := $model("spear-data")
return
    if($data//tei:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]) then 
        for $state in $data//tei:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]
        return <p>{app:tei2html($state)}</p>
    else ()
};

declare %templates:wrap function spear:langKnown($node as node(), $model as map(*)){
let $langKnown := $model("spear-data")//tei:langKnown
return
  app:tei2html($langKnown)  
};

declare %templates:wrap function spear:ethnicity($node as node(), $model as map(*)){
let $ethnicity := $model("spear-data")//tei:ethnicity
return
  app:tei2html($ethnicity)  
};
declare %templates:wrap function spear:faith($node as node(), $model as map(*)){
let $faith := $model("spear-data")//tei:faith
return
  app:tei2html($faith)  
};
declare %templates:wrap function spear:education($node as node(), $model as map(*)){
let $education := $model("spear-data")//tei:education
return
  app:tei2html($education)  
};
(:
: Events for persons and places are more complicated, group by @type attestation
:)
declare %templates:wrap function spear:events($node as node(), $model as map(*)){
(:add if spear:date then sort, else no sort
<span class="anchor"/>
:)
<div id="events-list">
    {
    let $data := $model("spear-data")
    return
    if($spear:sort = 'date') then
        <ul>
        {
            for $event in $data//tei:event
            let $date := substring($event/descendant::tei:reg/tei:date[1]/@syriaca-computed-start,1,2)
            group by $date
            order by $date ascending
            return
            <li>
                <h4>
                {
                    if($date !='') then concat(substring-after($date,'0'),'00') 
                    else 'Date Unknown'
                }
                </h4>
                <ul>
                    {
                        for $e in $event//tei:desc
                        return app:tei2html($e)
                    }
                </ul>
            </li>
         }
         </ul>
    else
        <ul>
        {
            for $event in $data//tei:event
            for $e in $event//tei:desc
            return app:tei2html($e)
         }
        </ul>
         }
</div>
};

declare %templates:wrap function spear:link-icons-list($node as node(), $model as map(*)){
let $data := $model("spear-data")
let $links:=
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data//tei:person//tei:idno, $data//tei:person//tei:location}
        </see-also>
    </body>
return app:tei2html($links)
};

declare %templates:wrap function spear:get-visualizations($node as node(), $model as map(*)){
let $relationships := $model("spear-data")
return
  d3:relationships($relationships)  
};
(:
declare function spear:get-visualizations($node as node(), $model as map(*)){
let $data := let $data := $model("spear-data")
return d3:relationships($data)
};
:)


