(:~
 : Builds place page and place page functions
 :)
xquery version "3.0";

module namespace place="http://syriaca.org//place";

import module namespace app="http://syriaca.org//templates" at "app.xql";
import module namespace geo="http://syriaca.org//geojson" at "geojson.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $place:id {request:get-parameter('id', '')};
declare variable $place:status {request:get-parameter('status', '')};

(:~
 : Retrieve place record
 : @param $id place id
 :)
declare function place:get-place($node as node(), $model as map(*)){
    let $placeid := concat('place-',$place:id)
    for $recs in collection($config:app-root || "/data/places/tei")/id($placeid)
    let $rec := $recs/ancestor::tei:TEI
    return map {"place-data" := $rec}
};

(:
 : Pass necessary element to h1 xslt template
 : NOTE: trouble with syr lang helper icon
:)
declare %templates:wrap function place:h1($node as node(), $model as map(*)){
    let $title := $model("place-data")//tei:place
    let $title-nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <srophe-title>
            {($title//tei:placeName[@syriaca-tags='#syriaca-headword'],$title/descendant::tei:idno, $title/descendant::tei:location)}
        </srophe-title>
    </body>
    return app:tei2html($title-nodes)
};

declare %templates:wrap function place:abstract($node as node(), $model as map(*)){
    let $abstract := $model("place-data")//tei:place/tei:desc[starts-with(@xml:id,'abstract')]
    let $abstract-nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
            {$abstract}
    </body>
    return app:tei2html($abstract)
};

declare function place:type-details($data, $type){
   (<div id="type">
        <p><strong>Place Type: </strong>
            <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
        </p>
    </div>,
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
    )
};

(:~
 : Add map and location information
:)
declare %templates:wrap function place:location-details($node as node(), $model as map(*)){
let $data := $model("place-data")
let $type := string($model("place-data")//tei:place/@type)
let $geo := $data//tei:geo[1]
return 
    if($data//tei:geo) then 
        <div class="row">
            <div class="col-md-7">
                {geo:build-map($geo,'','')}
            </div>
            <div class="col-md-5">
                {place:type-details($data, $type)}
            </div>    
        </div>
    else         
        <div class="col-md-12">
            {place:type-details($data, $type)}
        </div>
};

(:~
 : Add descriptions information
:)
declare %templates:wrap function place:description($node as node(), $model as map(*)){
    let $desc-nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
            {for $desc in $model("place-data")//tei:place/tei:desc[not(starts-with(@xml:id,'abstract'))] return $desc}
    </body>
    return app:tei2html($desc-nodes)
};

(:~
 : Add notes information
:)
declare %templates:wrap function place:notes($node as node(), $model as map(*)){
    let $notes-nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $note in $model("place-data")//tei:place/tei:note
                return $note
            }
    </body>
    return app:tei2html($notes-nodes)
};

(:~
 : Add descriptions events
:)
declare %templates:wrap function place:events($node as node(), $model as map(*)){
    let $events-nodes := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $event in $model("place-data")//tei:place/tei:event
                return $event
            }
    </body>
    return app:tei2html($events-nodes)
};

(:~
 : Retrieve place title for metadata function.
 : Function is called by metadata.xqm
 :)
declare function place:get-place-title(){
    'temp'
    (:
    let $title := string(place:get-place-rec()/child::*/tei:fileDesc/tei:titleStmt/tei:title[1])
    return concat('The Syriac Gazetteer: ',$title)
    :)
};

(:~
 : Retrieve place title for metadata function.
 : Function is called by metadata.xqm
 :)
declare function place:get-place-title($node as node(), $model as map(*)){
    let $title := $model("place-data")//tei:place
    return 
    string($title//tei:placeName[@syriaca-tags='#syriaca-headword'])

    (:
    let $title := string(place:get-place-rec()/child::*/tei:fileDesc/tei:titleStmt/tei:title[1])
    return concat('The Syriac Gazetteer: ',$title)
    :)
};

(:~
 : NOTE BROKEN, also , persons does not have metadata??
 : Builds Dublin Core metadata.
 : Function is called by metadata.xqm
 :)
declare function place:get-metadata() {
(:
    for $rec in place:get-place()
    let $description := if(exists($rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')])) then
                            <meta name="description" content="{$rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')]/text()}" />
                        else ''    
    let $title :=  <meta name="DC.title" property="dc.title" lang="en" content="{string($rec/child::*/tei:fileDesc/tei:titleStmt/tei:title[1])}"/>                       
    let $authors := let $author-name := distinct-values($rec/descendant::tei:titleStmt/tei:editor) 
                    for $author in $author-name
                    return <meta name="DC.creator" property="dc.creator" lang="en" content="{$author}" />
    let $contributors := let $contrib-name := distinct-values($rec/descendant::tei:titleStmt/tei:respStmt/tei:name) 
                         for $contributor in $contrib-name                        
                         return    <meta name="DC.contributor" property="dc.contributor" lang="en" content="{$contributor}" />              
                        
    let $identifier := <meta name="DC.identifier" property="dc.identifier" content="http://syriaca.org/place/{$place:id}" />
    let $rights := (<meta name="DC.rights" property="dc.rights" lang="en"  content="{normalize-space(string-join($rec/descendant::tei:publicationStmt/tei:availability/tei:licence/tei:p,' '))}"/>,
                    <meta name="DCTERMS.license" property="dcterms.license" content="http://creativecommons.org/licenses/by/3.0/" />)
    let $date :=     <meta name="DC.date" property="dc.date" lang="en" content="{$rec/descendant::tei:publicationStmt/tei:date}" />
    return ($description,$title,$contributors,$authors,$identifier,$rights,$date)
 :)
 'Temp'
};

(:~
 : Get nested locations
 : Pull all places records with @type="nested" and also references current place id in @ref
 :            <location type="nested" source="#bib110-3">
 :              <region ref="http://syriaca.org/place/722">Mosul region</region>
 :           </location>       
:)
declare function place:nested-loc($node as node(), $model as map(*)){
    let $ref-id := concat('http://syriaca.org/place/',$place:id)
    for $nested-loc in collection($config:app-root || "/data/places/tei")//tei:location[@type="nested"]/tei:*[@ref=$ref-id]
    let $parent-name := $nested-loc//tei:placeName[1]
    let $place-id := substring-after($nested-loc/ancestor::*/tei:place[1]/@xml:id,'place-')
    let $place-type := $nested-loc/ancestor::*/tei:place[1]/@type
    return app:tei2html(
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <nested-place id="{$place-id}" type="{$place-type}">
            {$nested-loc/ancestor::*/tei:placeName[1]}
        </nested-place>
    </body>)
};

declare function place:confessions($node as node(), $model as map(*)){
    let $data := $model("place-data")//tei:place
    return if($data/tei:state[@type='confession']) then 
        let $confessions := doc($config:app-root || "/documentation/confessions.xml")//tei:list
        return
        app:tei2html(
        <body xmlns="http://www.tei-c.org/ns/1.0">
            <confessions xmlns="http://www.tei-c.org/ns/1.0">
               {(
                $confessions,
                for $event in $data/tei:event
                return $event,
                for $state in $data/tei:state[@type='confession']
                return $state)
                }
            </confessions>
        </body>)
     else ()   
 };
 
(:~
 : Get related place names    
 : <relation name="contained" active="http://syriaca.org/place/145 http://syriaca.org/place/166" passive="#place-78" source="#bib78-1" to="0363"/>
:)
declare function place:related-places($node as node(), $model as map(*)){
    app:tei2html(
    <body xmlns="http://www.tei-c.org/ns/1.0">
    <tei:place>
        <div id="heading">
        {$model("place-data")//tei:place/tei:placeName[1]}
        </div>
        <tei:related-places>
        {
            for $related in $model("place-data")//tei:relation
            let $active := 
                for $rel-item in tokenize($related/@active,' ')
                let $item-id := tokenize($rel-item, '/')[last()]
                let $item-uri := $rel-item
                let $place-id := concat('place-',$item-id)
                return
                    <tei:relation id="{$item-id}" uri="{$item-uri}" varient="active">
                    {
                        (for $att in $related/@*
                            return
                                 attribute {name($att)} {$att},                      
                        for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                        return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                    }
                    </tei:relation>
            let $passive := 
                for $rel-item in tokenize($related/@passive,' ')
                let $item-id := tokenize($rel-item, '/')[last()]
                let $item-uri := $rel-item
                let $place-id := concat('place-',$item-id)
                return
                    <tei:relation id="{$item-id}" uri="{$item-uri}" varient="passive">
                    {
                        (for $att in $related/@*
                            return
                                 attribute {name($att)} {$att},                      
                        for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                        return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                    }
                    </tei:relation>
            let $mutual := 
                    if($related/@mutual) then
                    let $mutual-string := normalize-space($related/@mutual)
                    return
                        <tei:relation varient="mutual">
                            {
                                for $rel-item in tokenize($mutual-string,' ')
                                let $item-id := tokenize($rel-item, '/')[last()]
                                let $item-uri := $rel-item
                                let $place-id := concat('place-',$item-id)
                                return
                                    <tei:mutual id="{$item-id}">{
                                    (for $att in $related/@*
                                    return
                                         attribute {name($att)} {$att},                      
                                    for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                                    let $type := string($get-related/@type)
                                    return 
                                        (attribute type {$type}, $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']))
                                    }
                                    </tei:mutual>
                            }
                        </tei:relation>
                      else ''  

            return ($active,$passive,$mutual)
        }
        </tei:related-places>
    </tei:place>
    </body>)
};

(:
 : Return bibls for use in sources
:)
declare %templates:wrap function place:sources($node as node(), $model as map(*)){
    let $rec := $model("place-data")
    let $sources := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:place/tei:bibl}
    </body>
    return app:tei2html($sources)
};

(:
 : Return place names
:)
declare %templates:wrap function place:place-name($node as node(), $model as map(*)){
    let $names := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <place>
            {$model("place-data")//tei:place/tei:placeName}
        </place>
    </body>
    return app:tei2html($names)
};

(:
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function place:citation($node as node(), $model as map(*)){
    let $rec := $model("place-data")
    let $header := 
    <body xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </body>
    return app:tei2html($header)
};

(:~ 
 : Pull together place page data   
 : Adds related places and nested locations to full TEI document
 : Passes xml to placepage.xsl for html transformation
:)
declare %templates:wrap function place:get-place-data($node as node(), $model as map(*)){
   for $rec in $model("place-data")
   let $buildRec :=
                <TEI
                    xml:lang="en"
                    xmlns:xi="http://www.w3.org/2001/XInclude"
                    xmlns:svg="http://www.w3.org/2000/svg"
                    xmlns:math="http://www.w3.org/1998/Math/MathML"
                    xmlns="http://www.tei-c.org/ns/1.0">
                    {
                        ($rec/child::*, place:related-places($node, $model),
                        place:nested-loc($node, $model),place:confessions($node, $model))
                    }
                    </TEI>
    let $cache :='Change value to force page refresh 5936'
    return
       (: $buildRec:) 
       transform:transform($buildRec, doc('../resources/xsl/placepage.xsl'),() )
};

