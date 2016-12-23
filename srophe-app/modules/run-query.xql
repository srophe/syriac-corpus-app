xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace rdfq="http://syriaca.org/rdfq" at "lib/tei2rdf.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cito = "http://purl.org/spar/cito";
declare namespace cnt = "http://www.w3.org/2011/content";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace geo = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace gn = "http://www.geonames.org/ontology#";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

for $r in collection('/db/apps/srophe-data/data/persons')//tei:idno[. = 'http://syriaca.org/person/13']
return $r
(:
if($rec/descendant::tei:idno[starts-with(.,'http://worldcat.org/identities/lccn-n')] or $rec/descendant::tei:idno[starts-with(.,'http://viaf.org/viaf')][not(contains(.,'sourceID'))]) then
            let $viaf-ref := if($rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')]) then 
                                        $rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')][1]/text()
                                     else $rec/descendant::tei:idno[@type='URI'][not(contains(.,'sourceID/SRP')) and starts-with(.,'http://viaf.org/viaf')][1]
            let $uri := if(starts-with($viaf-ref,'http://viaf.org/viaf')) then 
                                    let $rdf := http:send-request(<http:request href="{concat($viaf-ref,'/rdf.xml')}" method="get"/>)[2]//schema:sameAs/child::*/@rdf:about[starts-with(.,'http://id.loc.gov/')]
                                    let $lcc := tokenize($rdf,'/')[last()]
                                    return concat('http://worldcat.org/identities/lccn-',$lcc)
                                else $viaf-ref
            let $build-request :=  <http:request href="{$uri}" method="get"/>
            return 
                if($uri != '') then 
                    try {
                        let $results :=  http:send-request($build-request)//by 
                        let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
                        return 
                            if(not(empty($results)) and  $total-works != '0') then 
                                    <div id="worldcat-refs" class="well">
                                        <h3>{$total-works} Catalog Search Results from WorldCat</h3>
                                        <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
                                        <div>
                                             <ul id="{$viaf-ref}" count="{$total-works}">
                                                {
                                                    for $citation in $results/citation[position() lt 5]
                                                    return
                                                        <li><a href="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</a></li>
                                                 }
                                             </ul>
                                             <span class="pull-right"><a href="{$uri}">See all {$total-works} titles from WorldCat</a></span>,<br/>
                                        </div>
                                    </div>    
                                             
                            else ()
                    } catch * {
                        <error>Caught error {$err:code}: {$err:description}</error>
                    } 
                 else ()   
    else () 
    :)