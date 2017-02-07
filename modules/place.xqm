(:~   
 : Builds place page and place page functions
 :)
xquery version "3.0";

module namespace place="http://syriaca.org/place";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

import module namespace templates="http://exist-db.org/xquery/templates" ;

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace transform="http://exist-db.org/xquery/transform";

(:~   
 : Parameters passed from the url 
 :)
declare variable $place:id {request:get-parameter('id', '')};
declare variable $place:status {request:get-parameter('status', '')};

(:~ 
 : Simple get record function, retrieves tei record based on idno
 : @param $place:id syriaca.org uri 
:)
declare 
    %templates:wrap 
function place:get-rec($node as node(), $model as map(*), $collection) {
    app:get-rec($node, $model, $collection)
(:
if($place:id) then 
    let $id :=
        if(contains(request:get-uri(),$global:base-uri)) then $place:id
        else if(contains(request:get-uri(),'/geo/') or contains(request:get-uri(),'/place/')) then concat($global:base-uri,'/place/',$place:id) 
        else $place:id
    return map {"data" := collection($global:data-root)//tei:idno[. = $id]/ancestor::tei:TEI}
else map {"data" := 'Page data'} 
:)
};

(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : @param $place:id if id is present find TEI title, otherwise use title of sub-module
:)
declare %templates:wrap function place:app-title($node as node(), $model as map(*), $coll){
    app:app-title($node, $model, $coll)
};  

(:
 : Pass necessary elements to h1 xslt template
:)
declare %templates:wrap function place:h1($node as node(), $model as map(*)){
    let $title := $model("data")//tei:place
    let $title-nodes := 
            <srophe-title xmlns="http://www.tei-c.org/ns/1.0">
                {($title//tei:placeName[@syriaca-tags='#syriaca-headword'],$title/descendant::tei:idno, $title/descendant::tei:location)}
            </srophe-title>
    return global:tei2html($title-nodes)
};

declare %templates:wrap function place:abstract($node as node(), $model as map(*)){
    let $abstract := $model("data")//tei:place/tei:desc[starts-with(@xml:id,'abstract')]
    let $abstract-nodes := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {$abstract}
    </place>
    return global:tei2html($abstract)
};

declare function place:type-details($data, $type){
<div class="clearfix" xmlns="http://www.w3.org/1999/xhtml">
    <div id="type">
        <p><strong>Place Type: </strong>
            <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
        </p>
    </div>
    {
    if($data//tei:location) then
        <div id="location" xmlns="http://www.w3.org/1999/xhtml">
            <h4>Location</h4>
            <ul>
            {
                for $location in $data//tei:location
                return global:tei2html($location)
            }
            </ul>
        </div>
    else ()
    }
</div>
};

(:~
 : Add map and location information
:)
declare %templates:wrap function place:location-details($node as node(), $model as map(*)){
let $data := $model("data")
let $type := string($model("data")//tei:place/@type)
let $geo := $data//tei:geo[1]
return 
    if($data//tei:geo) then 
        <div class="row" xmlns="http://www.w3.org/1999/xhtml">
            <div class="col-md-7">
                {maps:build-map($data,0)}
            </div>
            <div class="col-md-5">
                {place:type-details($data, $type)}
            </div>    
        </div>
    else place:type-details($data, $type)
};

(:~
 : Add descriptions information 
:)
declare %templates:wrap function place:description($node as node(), $model as map(*)){
    let $desc-nodes := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {for $desc in $model("data")//tei:place/tei:desc[not(starts-with(@xml:id,'abstract'))] return $desc}
    </place>
    return global:tei2html($desc-nodes)
};

(:~
 : Add notes information
:)
declare %templates:wrap function place:notes($node as node(), $model as map(*)){
    let $notes-nodes := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $note in $model("data")//tei:place/tei:note
                return $note
            }
    </place>
    return global:tei2html($notes-nodes)
};

(:~
 : Add descriptions events
:)
declare %templates:wrap function place:events($node as node(), $model as map(*)){
    let $events-nodes := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $event in $model("data")//tei:place/tei:event
                return $event
            }
    </place>
    return global:tei2html($events-nodes)
};

(:~
 : Get nested locations
 : Pull all places records with @type="nested" and also references current place id in @ref
 :            <location type="nested" source="#bib110-3">
 :              <region ref="http://syriaca.org/place/722">Mosul region</region>
 :           </location>       
:)
declare function place:nested-loc($node as node(), $model as map(*)){
    let $ref-id := concat($global:base-uri,'/place/',$place:id)
    return 
        global:tei2html(<place xmlns="http://www.tei-c.org/ns/1.0">
        {
            for $nested-loc in collection($global:data-root || "/places/tei")//tei:location[@type="nested"]/tei:*[@ref=$ref-id]
            let $parent-name := $nested-loc//tei:placeName[1]
            let $place-id := substring-after($nested-loc/ancestor::*/tei:place[1]/@xml:id,'place-')
            let $place-type := $nested-loc/ancestor::*/tei:place[1]/@type
            return 
                <nested-place id="{$place-id}" type="{$place-type}">
                    {$nested-loc/ancestor::*/tei:placeName[1]}
                </nested-place>
          }      
        </place>)
};

(:~
 : Confessions list built from refs in tei to /srophe/documentation/confessions.xml
:)
declare function place:confessions($node as node(), $model as map(*)){
    let $data := $model("data")//tei:place
    return if($data/tei:state[@type='confession']) then 
        let $confessions := doc($global:app-root || "/documentation/confessions.xml")//tei:list
        return 
        global:tei2html(
        <place xmlns="http://www.tei-c.org/ns/1.0">
            <confessions xmlns="http://www.tei-c.org/ns/1.0">
               {(
                $confessions,
                for $event in $data/tei:event
                return $event,
                for $state in $data/tei:state[@type='confession']
                return $state)
                }
            </confessions>
        </place>)
     else ()   
 };
 
(:~
 : Get related place names      
 : ex: <relation name="contained" active="http://syriaca.org/place/145 http://syriaca.org/place/166" passive="#place-78" source="#bib78-1" to="0363"/>
:)
declare function place:related-places($node as node(), $model as map(*)){
 let $rec := $model("data")
 return 
    global:tei2html(
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <div id="heading">{$model("data")//tei:place/tei:placeName[1]}</div>
        <tei:related-places>
                {
                    for $related in $rec//tei:relation
                    let $active := 
                        for $rel-item in tokenize($related/@active,' ')
                        let $item-id := tokenize($rel-item, '/')[last()]
                        let $item-uri := $rel-item
                        let $place-id := concat('place-',$item-id)
                        return
                            if(starts-with($item-id,'#')) then ()
                            else
                                <relation id="{$item-id}" uri="{$item-uri}" varient="active">
                                {
                                    (for $att in $related/@*
                                        return
                                             attribute {name($att)} {$att},                      
                                    for $get-related in collection($global:data-root || "/places/tei")/id($place-id)
                                    return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                                }
                                </relation>
                            
                    let $passive := 
                        for $rel-item in tokenize($related/@passive,' ')
                        let $item-id := tokenize($rel-item, '/')[last()]
                        let $item-uri := $rel-item
                        let $place-id := concat('place-',$item-id)
                        return
                            if(starts-with($item-id,'#')) then ()
                            else
                            <relation id="{$item-id}" uri="{$item-uri}" varient="passive">
                            {
                                (for $att in $related/@*
                                    return
                                         attribute {name($att)} {$att},                      
                                for $get-related in collection($global:data-root || "/places/tei")/id($place-id)
                                return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                            }
                            </relation>
                    let $mutual := 
                            if($related/@mutual) then
                            let $mutual-string := normalize-space($related/@mutual)
                            return
                                <relation varient="mutual">
                                    {
                                        for $rel-item in tokenize($mutual-string,' ')
                                        let $item-id := tokenize($rel-item, '/')[last()]
                                        let $item-uri := $rel-item
                                        let $place-id := concat('place-',$item-id)
                                        return
                                            <mutual id="{$item-id}">{
                                            (for $att in $related/@*
                                            return
                                                 attribute {name($att)} {$att},                      
                                            for $get-related in collection($global:data-root || "/places/tei")/id($place-id)
                                            let $type := string($get-related/@type)
                                            return 
                                                (attribute type {$type}, $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']))
                                            }
                                            </mutual>
                                    }
                                </relation>
                              else ''  
        
                    return ($active,$passive,$mutual)
                }
        </tei:related-places>
    </place>)
};

(:
 : Return bibls for use in sources 
:)
declare %templates:wrap function place:sources($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $sources := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:place/tei:bibl}
    </place>
    return global:tei2html($sources)
};

(:
 : Return place names
:)
declare %templates:wrap function place:place-name($node as node(), $model as map(*)){
    let $names := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {$model("data")//tei:place/tei:placeName}
    </place>
    return global:tei2html($names)
};

(:
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function place:citation($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $header := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </place>
    return global:tei2html($header)
};

(:~
 : Prints link icons on left
:)
declare %templates:wrap function place:link-icons-list($node as node(), $model as map(*)){
let $data := $model("data")
let $links:=
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data/descendant::tei:place/descendant::tei:idno, $data/descendant::tei:place/descendant::tei:location}
        </see-also>
    </place>
return global:tei2html($links)
};



(:~
 : Add contact form for submitting corrections
:)
declare %templates:wrap function place:contact($node as node(), $model as map(*)){
<div class="modal fade" id="feedback" tabindex="-1" role="dialog" aria-labelledby="feedbackLabel" aria-hidden="true" xmlns="http://www.w3.org/1999/xhtml">
    <div class="modal-dialog">
        <div class="modal-content">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">x</span><span class="sr-only">Close</span></button>
            <h2 class="modal-title" id="feedbackLabel">Corrections/Additions?</h2>
        </div>
        <form action="/exist/apps/srophe/modules/email.xql" method="post" id="email" role="form">
            <div class="modal-body" id="modal-body">
                <!-- More information about submitting data from howtoadd.html -->
                <p><strong>Notify the editors of a mistake:</strong>
                <a class="btn btn-link togglelink" data-toggle="collapse" data-target="#viewdetails" data-text-swap="hide information">more information...</a>
                </p>
                <div class="container">
                    <div class="collapse" id="viewdetails">
                    <p>Using the following form, please inform us which page URI the mistake is on, where on the page the mistake occurs,
                    the content of the correction, and a citation for the correct information (except in the case of obvious corrections, such as misspelled words). 
                    Please also include your email address, so that we can follow up with you regarding 
                    anything which is unclear. We will publish your name, but not your contact information as the author of the  correction.</p>
                    <h4>Add data to an existing entry</h4>
                    <p>The Syriac Gazetteer is an ever expanding resource  created by and for users. The editors actively welcome additions to the gazetteer. If there is information which you would like to add to an existing place entry in The Syriac Gazetteer, please use the link below to inform us about the information, your (primary or scholarly) source(s) 
                    for the information, and your contact information so that we can credit you for the modification. For categories of information which  The Syriac Gazetteer structure can support, please see the section headings on the entry for Edessa and  specify in your submission which category or 
                    categories this new information falls into.  At present this information should be entered into  the email form here, although there is an additional  delay in this process as the data needs to be encoded in the appropriate structured data format  and assigned a URI. A structured form for submitting  new entries is under development.</p>
                    </div>
                </div>
                <input type="text" name="name" placeholder="Name" class="form-control" style="max-width:300px"/>
                <br/>
                <input type="text" name="email" placeholder="email" class="form-control" style="max-width:300px"/>
                <br/>
                <input type="text" name="subject" placeholder="subject" class="form-control" style="max-width:300px"/>
                <br/>
                <textarea name="comments" id="comments" rows="3" class="form-control" placeholder="Comments" style="max-width:500px"/>
                <input type="hidden" name="id" value="{$place:id}"/>
                <input type="hidden" name="place" value="{string($model("data")//tei:place/tei:placeName[1])}"/>
                <!-- start reCaptcha API-->
                <div class="g-recaptcha" data-sitekey="6Lc8sQ4TAAAAAEDR5b52CLAsLnqZSQ1wzVPdl0rO"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" data-dismiss="modal">Close</button><input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
            </div>
        </form>
        </div>
    </div>
</div>
};