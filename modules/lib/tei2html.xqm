xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://syriaca.org/tei2html";
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
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            default return tei2html:tei2html($node/node())
};
