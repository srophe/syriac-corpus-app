xquery version "3.0";

module namespace app="http://syriaca.org//templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 <title>The Syriac Gazetteer | Edessa — ܐܘܪܗܝ Edessa</title>
        <meta name="viewport" content="width=device-width" />
        <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
        <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />
        <meta name="DC.subject" property="dc.subject" content="Geography, Ancient" />
        <meta name="DC.type" property="dc.type" content="Text" />
        <meta name="DC.isPartOf" property="dc.ispartof" content="The Syriac Gazetteer" />
        <meta name="DC.publisher" property="dc.publisher" lang="en" content="Syriaca.org: The Syriac Reference Portal" />
        
 <meta name="DC.creator" property="dc.creator" lang="en" content="Thomas A. Carlson" />
        <meta name="DC.creator" property="dc.creator" lang="en" content="David A. Michelson" />
        <meta name="DC.contributor" property="dc.contributor" lang="en" content="Robert Aydin" />
        <meta name="DC.contributor" property="dc.contributor" lang="en" content="Dayroyo Roger-Youssef Akhrass" />
        <meta name="DC.contributor" property="dc.contributor" lang="en" content="Anthony Davis" />

        <meta name="DC.date" property="dc.date" lang="en" content="2013-11-12" />
 :)
 (:
declare function app:get-metadata($rec) {
    let $description := if $rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')] then
                            <meta name="description" content="{$rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')]/text()}" />
                        else ''    
    let $title :=  <meta name="DC.title" property="dc.title" lang="en" content="{$rec/tei:title[@level='a']/text()}"/>                       
    let $identifier := <meta name="DC.identifier" property="dc.identifier" content="http://syriaca.org/place/{$id}" />
    let $rights := (<meta name="DC.rights" property="dc.rights" lang="en"  content="{$rec/descendant::tei:place/tei:licence}"/>,
                    <meta name="DCTERMS.license" property="dcterms.license" content="http://creativecommons.org/licenses/by/3.0/" />)
    let $date :=     <meta name="DC.date" property="dc.date" lang="en" content="{$rec/descendant::tei:publicationStmt/tei:date}" />  
    return 
};
:)

(:~
 :  Get place record use id parameter passed from url
 :)

declare function app:get-title(){
    if(exists($id)) then 'test'
    else 'test2'
};
declare function app:get-place($node as node(), $model as map(*)){
     map { "place-data" := collection($config:app-root || "/data/places/tei")//tei:place}
};


declare %templates:wrap function app:get-place-data($node as node(), $model as map(*)){ 
    for $place in $model("place-data")
    return string($place)
};