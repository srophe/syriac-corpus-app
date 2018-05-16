xquery version "3.0";
(:~
 : Builds tei conversions. Citation module. 
 :)
 
module namespace bibl2html="http://syriaca.org/bibl2html";
import module namespace tei2html="http://syriaca.org/tei2html" at "tei2html.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace html="http://purl.org/dc/elements/1.1/";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Select citation type based on child elements
:)
declare function bibl2html:citation($nodes as node()*) {
    if($nodes/descendant-or-self::tei:teiHeader) then 
       bibl2html:record($nodes/descendant-or-self::tei:teiHeader)
    else if($nodes/descendant::tei:monogr and not($nodes/descendant::tei:analytic)) then 
       bibl2html:monograph($nodes/descendant::tei:monogr)
    else if($nodes/descendant::tei:analytic) then 
       bibl2html:analytic($nodes/descendant::tei:analytic)
    else bibl2html:record($nodes/descendant-or-self::tei:teiHeader)
};

(:~
 : Output monograph citation
:)
declare function bibl2html:record($nodes) {
    let $titleStmt := $nodes/descendant::tei:titleStmt
    let $sourceDesc := $nodes/descendant::tei:sourceDesc
    let $persons :=  if($titleStmt/tei:author) then 
                         if(bibl2html:emit-responsible-persons($titleStmt/tei:author,3) != '') then 
                            concat(bibl2html:emit-responsible-persons($titleStmt/tei:author,3),'. ')
                         else ()
                     else concat(bibl2html:emit-responsible-persons($titleStmt/tei:editor[@role='creator'],3), 
                        if(count($titleStmt/tei:editor) gt 1) then ' eds. ' else ' ed. ')
    let $id := $nodes/descendant-or-self::tei:publicationStmt[1]/tei:idno[1] 
    let $rspStmt := $nodes/descendant::tei:fileDesc/tei:editionStmt/tei:respStmt[1]/tei:resp
    let $rspStmtString := concat(upper-case(substring($rspStmt,1,1)),substring($rspStmt, 2))
    return 
        ($persons,' “',tei2html:tei2html($titleStmt/tei:title[1]),'.” ',$rspStmtString,' ', 
        if(bibl2html:responsibility($nodes) != '') then 
            (bibl2html:responsibility($nodes),'.')  else (), 
        ' ', tei2html:tei2html($titleStmt/tei:title[@level='s'][position()=last()]),'. Last modified ',
        if($nodes/descendant::tei:revisionDesc/tei:change[1]/@when castable as xs:date) then 
            concat(format-date(xs:date($nodes/descendant::tei:revisionDesc/tei:change[1]/@when), '[MNn] [D], [Y]'),'. ') 
        else concat(string($nodes/descendant::tei:revisionDesc/tei:change[1]/@when), '. '),
        concat(replace($id[1],'/tei',''),'.')
        )
};

declare function bibl2html:responsibility($nodes) {
    if($nodes/descendant::tei:fileDesc/tei:editionStmt/tei:respStmt/tei:name/tei:ptr) then
        let $source := replace(string($nodes/descendant::tei:fileDesc/tei:editionStmt/tei:respStmt/tei:name/tei:ptr/@target),'#','')
        return 
            if($nodes/descendant::tei:sourceDesc[@xml:id = $source]) then 
                for $s in $nodes/descendant::tei:sourceDesc[@xml:id = $source]
                return 
                    if($s/tei:msDesc) then 
                      $s/tei:msDesc/tei:msIdentifier/tei:altIdentifier[1]//text()
                    else bibl2html:citation($s)
            else 
                for $s in $nodes/descendant::tei:teiHeader/tei:fileDesc/tei:sourceDesc[1]
                return 
                    if($s/tei:msDesc) then 
                        $s/tei:msDesc/tei:msIdentifier/tei:altIdentifier[@type='preferred']//text()
                    else bibl2html:citation($s)     
    else if($nodes/descendant::tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:respStmt/tei:name) then string-join($nodes/descendant::tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:respStmt/tei:name/text(),' ')
    else ()
};

