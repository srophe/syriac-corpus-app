xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://syriaca.org/tei2html";
import module namespace global="http://syriaca.org/global" at "global.xqm";

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
            case element(tei:title) return 
                <span class="teiTitle">{
                    tei2html:tei2html($node/node())
                }</span>
            case element(tei:foreign) return 
                <span dir="{if($node/@xml:lang = ('syr','ar','^syr')) then 'rtl' else 'ltr'}">{
                    tei2html:tei2html($node/node())
                }</span>                
            case element(tei:persName) return 
                <span class="persName">{
                    if($node/child::*) then 
                        for $part in $node/child::*
                        order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
                        return tei2html:tei2html($part/node())
                    else tei2html:tei2html($node/node())
                }</span>
            case element(tei:biblStruct) return 
                tei2html:citation($node)
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            default return tei2html:tei2html($node/node())
};

declare function tei2html:citation($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:biblStruct) return tei2html:citation($node/node())
            case element(tei:analytic) return 
                (
                (: Ouput author/editors :)
                tei2html:citation-names($node,2),
                (: Ouput titles :)
                if($node/tei:title[starts-with(@xml:lang,'en')]) then 
                    ('"',tei2html:citation($node/tei:title[starts-with(@xml:lang,'en')][1]),if(not(ends-with($node/tei:title[starts-with(@xml:lang,'en')][1]/text(),'.|:|,'))) then '.' else(),'"')
                else ('"',tei2html:citation($node/tei:title[1]), if(not(ends-with($node/tei:title[1]/text(),'.|:|,'))) then '.' else(),'"'),
                if($node/following-sibling::tei:monogr/tei:title[1][@level='m']) then ' In'
                else ()                
                )
            case element(tei:monogr) return 
                (
                (: Title:)
                tei2html:citation($node/tei:title[1]),
                if($node/preceding-sibling::*[1][self::tei:analytic]) then 
                    (', ', tei2html:citation-names($node,2),
                    if($node/tei:title[@level='m'] and $node/tei:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]) then 
                        for $b in $node/tei:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]
                        return (', ', tei2html:citation($b))
                    else ()
                    )
                else '.',
                (: Tranlators :)
                if(count($node/tei:editor[@role='translator']) gt 0) then 
                    (' Translated by ', tei2html:citation-names($node/tei:editor[@role='translator'], 2))
                else (),
                (: Edition :)
                if($node/tei:edition) then
                    ('. ', if($node/tei:edition[starts-with(@xml:lang,'en')]) then tei2html:citation($node/tei:edition[starts-with(@xml:lang,'en')][1]) else tei2html:citation($node/tei:edition))
                else (),
                (: BiblScope :)
                if($node/tei:biblScope[@unit='vol']) then 
                    (' ',tei2html:citation($node/tei:biblScope[@unit='vol']),' ')
                else (),
                (: Series :)
                if($node/following-sibling::*[1][self::tei:series]) then 
                    (' ',tei2html:citation($node/following-sibling::*[1][self::tei:series]),' ')
                else if($node/following-sibling::*[1][self::tei:monogr]) then (', T5')
                else if($node/preceding-sibling::*[1][self::tei:monogr]) then 
                    (' ',tei2html:citation($node/preceding-sibling::*[1][self::tei:monogr]/tei:imprint))
                else if($node/preceding-sibling::*[1][self::tei:analytic]) then 
                        if($node/tei:title[@level='j'] and $node/tei:imprint[child::*[string-length(.) gt 0]]) then 
                            ('(', tei2html:citation($node/tei:imprint) ,')')
                        else (' ',tei2html:citation($node/tei:imprint))
                else (' ',tei2html:citation($node/tei:imprint)),
                if($node/following-sibling::*[1][self::tei:monogr]) then ', ' else (),
                if($node/tei:title[@level='j'] and $node/tei:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]) then
                    for $n in $node/tei:biblScope[(@unit != 'vol' and @unit != 'series') or not(@unit)]
                    return (': ', $n)
                else()
                )
            case element(tei:imprint) return    
                (if($node/tei:pubPlace[starts-with(@xml:lang,'en')]) then
                    tei2html:citation($node/tei:pubPlace[starts-with(@xml:lang,'en')][1])
                else if($node/tei:pubPlace) then     
                    tei2html:citation($node/tei:pubPlace[1])
                else (),
                if($node/tei:pubPlace and $node/tei:publisher) then ': '
                else (),
                if($node/tei:publisher[starts-with(@xml:lang,'en')]) then 
                    tei2html:citation($node/tei:publisher[starts-with(@xml:lang,'en')][1])
                else if($node/tei:publisher) then 
                    tei2html:citation($node/tei:publisher[1])
                else (),
                if(not($node/tei:pubPlace) and not($node/tei:publisher) and $node/tei:title[@level='m']) then
                    <abbr title="no publisher">n.p.</abbr>        
                else (),
                if($node/tei:date/preceding-sibling::*) then ', '
                else (),
                if($node/tei:date) then 
                    tei2html:citation($node/tei:date[1])
                else <abbr title="no date of publication">n.d.</abbr>,
                if($node/following-sibling::tei:biblScope[@unit='series']) then 
                    (',', tei2html:citation($node/parent::tei:biblScope[@unit='series']))
                else ())
            case element(tei:title) return
                <span>{(attribute class {
                if($node/@level='a') then 'title-analytic'
                else if($node/@level='m') then 'title-monographic'
                else if($node/@level='j') then 'title-journal'
                else if($node/@level='s') then 'title-series'
                else if($node/@level='u') then 'title-unpublished'
                else if($node/parent::tei:persName) then 'title-person'
                else 'title'},
                attribute dir {if($node/ancestor-or-self::tei:*[@xml:lang][1] = ('ar','^syr')) then 'rtl' else 'ltr'},
                tei2html:tei2html($node/node())
                )}</span>
            default return tei2html:tei2html($node/node())
};

