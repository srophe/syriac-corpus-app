xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://syriaca.org/tei2html";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";

declare namespace html="http://purl.org/dc/elements/1.1/";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Simple TEI to HTML transformation
 : @param $node   
:)
declare function tei2html:tei2html($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:biblScope) return element span {
                let $unit := if($node/@unit = 'vol') then concat($node/@unit,'.') 
                             else if($node[@unit != '']) then string($node/@unit) 
                             else if($node[@type != '']) then string($node/@type)
                             else () 
                return 
                    if(matches($node/text(),'^\d')) then concat($unit,' ',$node/text())
                    else if(not($node/text()) and ($node/@to or $node/@from)) then  concat($unit,' ',$node/@from,' - ',$node/@to)
                    else $node/text()
            }
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            case element(tei:imprint) return element span {
                    if($node/tei:pubPlace/text()) then $node/tei:pubPlace[1]/text() else (),
                    if($node/tei:pubPlace/text() and $node/tei:publisher/text()) then ': ' else (),
                    if($node/tei:publisher/text()) then $node/tei:publisher[1]/text() else (),
                    if(not($node/tei:pubPlace) and not($node/tei:publisher) and $node/tei:title[@level='m']) then <abbr title="no publisher">n.p.</abbr> else (),
                    if($node/tei:date/preceding-sibling::*) then ', ' else (),
                    if($node/tei:date) then $node/tei:date else <abbr title="no date of publication">n.d.</abbr>,
                    if($node/following-sibling::tei:biblScope[@unit='series']) then ', ' else ()
            }
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            case element(tei:persName) return 
                <span class="tei-persName">{
                    if($node/child::*) then 
                        for $part in $node/child::*
                        order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
                        return tei2html:tei2html($part/node())
                    else tei2html:tei2html($node/node())
                }</span>
            case element(tei:title) return 
                let $titleType := 
                        if($node/@level='a') then 
                            'title-analytic'
                        else if($node/@level='m') then 
                            'title-monographic'
                        else if($node/@level='j') then 
                            'title-journal'
                        else if($node/@level='s') then 
                            'title-series'
                        else if($node/@level='u') then 
                            'title-unpublished'
                        else if($node/parent::tei:persName) then 
                            'title-person'                             
                        else ()
                return  
                    <span class="tei-title {$titleType}">{
                        (if($node/@xml:lang) then attribute lang { $node/@xml:lang } else (),
                        tei2html:tei2html($node/node()))                 
                    }</span>
            case element(tei:foreign) return 
                <span dir="{if($node/@xml:lang = ('syr','ar','^syr')) then 'rtl' else 'ltr'}">{
                    tei2html:tei2html($node/node())
                }</span>
            default return tei2html:tei2html($node/node())
};

(:
 : Used for short views of records, browse, search or related items display. 
:)
declare function tei2html:summary-view($nodes as node()*, $lang as xs:string?, $id as xs:string?) as item()* {
  tei2html:summary-view-generic($nodes,$id)   
};

