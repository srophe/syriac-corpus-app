(:~    
 : Builds Facet definitions for each submodule. 
 :)
xquery version "3.0";

module namespace facet-defs="http://syriaca.org/facet-defs";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="http://syriaca.org/templates" at "app.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";


declare function facet-defs:facet-definition($collection){
if($collection = 'persons') then
<facets xmlns="http://expath.org/ns/facet">
    <facet-definition name="Type">
        <group-by function="facet:group-by-sub-module">
            <sub-path>descendant::tei:seriesStmt/tei:biblScope/tei:idno</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="descending">count</order-by>
    </facet-definition>
    <facet-definition name="Century">
        <range type="xs:date">
            <bucket gt="0001-01-01" lt="0100-01-01" name="1-100"/>
            <bucket gt="0100-01-01" lt="0200-01-01" name="100-200"/>
            <bucket gt="0200-01-01" lt="0300-01-01" name="200-300"/>
            <bucket gt="0300-01-01" lt="0400-01-01" name="300-400"/>
            <bucket gt="0400-01-01" lt="0500-01-01" name="400-500"/>
            <bucket gt="0500-01-01" lt="0600-01-01" name="500-600"/>
            <bucket gt="0600-01-01" lt="0700-01-01" name="600-700"/>
            <bucket gt="0700-01-01" lt="0800-01-01" name="700-800"/>
            <bucket gt="0800-01-01" lt="0900-01-01" name="800-900"/>
            <bucket gt="0900-01-01" lt="1000-01-01" name="900-1000"/>
            <bucket gt="1000-01-01" lt="1100-01-01" name="1000-1100"/>
            <bucket gt="1100-01-01" lt="1200-01-01" name="1100-1200"/>
            <bucket gt="1200-01-01" lt="1300-01-01" name="1200-1300"/>
            <bucket gt="1300-01-01" lt="1400-01-01" name="1300-1400"/>
            <bucket gt="1400-01-01" lt="1500-01-01" name="1400-1500"/>
            <bucket gt="1500-01-01" lt="1600-01-01" name="1500-1600"/>
            <bucket gt="1600-01-01" lt="1700-01-01" name="1600-1700"/>
            <bucket gt="1700-01-01" lt="1800-01-01" name="1700-1800"/>
            <bucket gt="1800-01-01" lt="1900-01-01" name="1800-1900"/>
            <bucket gt="1900-01-01" lt="2000-01-01" name="1900-2000"/>
            <!--<bucket gt="2000-01-01" name="2000 +"/>-->
        </range>
        <group-by type="xs:date">
            <sub-path>/@syriaca-computed-start</sub-path>
            <!--<sub-path>descendant::*/@syriaca-computed-start</sub-path>-->
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="descending">count</order-by>
    </facet-definition>
    <facet-definition name="Sex or Gender">
        <group-by>
            <sub-path>descendant::tei:sex/text()</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Has name in">
        <group-by>
            <sub-path>descendant::tei:persName/@xml:lang</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Born">
        <group-by>
            <sub-path>descendant::tei:relation[@name="born-at"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Died">
        <group-by>
            <sub-path>descendant::tei:relation[@name="died-at"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Literary Connection">
        <group-by function="facet:group-by-array">
            <sub-path>descendant::tei:relation[@name="has-literary-connection-to-place"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>        
    <facet-definition name="Unspecified Connection">
        <group-by function="facet:group-by-array">
            <sub-path>descendant::tei:relation[@name="has-relation-to-place"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>            
    <facet-definition name="Office">
        <group-by>
            <sub-path>descendant::tei:state[@type="office"]/@role</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Saint type">
        <group-by>
            <sub-path>descendant::tei:state[@type="saint"]/@role</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Occupation">
        <group-by>
            <sub-path>descendant::tei:state[@type="occupation"]/@role</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
</facets> 
else if($collection = 'bhse') then
<facets xmlns="http://expath.org/ns/facet">
    <facet-definition name="Type">
        <group-by function="facet:group-by-sub-module">
            <sub-path>descendant::tei:seriesStmt/tei:biblScope/tei:idno</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="descending">count</order-by>
    </facet-definition>
    <facet-definition name="Commemorated">
        <group-by function="facet:group-by-array">
            <sub-path>descendant::tei:relation[@name="syriaca:commemorated"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>        
    <facet-definition name="Sources">
        <group-by>
            <sub-path>descendant::tei:body/tei:bibl/tei:bibl/tei:ptr/@target</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
</facets> 
else if($collection = 'spear') then
<facets xmlns="http://expath.org/ns/facet">
    <facet-definition name="Place">
        <group-by>
            <sub-path>descendant::tei:placeName/@ref</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="descending">count</order-by>
    </facet-definition>
    <facet-definition name="Person">
    <!--function="facet:group-name" -->
        <group-by>
            <sub-path>descendant::tei:persName/@ref</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition> 
        <facet-definition name="Sex or Gender">
        <group-by>
            <sub-path>descendant::tei:sex/text()</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Born">
        <group-by>
            <sub-path>descendant::tei:relation[@name="born-at"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Died">
        <group-by>
            <sub-path>descendant::tei:relation[@name="died-at"]/@passive</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    
    <facet-definition name="Keyword">
        <group-by function="facet:group-by-array">
            <sub-path>descendant::*/@*[contains(.,'/keyword/')]</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
    <facet-definition name="Source Text">
        <group-by function="facet:spear-source-text">
            <sub-path>ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]</sub-path>
        </group-by>
        <max-values show="5">40</max-values>
        <order-by direction="ascending">count</order-by>
    </facet-definition>
</facets> 
else ()
};