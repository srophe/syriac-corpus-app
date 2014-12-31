xquery version "3.0";
(:~
 : Builds tei to html conversion. Not currently in use 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace tei2="http://syriaca.org//tei2html";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Build h1 headers across modules
 : @param $node
NOTE: will need work and testing for use with persons and places, need to add birth/death for persons, maybe as parameters
:)
declare %templates:wrap  function tei2:h1($nodes as node()) {
    if($nodes[1][@syriaca-tags='#syriaca-headword']) then 
        (<bdi lang="{string($nodes[@syriaca-tags='#syriaca-headword']/@xml:lang="^en")}">{$nodes[@syriaca-tags='#syriaca-headword'][@xml:lang="^en"]} - </bdi>,
         if($nodes[@syriaca-tags='#syriaca-headword'][@xml:lang="^syr"]) then
            <bdi lang="{string($nodes[@syriaca-tags='#syriaca-headword']/@xml:lang="^syr")}">{$nodes[@syriaca-tags='#syriaca-headword'][@xml:lang="^syr"]}</bdi>
         else <bdi dir="ltr">[ Syriac Not Available ]</bdi>,
         if($nodes[@ana]) then concat('(',substring-after($nodes/@ana,'#syriaca-'),')')
         else ()
        ) 
    else
       $nodes/text()
};

declare function tei2:do-ref($refs){
<bdi class="footnote-refs" dir="ltr">
    {
        for $ref in tokenize($refs,' ')
        return 
            <span class="footnote-ref">
                <a href="{$ref}">{substring-after($ref,'-')}</a>
                {
                    if(position() != last()) then ', ' 
                    else ()
                }
            </span>
        }
</bdi>
};

declare function tei2:sources($sources as node()*) {
<div class="well">
    <div id="sources">
        <h3>Sources</h3>
            <p><small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small></p>
            <ul>
                <!-- Bibliography elements are processed by bibliography.xsl -->
                <li>In process</li>
            </ul>
    </div>
</div>
};

declare function tei2:citation($sources as node()*) {
<div class="citationinfo">
    <h3>How to Cite This Entry</h3>
    <div id="citation-note" class="well">
    <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
        <div class="collapse" id="showcit">
            <div id="citation-bibliography">
                <h4>Bibliography:</h4>
                <!--<xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-biblist"/>-->
            </div>
            <div id="about">
                <h3>About this Entry</h3>
                <!--<xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="about"/>-->
            </div>
            <div id="license">
                <h3>Copyright and License for Reuse</h3>
                <p>Except otherwise noted, this page is © 
                {
                    if($sources//tei:date castable as xs:date) then format-date($sources//tei:date,'[Y]')
                    else $sources//tei:date
                }. {tei2:tei2html($sources//tei:licence)}</p>     
            </div>
            </div>
        <a class="togglelink pull-right btn-link" data-toggle="collapse" data-target="#showcit" data-text-swap="Hide citation">Show full citation information...</a>
    </div>
</div>
};        
declare function tei2:tei2html($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return
                $node
            case comment() return ()
            case element(tei:placeName) return
                if($node/@ref) then
                     <span class="placeName" xmlns="http://www.w3.org/1999/xhtml">
                        <a class="placeName" href="{string($node/@ref)}">
                            {tei2:tei2html($node/node())} 
                        </a>
                        {tei2:do-ref(string($node/@source))}
                    </span>  
                 else 
                    <span class="placeName" xmlns="http://www.w3.org/1999/xhtml">
                        {tei2:tei2html($node/*),tei2:do-ref($node/@source)}
                    </span>
            case element(tei:persName) return
                if($node/@ref) then
                    <span class="persName" xmlns="http://www.w3.org/1999/xhtml">
                        <a class="persName" href="{string($node/@ref)}">
                            {tei2:tei2html($node/node())} 
                        </a>
                        {tei2:do-ref(string($node/@source))}
                    </span>  
                 else 
                    <span class="persName" xmlns="http://www.w3.org/1999/xhtml">
                        {tei2:tei2html($node/*),tei2:do-ref($node/@source)}
                    </span>
            case element(tei:education) return
                <p class="single-space">
                    <span class="srp-label">
                        {
                            if($node/@role) then concat(upper-case(substring($node/@role,1,1)),substring($node/@role,2))
                            else if($node/@type) then concat(upper-case(substring($node/@type,1,1)),substring($node/@type,2))
                            else 'Education '
                        }
                    </span>
                    {(tei2:tei2html($node/*),tei2:do-ref($node/@source))}
                </p>      
            case element(tei:faith) return
                <p class="single-space">
                    <span class="srp-label">
                        {
                            if($node/@role) then concat(upper-case(substring($node/@role,1,1)),substring($node/@role,2))
                            else if($node/@type) then concat(upper-case(substring($node/@type,1,1)),substring($node/@type,2))
                            else 'Religious affiliation '
                        }
                    </span>
                    {(tei2:tei2html($node/*),tei2:do-ref($node/@source))}
                </p>                      
            case element(tei:langKnown) return
                <p class="single-space">
                    <span class="srp-label">
                        {
                            if($node/@role) then concat(upper-case(substring($node/@role,1,1)),substring($node/@role,2))
                            else if($node/@type) then concat(upper-case(substring($node/@type,1,1)),substring($node/@type,2))
                            else 'Language Spoken '
                        }
                    </span>
                    {(tei2:tei2html($node/*),tei2:do-ref($node/@source))}
                </p>                    
            case element(tei:ethnicity) return
                <p class="single-space">
                    <span class="srp-label">
                        {
                            if($node/@role) then concat(upper-case(substring($node/@role,1,1)),substring($node/@role,2))
                            else if($node/@type) then concat(upper-case(substring($node/@type,1,1)),substring($node/@type,2))
                            else 'Ethnicity '
                        }
                    </span>
                    {(tei2:tei2html($node/*),tei2:do-ref($node/@source))}
                </p>
            case element(tei:state) return
                <p class="single-space">
                    <span class="srp-label">
                        {
                            if($node/@role) then concat(upper-case(substring($node/@role,1,1)),substring($node/@role,2))
                            else concat(upper-case(substring($node/@type,1,1)),substring($node/@type,2))
                        }
                    </span>
                    {(tei2:tei2html($node/*),tei2:do-ref($node/@source))}
                </p>
            case element(tei:ref) return
                <a href="{$node/@target}">{tei2:tei2html($node/node())}</a>
            case element(tei:p) return 
                <p xmlns="http://www.w3.org/1999/xhtml">{ tei2:tei2html($node/node()) }</p>
            case element(exist:match) return
                <mark xmlns="http://www.w3.org/1999/xhtml">{ $node/node() }</mark>
            case element() return
                tei2:tei2html($node/node())
            default return
                $node/string()
};