declare function tei2html:citation-names($nodes as node()*, $max-output as xs:integer?) as item()* {
let $persons :=
    if($nodes/tei:author) then 
        let $count := count($nodes/tei:author)
        return tei2html:emit-responsible-persons($nodes/tei:author,$max-output,$count)
    else if($nodes/tei:editor[not(@role) or @role!='translator']) then 
        let $count := count($nodes/descendant::tei:editor[not(@role) or @role!='translator'])
        return (tei2html:emit-responsible-persons($nodes/tei:editor[not(@role) or @role!='translator'],$max-output,$count),if($count = 1) then ', ed.' else ', eds.')
    else ()  
return if(not(ends-with(normalize-space(string-join($persons,' ')),'.'))) then ($persons,'.') else $persons        
};

declare function tei2html:emit-responsible-persons($nodes as node()*, $max-output as xs:integer?, $count as xs:integer?){
    if(not(empty($max-output))) then 
        for $n at $p in subsequence($nodes,1,$max-output)
        return 
            if($count = 1) then tei2html:citation-names-display($n)
            else if($p = $max-output) then 
                (' and ',tei2html:citation-names-display($n), if($count gt $max-output) then ' et al.'  else ())
            else if($p gt 1) then 
                (', ',tei2html:citation-names-display($n))         
            else tei2html:citation-names-display($n)
    else 
        for $n at $p in subsequence($nodes,1,$count)
        return 
            if($count = 1) then tei2html:citation-names-display($n)
            else if($p = $max-output) then 
                (' and ',tei2html:citation-names-display($n), if($count gt $max-output) then ' et al.'  else ())
            else if($p gt 1) then 
                (', ',tei2html:citation-names-display($n))         
            else tei2html:citation-names-display($n)
};

declare function tei2html:citation-names-display($nodes as node()*) as item()* {
    $nodes
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
                    <label>Source: </label> {tei2html:citation($nodes/descendant::tei:biblStruct)}
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