(: Generic short view template :)
declare function tei2html:summary-view-generic($nodes as node()*, $id as xs:string?) as item()* {
    let $title := $nodes/descendant-or-self::tei:title[1]      
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)
    return 
        <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{tei2html:tei2html($title)}</a> 
            {if($nodes/descendant::tei:titleStmt/tei:author) then (' by ', tei2html:tei2html($nodes/descendant::tei:titleStmt/tei:author))
            else ()}
            {if($nodes/descendant::tei:biblStruct) then 
                <span class="results-list-desc desc" dir="ltr" lang="en">
                    <label>Source: </label> {bibl2html:citation($nodes/descendant::tei:biblStruct)}
                </span>
            else ()}
            {if($nodes/descendant-or-self::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
            {if($nodes/descendant::*:match) then
              <div>
                <span class="results-list-desc srp-label">Matches:</span>
                {
                 for $r in $nodes/descendant::*:match/parent::*[1]
                 return   
                    if(position() lt 8) then 
                        <span class="results-list-desc container">
                            <span class="srp-label">
                                {concat(position(),'. (', name(.),') ')}
                            </span>
                            {tei2html:tei2html(.)}
                            {if(position() = 8) then <span class="results-list-desc container">more ...</span> else()}
                        </span>
                    else ()
                }
              </div>
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>    
};

declare function tei2html:translate-series($series as xs:string?){
    if($series = 'The Syriac Biographical Dictionary') then ()
    else if($series = 'A Guide to Syriac Authors') then 
        <a href="{$global:nav-base}/authors/index.html"><img src="{$global:nav-base}/resources/img/icons-authors-sm.png" alt="A Guide to Syriac Authors"/>author</a>
    else if($series = 'Qadishe: A Guide to the Syriac Saints') then 
        <a href="{$global:nav-base}/q/index.html"><img src="{$global:nav-base}/resources/img/icons-q-sm.png" alt="Qadishe: A Guide to the Syriac Saints"/>saint</a>        
    else $series
};

(:~ 
 : Reworked KWIC to be more 'Google like' used examples from: http://ctb.kantl.be/download/kwic.xql for preceding and following content. 
 : Pass content through tei2html:tei2html() to handle simple things like suppression of tei:orig, etc. Could be made more robust to hide URI's as well. 
 :
 : @see : https://rvdb.wordpress.com/2011/07/20/from-kwic-display-to-kwicer-processing-with-exist/
          http://ctb.kantl.be/download/kwic.xql
:)
declare function tei2html:output-kwic($nodes as node()*, $id as xs:string?){
    for $node in subsequence($nodes//exist:match,1,8)
    return
        <span>{tei2html:kwic-truncate-previous($node/ancestor-or-self::tei:div[@type='entry'], $node, (), 40)} 
                &#160;<span class="match" style="background-color:yellow;">{$node/text()}</span>
                {tei2html:kwic-truncate-following($node/ancestor-or-self::tei:div[@type='entry'], $node, (), 40)} </span>
};

(:~
	Generate the left-hand context of the match. Returns a normalized string, 
	whose total string length is less than or equal to $width characters.
	Note: this function calls itself recursively until $node is empty or
	the returned sequence has the desired total string length.
:)
declare function tei2html:kwic-truncate-previous($root as node()?, $node as node()?, $truncated as item()*, $width as xs:int) {
  let $nextProbe := $node/preceding::text()[1]
  let $next := if ($root[not(. intersect $nextProbe/ancestor::*)]) then () else tei2html:tei2html($nextProbe)  
  let $probe :=  concat($nextProbe, ' ', $truncated)
  return
    if (string-length($probe) gt $width) then
      let $norm := concat(normalize-space($probe), ' ')
      return 
        if (string-length($norm) le $width and $next) then
          tei2html:kwic-truncate-previous($root, $next, $norm, $width)
        else if ($next) then
          concat('...', substring($norm, string-length($norm) - $width + 1))
        else $norm
    else if ($next) then 
      tei2html:kwic-truncate-previous($root, $next, $probe, $width)
    else for $str in normalize-space($probe)[.] return concat($str, ' ')
};

declare function tei2html:kwic-truncate-following($root as node()?, $node as node()?, $truncated as item()*, $width as xs:int) {
  let $nextProbe := $node/following::text()[1]
  let $next := if ($root[not(. intersect $nextProbe/ancestor::*)]) then () else tei2html:tei2html($nextProbe)  
  let $probe :=  concat($nextProbe, ' ', $truncated)
  return
    if (string-length($probe) gt $width) then
      let $norm := concat(normalize-space($probe), ' ')
      return 
        if (string-length($norm) le $width and $next) then
          tei2html:kwic-truncate-following($root, $next, $norm, $width)
        else if ($next) then
          concat('...', substring($norm, string-length($norm) - $width + 1))
        else $norm
    else if ($next) then 
      tei2html:kwic-truncate-following($root, $next, $probe, $width)
    else for $str in normalize-space($probe)[.] return concat($str, ' ')
};