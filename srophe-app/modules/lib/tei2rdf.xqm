xquery version "3.0";
(:
 : Build generic TEI to RDF/XML 
:)
module namespace tei2rdf="http://syriaca.org/tei2rdf";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace data="http://syriaca.org/data" at "data.xqm";
import module namespace config="http://syriaca.org/config" at "../config.xqm";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc = "http://purl.org/dc/terms/";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace snap = "http://syriaca.org/snap";
declare namespace syriaca = "http://syriaca.org/syriaca";
declare namespace schema = "http://schema.org/";
declare namespace person = "http://syriaca.org/person/";
declare namespace cwrc = "http://sparql.cwrc.ca/ontologies/cwrc#";
declare namespace foaf =  "http://xmlns.com/foaf/0.1/";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

declare function tei2rdf:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/Person"/>
    else if($rec/descendant::tei:body/tei:listPlace) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/Place"/>
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/conceptualWork"/>
    else if($rec/descendant::tei:body/tei:biblStruct) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://purl.org/dc/terms/bibliographicResource"/>    
    else if($rec/tei:listPerson) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://syriaca.org/syriaca/personFactoid"/>    
    else if($rec/tei:listEvent) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://syriaca.org/syriaca/eventFactoid"/>
    else if($rec/tei:listRelation) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://syriaca.org/syriaca/relationFactoid"/>
    else()
};

declare function tei2rdf:rec-label($rec){
    if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then 
        for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][node()]
        return <skos:prefLabel xml:lang="{string($headword/@xml:lang)}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">{string-join($headword/text(),' ')}</skos:prefLabel>
    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then 
        for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[node()]
        return <skos:prefLabel xml:lang="{string($headword/@xml:lang)}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">{string-join($headword/text(),' ')}</skos:prefLabel>
    else if($rec[self::tei:div/@uri]) then 
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">{normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' '))}</skos:prefLabel>
    else <skos:prefLabel xml:lang="{string($rec/descendant::tei:title[1]/@xml:lang)}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">{string-join($rec/descendant::tei:title[1]/text(),' ')}</skos:prefLabel>
};

(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 :)
declare function tei2rdf:desc($rec) as xs:string* {
for $desc in $rec/descendant::tei:desc
let $source := $desc/tei:quote/@source
return
    if($desc[@type='abstract'][not(@source)][not(tei:quote/@source)] or $desc[contains(@xml:id,'abstract')][not(@source)][not(tei:quote/@source)][. != '']) then 
        <dc:description xmlns:dc="http://purl.org/dc/terms/">{string-join($desc/text(),' ')}</dc:description>
    else ()
    (: this is unclear save for later
        if($desc/child::* != '' or $desc != '') then 
            <dcterms:description xmlns:dcterms="http://purl.org/dc/terms/">
                <rdfs:label xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                    {if($desc/@xml:lang) then attribute lang {$desc/@xml:lang} else ()}
                    {}
                    
                </rdfs:label>
            </dcterms:description>
            
            concat('&#xa; dcterms:description [',
                tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($desc, string($desc/@xml:lang))),
                    if($source != '') then
                       if($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p/tei:listBibl/tei:bibl/tei:ptr/@target = $source) then 
                            tei2ttl:make-triple('','dcterms:license', tei2ttl:make-uri(string($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target)))
                       else ()
                    else (),
            '];')
            :)
};

(:~
 : Handling tei:bibl 
 : @param $rec TEI record.
 :)
declare function tei2rdf:bibl($rec) {
let $bibl-ids := $rec//descendant::tei:body//tei:bibl/tei:ptr/@target
return 
if($bibl-ids != '') then
    for $id in $bibl-ids
    return 
     <dc:relation rdf:resource="{$id}" xmlns:dc="http://purl.org/dc/terms/"/>
else ()   
};

