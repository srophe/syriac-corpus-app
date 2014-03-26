xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
module namespace forms="http://syriaca.org//forms";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";


declare function forms:build-instance-new(){
        <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:svg="http://www.w3.org/2000/svg" xml:lang="en">
        <teiHeader>
         <fileDesc>
             <titleStmt>
                 <title level="a" xml:lang="en"></title>
                 <respStmt>
                    <resp>Online form completed by</resp>
                    <name></name>
                </respStmt>
             </titleStmt>
             <publicationStmt>
                 <date/>
             </publicationStmt>
             <sourceDesc>
                 <bibl/>
             </sourceDesc>
         </fileDesc>
        </teiHeader>
        <text>
            <body>
                <listPlace>
                    <place xml:id="placeXX" type="">
                        <!--Must include 1 english name place type -->
                        <placeName xml:id="" xml:lang="" source=""/>           
                        <!-- bibl also save to bible data folder? -->
                        <desc xml:lang="">
                            <quote source="">Description</quote>
                        </desc>
                        <!-- events bind computed dates at creation able to insert place names -->
                        <event when="" source="">
                            <p xml:lang="en"/>
                        </event>
                        <!-- attestations -->
                        <event type="attestation" xml:id="attestationXX" source="">
                            <p xml:lang="en">description</p>
                        </event>
                        <!-- confession dropdown?-->
                        <state type="confession" xml:id="confessionXX" ref="" source="">
                            <label></label>
                        </state>
                        <!-- notes type dropdown insert place name where needed?-->
                        <note type=""/>
                        <bibl xml:id="biblXX">
                            <!-- repeatable -->
                            <author></author>
                            <!-- title repeatable a(article?) m(manuscript) -->
                            <title level="" xml:lang=""></title>
                            <!-- point to bib record -->
    <!--                        <ptr target="http://syriaca.org/bibl/1"/>-->
                            <!--unit: pages maps-->
                            <citedRange unit="pp"/>
                        </bibl>
                    </place>
                </listPlace>
            </body>
        </text>
    </TEI>    

};
declare function forms:build-instance-add($id){
    let $place-id := concat('place-',$id)
    for $parent-rec in collection("/db/apps/srophe/data/places/tei")/id($place-id) 
    let $title := $parent-rec/ancestor::*/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]
    let $title-display := replace($title,'-','')
    let $place-type := string($parent-rec/@type)
    return 
     <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:svg="http://www.w3.org/2000/svg" xml:lang="en">
        <teiHeader>
         <fileDesc>
             <titleStmt>
                 {$title}
                <respStmt>
                    <resp>Online form completed by</resp>
                    <name></name>
                </respStmt>
             </titleStmt>
             <publicationStmt>
                 <date/>
             </publicationStmt>
             <sourceDesc>
                 <bibl/>
             </sourceDesc>
         </fileDesc>
        </teiHeader>
        <text>
            <body>
                <listPlace>
                    <place xml:id="{$place-id}" type="{$place-type}">
                        <!--Must include 1 english name place type -->
                        <placeName xml:id="name{$id}-1" xml:lang="" source=""/>           
                        <!-- bibl also save to bible data folder? -->
                        <desc xml:lang="">
                            <quote source="">Description</quote>
                        </desc>
                        <!-- events bind computed dates at creation able to insert place names -->
                        <event when="" source="">
                            <p xml:lang="en"/>
                        </event>
                        <!-- attestations -->
                        <event type="attestation" xml:id="attestation{$id}-1" source="">
                            <p xml:lang="en">description</p>
                        </event>
                        <!-- confession dropdown?-->
                        <state type="confession" xml:id="confession{$id}-1" ref="" source="">
                            <label></label>
                        </state>
                        <!-- notes type dropdown insert place name where needed?-->
                        <note type=""/>
                        <bibl xml:id="bib{$id}-1">
                            <!-- repeatable -->
                            <author></author>
                            <!-- title repeatable a(article?) m(manuscript) -->
                            <title level="" xml:lang=""></title>
                            <!-- point to bib record -->
    <!--                        <ptr target="http://syriaca.org/bibl/1"/>-->
                            <!--unit: pages maps-->
                            <citedRange unit="pp"/>
                        </bibl>
                    </place>
                </listPlace>
            </body>
        </text>
    </TEI>    

};
(:~
  : Build new xml instance with parent id pre-populated
  : @id place id passed from place page. 
:)
declare function forms:build-instance($id){
    if(exists($id) and $id !='') then forms:build-instance-add($id)
    else forms:build-instance-new()
};
