xquery version "3.0";
(:
 : Build ttl output for Gazetteer data. 
 : Based on examples: https://github.com/srophe/Linked-Data/blob/master/ShortEdessaPlace78inPGIF.ttl 
:)

module namespace tei2ttl="http://syriaca.org/tei2ttl";
import module namespace global="http://syriaca.org/global" at "global.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare option exist:serialize "method=text media-type=text/turtle indent=yes";

(: Create URI :)
declare function tei2ttl:make-uri($uri){
    concat('<',normalize-space($uri),'>')
};

(: Add language :)
declare function tei2ttl:make-lang($lang) as xs:string?{
    concat('@',$lang)
};

(: Build literal string, add lang if specified :)
declare function tei2ttl:make-literal($string, $lang) as xs:string?{
    concat('"',replace(normalize-space(string-join($string,' ')),'"',''),'"',
        if($lang != '') then tei2ttl:make-lang($lang) 
        else ())
    
};

(: Build basic triple string :)
declare function tei2ttl:make-triple($s as xs:string?, $o as xs:string?, $p as xs:string?) as xs:string* {
    concat('&#xa;', $s,' ', $o,' ', $p, ' ;')
};

(: Places descriptions :)
declare function tei2ttl:desc($rec) as xs:string* {
string-join(
for $desc in $rec/descendant::tei:desc
let $source := $desc/tei:quote/@source
return
    if($desc[@type='abstract'][not(@source)][not(tei:quote/@source)] or $desc[contains(@xml:id,'abstract')][not(@source)][not(tei:quote/@source)][. != '']) then 
        tei2ttl:make-triple('', 'dcterms:description', tei2ttl:make-literal($desc/text(),''))
    else 
        if($desc/child::* != '' or $desc != '') then 
            concat('&#xa; dcterms:description [',
                tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($desc, string($desc/@xml:lang))),
                    if($source != '') then
                       if($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p/tei:listBibl/tei:bibl/tei:ptr/@target = $source) then 
                            tei2ttl:make-triple('','dcterms:license', tei2ttl:make-uri(string($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target)))
                       else ()
                    else (),
            '];')
        else (), '')
};

(: Places ids :)
declare function tei2ttl:ids($rec) as xs:string* {
string-join(
for $id in $rec/descendant::tei:idno[@type='URI']
return 
    if($id[starts-with(.,'http://pleiades')]) then 
        tei2ttl:make-triple('','skos:exactMatch',tei2ttl:make-uri($id))
    else if($id[starts-with(.,'http://en.wikipedia.org')]) then 
        tei2ttl:make-triple('','skos:closeMatch',tei2ttl:make-uri($id))
    else (),''
    )
};

(: Place names :)
declare function tei2ttl:names($rec) as xs:string*{
string-join(
for $name in $rec/descendant::tei:placeName
return 
    if($name/parent::tei:place) then 
        concat('&#xa; lawd:hasName [',
            if($name[contains(@syriaca-tags,'#syriaca-headword')]) then
               tei2ttl:make-triple('','lawd:primaryForm',tei2ttl:make-literal($name/text(),$name/@xml:lang)) 
            else tei2ttl:make-triple('','lawd:variantForm',tei2ttl:make-literal($name/text(),$name/@xml:lang)), 
        '];')    
    else   
        if($name/ancestor::tei:location[@type='nested'][starts-with(@ref,'http://syriaca.org/')]) then
           tei2ttl:make-triple('','dcterms:isPartOf',tei2ttl:make-uri($name/@ref)) 
        else if($name[starts-with(@ref,'http://syriaca.org/')]) then  
            tei2ttl:make-triple('','skos:related',tei2ttl:make-uri($name/@ref))
        else (),'')
};

(: Locations with coords :)
declare function tei2ttl:geo($rec) as xs:string*{
string-join(
for $geo in $rec/descendant::tei:location[tei:geo]
return 
    concat('&#xa;geo:location [',
        tei2ttl:make-triple('','geo:lat',tei2ttl:make-literal(substring-before($geo/tei:geo,' '),'')),
        tei2ttl:make-triple('','geo:long',tei2ttl:make-literal(substring-after($geo/tei:geo,' '),'')),
    '];'),'')
};

