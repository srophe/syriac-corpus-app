xquery version "3.0";
(:~
 : Builds tei conversions to plain text.
 :)
 
module namespace tei2txt="http://syriaca.org/tei2txt";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

declare function tei2txt:typeswitch($nodes) {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return normalize-space($node)
            case comment() return ()
            case element(tei:div) return 
                ('&#xd;',tei2txt:typeswitch($node/node()),'&#xd;')
            case element(tei:head) return 
                (tei2txt:typeswitch($node/node()),'&#xd;')
            case element(tei:pb) return 
                if($node/@n) then ('&#xd; pb.', $node/@n,' &#xd;')
                else ()                       
            case element(tei:teiHeader) return 
                concat(normalize-space(string-join((bibl2html:citation($node)),'')),'&#xd;')                
            case element() return 
                if($node/@n) then (concat(' ', $node/@n,' '),tei2txt:typeswitch($node/node()))
                else tei2txt:typeswitch($node/node())
            (:case element (html:span) return 
                if($node/@class[contains(.,'title-monographic') or contains(.,'title-journal')]) then 
                    ('\i',tei2txt:typeswitch($node/node()))
                else tei2txt:typeswitch($node/node()):)
            default return tei2txt:typeswitch($node/node())
};

declare function tei2txt:tei2txt($nodes as node()*) {
    tei2txt:typeswitch($nodes)
};