(:~
 : Uses XQuery templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2rdf:bibl-citation($rec){
let $citation := bibl2html:citation($rec)
return 
    <dcterms:bibliographicCitation xmlns:dc="http://purl.org/dc/terms/">{string-join($citation)}</dcterms:bibliographicCitation>
};

(:~
 : Handling tei:idno 
 : @param $rec TEI record.
 :)
declare function tei2rdf:idnos($rec, $id) {
let $ids := $rec//descendant::tei:body//tei:idno[@type='URI'][text() != $id]/text()
return 
if($ids != '') then
    for $id in $ids
    return 
    (<skos:closeMatch rdf:resource="{$id}" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>, 
    <dc:relation rdf:resource="{$id}" xmlns:dc="http://purl.org/dc/terms/" />)
else ()   
};

declare function tei2rdf:other-formats($id) {
   (
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/html')}"/>,
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/tei')}"/>,
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/ttl')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/html')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/tei')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/ttl')}"/>
   )
};

(:~
 : Modified functx function to translate syriaca.org relationship names attributes to camel case.
 : @param $property as a string. 
:)
declare function tei2rdf:translate-relation-property($property as xs:string?) as xs:string{
    string-join((tokenize($property,'-')[1],
       for $word in tokenize($property,'-')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
};

declare function tei2rdf:related($rec, $id) {
(for $relation in $rec/descendant::tei:relation[not(parent::*/parent::tei:bibl)]
return 
    if($relation/@ref) then 
        let $related := distinct-values((tokenize($relation/@active,' '), tokenize($relation/@passive,' '), tokenize($relation/@mutual,' ')))
        return 
            let $relation := string($relation/@ref)
            for $r in $related[not(starts-with(.,('#','bibl'))) and (. != $id)]
            return 
                element { xs:QName($relation) } 
                        { attribute {xs:QName("rdf:resource")} { $r} } 
    else 
        if($relation/@name = 'contained') then 
            for $active in tokenize($relation/@active,' ')
            return <dcterms:isPartOf xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$active}"/>
        else if($relation/@name = 'share-a-name') then 
            let $rel := normalize-space($relation/@mutual)
            for $mutual in tokenize($rel,' ') 
            return 
                if(starts-with($mutual,'#')) then ()
                else <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{$mutual}"/>
        else if(contains($relation/@name,'-')) then 
            let $related := distinct-values((tokenize($relation/@active,' '), tokenize($relation/@passive,' '), tokenize($relation/@mutual,' ')))
            return 
                let $relation := concat('syriaca:',tei2rdf:translate-relation-property(string($relation/@name)))
                for $r in $related[not(starts-with(.,('#','bibl'))) and (. != $id)]
                return 
                    element { xs:QName($relation) } 
                        { attribute {xs:QName("rdf:resource")} { $r} }    
        else (),
for $location-relation in $rec/descendant::tei:location[@type='nested']/child::*[starts-with(@ref,$global:base-uri)]/@ref
return <dcterms:isPartOf xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$location-relation}"/>
) 
};