(: Relations :)
declare function tei2ttl:relation($rec) as xs:string*{
string-join(
(
for $relation in $rec/descendant::tei:relation
return 
    if($relation/@name = 'contained') then 
        for $active in tokenize($relation/@active,' ')
        return tei2ttl:make-triple('','dcterms:isPartOf',tei2ttl:make-uri($active))
    else if($relation/@name = 'share-a-name') then 
        let $rel := normalize-space($relation/@mutual)
        for $mutual in tokenize($rel,' ')
        return 
            if(starts-with($mutual,'#')) then ()
            else tei2ttl:make-triple('','dcterms:relation',tei2ttl:make-uri($mutual))
    else (),
for $location-relation in $rec/descendant::tei:location[@type='nested']/child::*[starts-with(@ref,'http://syriaca.org/')]/@ref
return tei2ttl:make-triple('','dcterms:isPartOf',tei2ttl:make-uri($location-relation))
    ),'')
};

(: Prefixes :)
declare function tei2ttl:prefix() as xs:string{
"@prefix cito: <http://purl.org/spar/cito> .
@prefix cnt: <http://www.w3.org/2011/content#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix geosparql: <http://www.opengis.net/ont/geosparql#> .
@prefix gn: <http://www.geonames.org/ontology#> .
@prefix lawd: <http://lawd.info/ontology/> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix wdata: <https://www.wikidata.org/wiki/Special:EntityData/> .&#xa;"
};

(: Triples for a single record :)
declare function tei2ttl:make-triples($rec) as xs:string*{
let $id := replace($rec/descendant::tei:idno[starts-with(.,'http://syriaca.org/')][1],'/tei','')
return 
    concat(
    tei2ttl:make-triple(tei2ttl:make-uri($id), 'a', 'lawd:Place'),
    tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($rec/descendant::tei:titleStmt/tei:title[@level='a'][1]/descendant::text(),'')),
    tei2ttl:names($rec),
    tei2ttl:desc($rec),
    if($rec/descendant::tei:state[@type='existence'][@from]) then
        tei2ttl:make-triple('','dcterms:temporal', tei2ttl:make-literal($rec/descendant::tei:state[@type='existence']/@from,''))
    else (),
    tei2ttl:ids($rec),
    tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/html'))),
    tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/tei'))),
    tei2ttl:geo($rec),
    tei2ttl:relation($rec)
    )
};

(: Make sure record ends with a '.' :)
declare function tei2ttl:record($rec) as xs:string*{
    replace(tei2ttl:make-triples($rec),';$','.&#xa;')
};

declare function tei2ttl:save-to-db($id){
if($id = 'run all') then 
    let $recs := collection('/db/apps/logar-data/data/places/tei')
    (: Individual recs :)
    for $hit at $p in subsequence($recs, 1, 4000)//tei:TEI
    let $filename := concat(tokenize(replace($hit/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'/tei',''),'/')[last()],'.ttl')
    let $file-data :=  
        try {
            (concat(tei2ttl:prefix(), tei2ttl:record($hit)))
        } catch * {
            <error>Caught error {$err:code}: {$err:description}</error>
            }     
    return xmldb:store(xs:anyURI('/db/apps/logar-data/rdf/data'), xmldb:encode-uri($filename), $file-data)
else if($id = 'combined') then 
    (: Full collection:) 
    let $recs := collection('/db/apps/logar-data/data/places/tei')
    let $full-rec := 
       string-join(
       for $hit in $recs
        let $filename := concat(tokenize(replace($hit/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'/tei',''),'/')[last()],'.ttl')
        let $file-data :=  
            try {
                tei2ttl:record($hit)
            } catch * {
                <error>Caught error {$err:code}: {$err:description}</error>
                }
        return $file-data,'&#xa;')  
    let $full := concat(tei2ttl:prefix(),$full-rec)    
    return xmldb:store(xs:anyURI('/db/apps/bug-test/data'), xmldb:encode-uri('all-places.ttl'), $full)
else if($id != '') then  
    let $recs := collection('/db/apps/srophe-data/data/places/tei')//tei:idno[@type='URI'][. = $id]
    (: Individual recs :)
    for $hit in $recs/ancestor::tei:TEI
    let $filename := concat(tokenize(replace($hit/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'/tei',''),'/')[last()],'.ttl')
    let $file-data :=  
        try {
            (concat(tei2ttl:prefix(), tei2ttl:record($hit)))
        } catch * {
            <error>Caught error {$err:code}: {$err:description}</error>
            }     
    return $file-data
    (:xmldb:store(xs:anyURI('/db/apps/bug-test/data/places/rdf'), xmldb:encode-uri($filename), $file-data):)
else ()
};
