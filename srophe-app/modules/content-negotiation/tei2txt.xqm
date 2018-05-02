xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2txt="http://syriaca.org/tei2txt";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function tei2txt:typeswitch($nodes as node()*) {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:lb) return '&#xa;'
            case element(tei:l) return (tei2txt:typeswitch($node/node()),'&#xa;')
            case element(tei:teiHeader) return string-join(bibl2html:citation($node),'')
            default return tei2txt:typeswitch($node/node())
};

declare function tei2txt:tei2txt($nodes as node()*) {
    tei2txt:typeswitch($nodes)
};