declare function tei2rdf:internal-refs($rec){
let $links := distinct-values($rec/descendant::tei:body//@ref[starts-with(.,'http://')] | $rec/descendant::tei:body//@target[starts-with(.,'http://')])
return 
if($links != '') then
    for $i in $links
    return <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{$i}"/>
else ()
};

declare function tei2rdf:rec-title($rec){
    <dc:title xmlns:dc="http://purl.org/dc/terms/">{string-join($rec//tei:titleStmt/tei:title/node(),' ')}</dc:title>
};

declare function tei2rdf:spear($rec, $id){
    if(contains($id,'/spear/')) then
        (
        let $bibl-ids := $rec//descendant::tei:bibl/tei:ptr/@target
        return 
            if($bibl-ids != '') then
                for $id in $bibl-ids
                return 
                 (<dc:relation rdf:resource="{$id}" xmlns:dc="http://purl.org/dc/terms/"/>,
                 <dcterms:source rdf:resource="{$id}" xmlns:dcterms="http://purl.org/dc/terms/"/>)
            else (),
            if($rec/tei:listPerson) then 
                <syriaca:personFactoid xmlns:syriaca="http://syriaca.org/syriaca">
        			<skos:Concept rdf:about="{$rec/descendant::tei:listPerson/tei:person/tei:persName/@ref}">
        			 {
                        if($rec/descendant::tei:person/tei:birth/tei:date) then 
                            <schema:birthDate xmlns:schema="http://schema.org/">{$rec/descendant::tei:person/tei:birth/tei:date/@when | $rec/descendant::tei:person/tei:birth/tei:date/@notAfter | $rec/descendant::tei:person/tei:birth/tei:date/@notBefore }</schema:birthDate>
                        if($rec/descendant::tei:person/tei:birth/tei:placeName[@ref]) then 
                            <schema:birthPlace rdf:resource="{$rec/descendant::tei:birth/tei:placeName/@ref}" xmlns:schema="http://schema.org/"/>
                        if($rec/descendant::tei:person/tei:nationality/tei:placeName/@ref) then 
                            <person:citizenship rdf:resource="{$rec/descendant::tei:person/tei:nationality/tei:placeName/@ref}" xmlns:person="http://syriaca.org/person/"/>
                        if($rec/descendant::tei:person/tei:death/tei:date) then 
                            <schema:deathDate xmlns:schema="http://schema.org/">
                                {$rec/descendant::tei:person/tei:death/tei:date/@when | $rec/descendant::tei:person/tei:death/tei:date/@notAfter | $rec/descendant::tei:person/tei:death/tei:date/@notBefore }
                            </schema:deathDate>
                        if($rec/descendant::tei:person/tei:death/tei:placeName[@ref]) then 
                            <schema:deathPlace rdf:resource="{$rec/descendant::tei:person/tei:death/tei:placeName/@ref}" xmlns:schema="http://schema.org/"/>
                        if($rec/descendant::tei:person/tei:education[@ref]) then 
                            <syriaca:studiedSubject rdf:resource="{$rec/descendant::tei:person/tei:education/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:education[@ref]) then 
                            <syriaca:studiedSubject rdf:resource="{$rec/descendant::tei:person/tei:education/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:trait[@type='ethnicLabel'][@ref]) then 
                            <cwrc:hasEthnicity rdf:resource="{$rec/descendant::tei:person/tei:trait[@type='ethnicLabel']/@ref}" xmlns:cwrc="http://sparql.cwrc.ca/ontologies/cwrc#"/>
                        if($rec/descendant::tei:person/tei:trait[@type='gender'][@ref]) then 
                            <schema:gender rdf:resource="{$rec/descendant::tei:person/tei:trait[@type='ethnicLabel']/@ref}" xmlns:schema="http://schema.org/"/>
                        if($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown[@ref]) then 
                            <cwrc:hasLinguisticAbility rdf:resource="{$rec/descendant::tei:person/tei:langKnowledge/tei:langKnown/@ref}" xmlns:cwrc="http://sparql.cwrc.ca/ontologies/cwrc#"/>
                        if($rec/descendant::tei:person/tei:state[@type='mental'][@ref]) then 
                            <syriaca:hasMentalState rdf:resource="{$rec/descendant::tei:person/tei:state/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:persName) then 
                            for $name in $rec/descendant::tei:person/tei:persName
                            return 
                            <foaf:name xmlns:syriaca="http://syriaca.org/syriaca">{string-join($name//text(),' ')}</foaf:name>
                        if($rec/descendant::tei:person/tei:occupation[@ref]) then 
                            <snap:occupation rdf:resource="{$rec/descendant::tei:person/tei:occupation/@ref}" xmlns:snap="http://syriaca.org/snap"/>
                        if($rec/descendant::tei:person/tei:trait[@type='physical'][@ref]) then 
                            <syriaca:hasPhysicalTrait rdf:resource="{$rec/descendant::tei:person/tei:trait[@type='physical']/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:residence/tei:placeName[@type='physical'][@ref]) then 
                            <person:residency rdf:resource="{$rec/descendant::tei:person/tei:residence/tei:placeName[@type='physical']/@ref}" xmlns:person="http://syriaca.org/person/"/>
                        if($rec/descendant::tei:person/tei:state[@type='sanctity'][@ref]) then 
                            <syriaca:sanctity rdf:resource="{$rec/descendant::tei:person/tei:state[@type='sanctity']/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:sex) then 
                            <syriaca:sex xmlns:syriaca="http://syriaca.org/syriaca">{string($rec/descendant::tei:person/tei:sex)}</syriaca:sex>
                        if($rec/descendant::tei:person/tei:socecStatus[@ref]) then 
                            <syriaca:hasSocialRank rdf:resource="{$rec/descendant::tei:person/tei:socecStatus/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>
                        if($rec/descendant::tei:person/tei:trait[@type='physical'][@ref]) then 
                            <syriaca:hasPhysicalTrait rdf:resource="{$rec/descendant::tei:person/tei:trait[@type='physical']/@ref}" xmlns:syriaca="http://syriaca.org/syriaca"/>                    
                        else ()
        			 }	
        			 </skos:Concept>
        		</syriaca:personFactoid>
            else if($rec/tei:listEvent) then 
                (: Subjects:)
                let $subjects := tokenize($rec/descendant::tei:event/tei:ptr/@target,' ')
                for $subject in $subjects
                return <dcterms:subject rdf:resource="{$subject}" xmlns:dcterms="http://purl.org/dc/terms/"/>,
                (: Places :)
                let $places := $rec/descendant::tei:event/tei:desc/descendant::tei:placeName/@ref
                for $place in $places
                return <schema:location rdf:resource="{$place}" xmlns:schema="http://schema.org/"/>,
                (: Dates :)
                let $dates := $rec/descendant::tei:event/descendant::tei:date/@when | $rec/descendant::tei:event/descendant::tei:date/@notBefore
                | $rec/descendant::tei:event/descendant::tei:date/@notAfter
                for $date in $dates
                return <dcterms:date xmlns:dcterms="http://purl.org/dc/terms/">{$date}</dcterms:date>
            else if($rec/tei:listRelation) then ()
                <syriaca:relationFactoid xmlns:syriaca="http://syriaca.org/syriaca">
                    <!--
        			<skos:Concept rdf:about="{$rec/descendant::tei:listPerson/tei:person/tei:persName/@ref}">
        			</skos:Concept>
        			-->
        		</syriaca:relationFactoid>
            else ()   
         )
    else ()
};

declare function tei2rdf:make-triple-set($rec){
let $id := if($rec/descendant::tei:idno[starts-with(.,$global:base-uri)]) then replace($rec/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
           else if($rec/@uri[starts-with(.,$global:base-uri)]) then $rec/@uri[starts-with(.,$global:base-uri)]
           else $rec/descendant::tei:idno[1]
return 
(<skos:Concept rdf:about="{$id}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">
    {(tei2rdf:rec-type($rec),
    tei2rdf:rec-label($rec),
    tei2rdf:idnos($rec, $id),
    tei2rdf:bibl($rec),
    tei2rdf:other-formats($id),
    tei2rdf:related($rec, $id),
    tei2rdf:internal-refs($rec),
    tei2rdf:spear($rec, $id)
    )}
</skos:Concept>,
<rdfs:Resource rdf:about="{concat($id,'/html')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dc:subject xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dc:format xmlns:dc="http://purl.org/dc/terms/">text/html</dc:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>,
<rdfs:Resource rdf:about="{concat($id,'/tei')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dc:subject xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dc:format xmlns:dc="http://purl.org/dc/terms/">text/xml</dc:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>,
<rdfs:Resource rdf:about="{concat($id,'/ttl')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dc:subject xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dc:format xmlns:dc="http://purl.org/dc/terms/">text/turtle</dc:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>
)
};

declare function tei2rdf:rdf-output($recs){
element rdf:RDF {namespace {""} {"http://www.w3.org/1999/02/22-rdf-syntax-ns#"}, 
    namespace skos {"http://www.w3.org/2004/02/skos/core#"},
    namespace dc {"http://purl.org/dc/terms/"},
    namespace dcterms {"http://purl.org/dc/terms/"},
    namespace lawd {"http://lawd.info/ontology/"},
    namespace syriaca {"http://syriaca.org/schema#"},
    namespace rdfs {"http://www.w3.org/2000/01/rdf-schema#"},
    namespace snap {"http://syriaca.org/snap"},
    namespace syriaca {"http://syriaca.org/syriaca"},
    namespace schema {"http://schema.org/"},
            for $r in $recs
            return tei2rdf:make-triple-set($r) 
    }
};

