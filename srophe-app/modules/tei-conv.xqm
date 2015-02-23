xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2="http://syriaca.org//tei-conv";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

declare function tei2:tei2dc($nodes as node()*)) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return
                $node
            case comment() return ()
            case element(tei:title) return
                <dc:title>{$node/string()}</dc:title>
            case element(tei:author) return
                <dc:creator>{$node/string()}</dc:creator>
            case element(tei:editor) return
                <dc:contributor>{$node/string()}</dc:contributor>
            case element(tei:publisher) return
                <dc:publisher>{$node/string()}</dc:publisher>
            case element(tei:date) return
                <dc:date>{$node/string()}</dc:date>
            case element(tei:idno) return
                <dc:identifier>{$node/string()}</dc:identifier>
            case element(tei:availability) return
                <dc:rights>{$node/string()}</dc:rights>                
            case element() return
                tei2:tei2dc($node/node())
            default return
                $node/string()
};