(:~
 : Output monograph citation
:)
declare function bibl2html:monograph($nodes as node()*) {
    let $persons := if($nodes/tei:author) then 
                        concat(bibl2html:emit-responsible-persons($nodes/tei:author,3),', ')
                    else if($nodes/tei:editor[not(@role) or @role!='translator']) then 
                        (bibl2html:emit-responsible-persons($nodes/tei:editor[not(@role) or @role!='translator'],3), 
                        if(count($nodes/tei:editor[not(@role) or @role!='translator']) gt 1) then ' eds., ' else ' ed., ')
                    else ()
    return (if(deep-equal($nodes/tei:editor | 
                $nodes/tei:author, 
                $nodes/preceding-sibling::tei:monogr/tei:editor | 
                $nodes/preceding-sibling::tei:monogr/tei:author )) then () else $persons,tei2html:tei2html($nodes/tei:title[1]),
            if(count($nodes/tei:editor[@role='translator']) gt 0) then 
                (bibl2html:emit-responsible-persons($nodes/tei:editor[@role!='translator'],3),', trans. ') else (),
            if($nodes/tei:edition) then 
                (', ', $nodes/tei:edition[1]/text(),' ')
            else (),
            if($nodes/tei:biblScope[@unit='vol']) then
                (' ',tei2html:tei2html($nodes/tei:biblScope[@unit='vol']),' ')
            else (),
            if($nodes/following-sibling::tei:series) then bibl2html:series($nodes/following-sibling::tei:series)
            else if($nodes/following-sibling::tei:monogr) then ', '
            else if($nodes/preceding-sibling::tei:monogr and $nodes/preceding-sibling::tei:monogr/tei:imprint[child::*[string-length(.) gt 0]]) then   
            (' (', $nodes/preceding-sibling::tei:monogr/tei:imprint,')')
            else if($nodes/tei:imprint[child::*[string-length(.) gt 0]]) then 
                concat(' (',tei2html:tei2html($nodes/tei:imprint[child::*[string-length(.) gt 0]]),')', 
                if($nodes/following-sibling::tei:monogr) then ', ' else '.' )
            else())
};

(:~
 : Output analytic citation
:)
declare function bibl2html:analytic($nodes as node()*) {
    let $persons := if($nodes/tei:author) then 
                        concat(bibl2html:emit-responsible-persons($nodes/tei:author,3),', ')
                    else if($nodes/tei:editor[not(@role) or @role!='translator']) then 
                        (bibl2html:emit-responsible-persons($nodes/tei:editor[not(@role) or @role!='translator'],3), 
                        if(count($nodes/tei:editor[not(@role) or @role!='translator']) gt 1) then ' eds., ' else ' ed., ')
                    else 'No authors or Editors'
    return (
            $persons, 
            concat('"',tei2html:tei2html($nodes/tei:title[1]),if(not(ends-with($nodes/tei:title[1][starts-with(@xml:lang,'en')][1],'.|:|,'))) then '.' else (),'"'),            
            if(count($nodes/tei:editor[@role='translator']) gt 0) then (bibl2html:emit-responsible-persons($nodes/tei:editor[@role!='translator'],3),', trans. ') else (),
            if($nodes/following-sibling::tei:monogr/tei:title[1][@level='m']) then 'in' else(),
            if($nodes/following-sibling::tei:monogr) then bibl2html:monograph($nodes/following-sibling::tei:monogr) else()
        )
};

(:~
 : Output series citation
:)
declare function bibl2html:series($nodes as node()*) {(
    if($nodes/preceding-sibling::tei:monogr/tei:title[@level='j']) then ' (=' 
    else if($nodes/preceding-sibling::tei:series) then '; '
    else ', ',
    if($nodes/tei:title) then tei2html:tei2html($nodes/tei:title[1]) else (),
    if($nodes/tei:biblScope) then 
        (',', 
        for $r in $nodes/tei:biblScope[@unit='series'] | $nodes/tei:biblScope[@unit='vol'] | $nodes/tei:biblScope[@unit='tomus']
        return (tei2html:tei2html($r), if($r[position() != last()]) then ',' else ())) 
    else (),
    if($nodes/preceding-sibling::tei:monogr/tei:title[@level='j']) then ')' else (),
    if($nodes/preceding-sibling::tei:monogr/tei:imprint and not($nodes/following-sibling::tei:series)) then 
        (' (',tei2html:tei2html($nodes/preceding-sibling::tei:monogr/tei:imprint),')')
    else ()
)};

(:~
 : Output authors/editors
:)
declare function bibl2html:emit-responsible-persons($nodes as node()*, $num as xs:integer?) {
    let $persons := 
        let $limit := if($num) then $num else 3
        let $count := count($nodes)
        return 
            if($count = 1) then 
                bibl2html:person($nodes)                
            else if($count = 2) then
                (bibl2html:person($nodes[1]),' and ',bibl2html:person($nodes[2]))            
            else 
                for $n at $p in subsequence($nodes, 1, $num)
                return 
                    if($p = ($num - 1)) then 
                        (normalize-space(bibl2html:person($n)), ' and ')
                    else if($p = $num) then 
                        concat(normalize-space(bibl2html:person($n)),' ')
                    else concat(normalize-space(bibl2html:person($n)),', ')
    return replace(string-join($persons),'\s+$','')                    
};

(:~
 : Output authors/editors child elements. 
:)
declare function bibl2html:person($nodes as node()*) {
    if($nodes[@role='anonymous']) then () else string-join($nodes/descendant::text(),' ')
};