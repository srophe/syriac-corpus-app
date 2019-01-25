xquery version "3.0";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by ../app.xql and content-negotiation/content-negotiation.xql  
:)
module namespace data="http://syriaca.org/srophe/data";

import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Return document by id/tei:idno or document path
 : Return by ID if @param $id
 : Return by document path if @param $doc
 : @param $id return document by id or tei:idno
 : @param $doc return document path relative to data-root
:)
declare function data:get-document() {
    let $id := request:get-parameter('id', '')
    return collection($config:data-root)//tei:TEI[.//tei:idno[@type='URI'][. = request:get-parameter('id', '')]][1]
    (:
        if($id != '') then
            if(contains($id,'/spear/')) then
                for $rec in collection($config:data-root)//tei:div[@uri = $id]
                return <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec}</tei:TEI>   
            else if(contains($id,'/manuscript/')) then
                for $rec in collection($config:data-root)//tei:idno[@type='URI'][. = $id]
                return 
                    if($rec/ancestor::tei:msPart) then
                       <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec/ancestor::tei:msPart}</tei:TEI>
                    else $rec/ancestor::tei:TEI
            else collection($config:data-root)//tei:TEI[.//tei:idno[@type='URI'][. = $id]][1]
        else if(request:get-parameter('doc', '') != '') then 
            if(starts-with(request:get-parameter('doc', ''),$config:data-root)) then 
                doc(xmldb:encode-uri(request:get-parameter('doc', '') || '.xml'))
            else doc(xmldb:encode-uri($config:data-root || "/" || request:get-parameter('doc', '') || '.xml'))
        else ()
    :)    
    (:
    if(request:get-parameter('id', '') != '') then  
        if($config:document-id) then 
            collection($config:data-root)//tei:idno[. = request:get-parameter('id', '')][@type='URI']/ancestor::tei:TEI
        else collection($config:data-root)/id(request:get-parameter('id', ''))/ancestor::tei:TEI
    
    else if(request:get-parameter('doc', '') != '') then 
        if(starts-with(request:get-parameter('doc', ''),$config:data-root)) then 
            doc(xmldb:encode-uri(request:get-parameter('doc', '') || '.xml'))
        else doc(xmldb:encode-uri($config:data-root || "/" || request:get-parameter('doc', '') || '.xml'))
    else ()
    :)
};

declare function data:get-document($id as xs:string?) {
        if($id != '') then
            if(contains($id,'/spear/')) then
                for $rec in collection($config:data-root)//tei:div[@uri = $id]
                return <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec}</tei:TEI>   
            else if(contains($id,'/manuscript/')) then
                for $rec in collection($config:data-root)//tei:idno[@type='URI'][. = $id]
                return 
                    if($rec/ancestor::tei:msPart) then
                       <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec/ancestor::tei:msPart}</tei:TEI>
                    else $rec/ancestor::tei:TEI
            else collection($config:data-root)//tei:TEI[.//tei:idno[@type='URI'][. = concat($id,'/tei')]][1]
        else if(request:get-parameter('doc', '') != '') then 
            if(starts-with(request:get-parameter('doc', ''),$config:data-root)) then 
                doc(xmldb:encode-uri(request:get-parameter('doc', '') || '.xml'))
            else doc(xmldb:encode-uri($config:data-root || "/" || request:get-parameter('doc', '') || '.xml'))
        else () 
};

(:~
  : Select correct tei element to base browse list on. 
  : Places use tei:place/tei:placeName
  : Persons use tei:person/tei:persName
  : Defaults to tei:title
:)
declare function data:element($element as xs:string?) as xs:string?{
    if(request:get-parameter('element', '') != '') then 
        request:get-parameter('element', '') 
    else if($element) then $element        
    else "tei:titleStmt/tei:title[@level='a']"  
};

(:~
 : Make XPath language filter. 
 : @param $element used to select browse element: persName/placeName/title
:)
declare function data:element-filter($element as xs:string?) as xs:string? {    
    if(request:get-parameter('lang', '') != '') then 
        if(request:get-parameter('alpha-filter', '') = 'ALL') then 
            concat("/descendant::",$element,"[@xml:lang = '", request:get-parameter('lang', ''),"']")
        else concat("/descendant::",$element,"[@xml:lang = '", request:get-parameter('lang', ''),"']")
    else
        if(request:get-parameter('alpha-filter', '') = 'ALL') then 
            concat("/descendant::",$element)
        else concat("/descendant::",$element)
};

(:~
 : Build browse/search path.
 : @param $collection name from repo-config.xml
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection. TEI collection is defined in the seriesStmt
 : Enhancement: It would be nice to be able to pass in multiple collections to browse function
:)
declare function data:build-collection-path($collection as xs:string?) as xs:string?{  
    let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($collection != '') then concat('/',$collection)
            else ()
    let $get-series :=  
            if(config:collection-vars($collection)/@collection-URI != '') then string(config:collection-vars($collection)/@collection-URI)
            else ()                             
    let $series-path := 
            if($get-series != '') then concat("//tei:idno[. = '",$get-series,"'][ancestor::tei:seriesStmt]/ancestor::tei:TEI")
            else "//tei:TEI"
    return concat("collection('",$config:data-root,$collection-path,"')",$series-path)
};

(:~
 : Get all data
 : @param $collection collection to limit results set by
 : @param $element TEI element to base sort order on. 
:)
declare function data:get-records($collection as xs:string*, $element as xs:string?){
    let $element := data:element($element)
    let $sort := 
        if(request:get-parameter('sort', '') != '') then request:get-parameter('sort', '') 
        else if(request:get-parameter('sort-element', '') != '') then request:get-parameter('sort-element', '')
        else ()     
    let $eval-string := concat(data:build-collection-path($collection),
                facet:facet-filter(global:facet-definition-file($collection)),
                data:element-filter($element))    
    let $hits := util:eval($eval-string)
    return 
        (: Syriaca.org specific browse functions :)
        if($collection = ('places','geo') and request:get-parameter('view', '') = 'type') then  
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            let $title := global:build-sort-string($root/descendant::tei:titleStmt/tei:title[1],'')
            let $id := $root/descendant::tei:publicationStmt/tei:idno[1]
            group by $facet-grp := $id
            order by $title[1] collation 'http://www.w3.org/2013/collation/UCA'
            where $root/descendant::tei:place[contains(@type, request:get-parameter('type', ''))]
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort="{$sort}">{$root}</browse>
        (: Bibl browse :)
        else if($collection = 'bibl' and not(request:get-parameter('view', ''))) then
            for $hit in $hits[matches(.,'\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}','i')]
            let $root := $hit/ancestor-or-self::tei:TEI
            where $hit[matches(substring(global:build-sort-string(.,''),1,1),global:get-alpha-filter(),'i')]
            order by global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'') collation 'http://www.w3.org/2013/collation/UCA'
            return $root
        else if(request:get-parameter('view', '') = 'A-Z') then 
            for $hit in $hits[matches(.,'\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}','i')]
            let $root := $hit/ancestor-or-self::tei:TEI
            let $sort := global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'')
            where $hit[matches(substring(global:build-sort-string($root,''),1,1),global:get-alpha-filter(),'i')]
            order by $sort collation 'http://www.w3.org/2013/collation/UCA'
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort="{$sort}">{$root}</browse>
        else if(request:get-parameter('view', '') = 'ܐ-ܬ') then
            for $hit in $hits[matches(.,'\p{IsSyriac}','i')]
            let $root := $hit/ancestor-or-self::tei:TEI
            order by global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'') collation 'http://www.w3.org/2013/collation/UCA'
            return $root                            
        else if(request:get-parameter('view', '') = 'ا-ي') then
            for $hit in $hits[matches(.,'\p{IsArabic}','i')]
            let $root := $hit/ancestor-or-self::tei:TEI
            order by global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'ar') collation 'http://www.w3.org/2013/collation/UCA'
            return $root 
        else if(request:get-parameter('view', '') = 'other') then
            for $hit in $hits[not(matches(substring(global:build-sort-string(.,''),1,1),'\p{IsSyriac}|\p{IsArabic}|\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}|\p{IsLatinExtendedAdditional}','i'))]
            let $root := $hit/ancestor-or-self::tei:TEI
            order by global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'') collation 'http://www.w3.org/2013/collation/UCA'
            return $root         
        else if(request:get-parameter('view', '') = 'all') then
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            order by global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'') collation 'http://www.w3.org/2013/collation/UCA'
            return $root             
        (: Generic :)             
        else if(request:get-parameter('view', '') = 'map') then 
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            let $id := $root/descendant::tei:publicationStmt/tei:idno[1]
            group by $facet-grp := $id
            (:where $root[1]//tei:geo:)
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort="{$sort[1]}">{$root[1]}</browse>  
        else if(request:get-parameter('alpha-filter', '') = ('ALL','all') or request:get-parameter('alpha-filter', '') = '') then 
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            let $sort := global:build-sort-string($hit,request:get-parameter('lang', ''))
            let $id := $root/descendant::tei:publicationStmt/tei:idno[1]
            group by $facet-grp := $id
            order by $sort[1] collation 'http://www.w3.org/2013/collation/UCA'
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort="{string($sort[1])}">{$root[1]}</browse>              
        else 
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            let $sort := global:build-sort-string($hit,request:get-parameter('lang', ''))
            (:let $id := $root/descendant::tei:publicationStmt/tei:idno[1]
              group by $facet-grp := $id:)
            order by $sort collation 'http://www.w3.org/2013/collation/UCA'
            where matches($sort,global:get-alpha-filter())
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort="{$sort}">{$root}</browse> 
(:
if(request:get-parameter('view', '') = 'title') then 
            if(request:get-parameter('alpha-filter', '') = 'ALL' or request:get-parameter('alpha-filter', '') = '') then
                for $hit in $hits-main
                let $num := if(xs:integer($hit/@n)) then xs:integer($hit/@n) else 0
                order by global:build-sort-string($hit/text()[1],''), $num
                return <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
            else 
                for $hit in $hits-main[matches(substring(global:build-sort-string(.,$data:computed-lang),1,1),data:get-alpha-filter(),'i')]
                let $num := if(xs:integer($hit/@n)) then xs:integer($hit/@n) else 0
                order by global:build-sort-string($hit/text()[1],$data:computed-lang), $num
                return <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>             
        else
            if(request:get-parameter('alpha-filter', '') = 'ALL' or request:get-parameter('alpha-filter', '') = '') then
                for $hit in $hits-main
                order by global:build-sort-string(page:add-sort-options($hit/text()[1],$element),'') 
                return <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
            else 
                for $hit in $hits-main[matches(substring(global:build-sort-string(.,$data:computed-lang),1,1),data:get-alpha-filter(),'i')]
                order by global:build-sort-string(page:add-sort-options($hit/text()[1],$element),'') 
                return <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
:)            
};

(:~
 : Main search functions.
 : Build a search XPath based on search parameters. 
 : Add sort options. 
:)
declare function data:search($collection as xs:string*, $queryString as xs:string?) {                      
    let $eval-string := if($queryString != '') then $queryString 
                        else concat(data:build-collection-path($collection), data:create-query($collection),facet:facet-filter(global:facet-definition-file($collection)))
    let $hits := util:eval($eval-string)
    return 
        if(request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance' or request:get-parameter('view', '') = 'all') then 
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            let $sort := 
                if($collection = 'bibl') then
                    global:build-sort-string(data:add-sort-options-bibl($root, request:get-parameter('sort-element', '')),'')
                else global:build-sort-string(data:add-sort-options($root, request:get-parameter('sort-element', '')),'')
            order by $sort collation 'http://www.w3.org/2013/collation/UCA'
            return $root
        else if(request:get-parameter('relId', '') != '' and (request:get-parameter('sort-element', '') = '' or not(exists(request:get-parameter('sort-element', ''))))) then
            for $h in $hits
                let $part := 
                      if ($h/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n castable as  xs:integer)
                      then xs:integer($h/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
                      else 0
            order by $part
            return $h 
        else 
            for $hit in $hits
            let $root := $hit/ancestor-or-self::tei:TEI
            order by ft:score($hit) + (count($hit/descendant::tei:bibl) div 100) descending
            return $root 
};

(:~   
 : Builds general search string.
:)
declare function data:create-query($collection as xs:string?) as xs:string?{
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
         if(doc-available($search-config)) then 
            concat(string-join(data:dynamic-paths($search-config),''),data:relation-search())
        else
            concat(
            data:keyword-search(),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('author',request:get-parameter('author', '')),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:relation-search()
            )       
};

(:~ 
 : Adds sort filter based on sort prameter
 : Currently supports sort on title, author, publication date and person dates
 : @param $sort-option
:)
declare function data:add-sort-options($hit, $sort-option as xs:string*){
    if($sort-option != '') then
        if($sort-option = 'title') then 
           $hit/descendant::tei:titleStmt/tei:title[1]
        else if($sort-option = 'author') then 
            if($hit/descendant::tei:titleStmt/tei:author[1]) then 
                if($hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname[1]
                else $hit//descendant::tei:author[1]
            else 
                if($hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname[1]
                else $hit/descendant::tei:titleStmt/tei:editor[1]
        else if($sort-option = 'pubDate') then 
            $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:date[1]
        else if($sort-option = 'pubPlace') then 
            $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
        else if($sort-option = 'persDate') then
            if($hit/descendant::tei:birth) then xs:date($hit/descendant::tei:birth/@syriaca-computed-start)
            else if($hit/descendant::tei:death) then xs:date($hit/descendant::tei:death/@syriaca-computed-start)
            else ()
        else $hit
    else $hit
};

(:~
 : Search options passed to ft:query functions
 : Defaults to AND
:)
declare function data:search-options(){
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>1</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
};

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
:)
declare function data:clean-string($string){
let $query-string := $string
let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) then 
	       replace($query-string, '"', ' ')
	   else $query-string   (:if there is an uneven number of quotation marks, delete all quotation marks.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
let $query-string := replace($string,"'","''")	   
return 
    if(matches($query-string,"(^\*$)|(^\?$)")) then 'Invalid Search String, please try again.' (: Must enter some text with wildcard searches:)
    else replace(replace($query-string,'<|>|@|&amp;',''), '(\.|\[|\]|\\|\||\-|\^|\$|\+|\{|\}|\(|\)|(/))','\\$1')

};

(:~
 : Build XPath filters from values in search-config.xml
 : Matches request paramters with @name in search-config to find the matching XPath. 
:)
declare function data:dynamic-paths($search-config as xs:string?){
    let $config := doc($search-config)
    let $params := request:get-parameter-names()
    return string-join(
        for $p in $params
        return 
            if(request:get-parameter($p, '') != '') then
                if($p = 'keyword') then
                    data:keyword-search()
                else if($p = 'idno') then
                    data:idno()                    
                else if(string($config//input[@name = $p]/@element) = '.') then
                    concat("[ft:query(.//tei:body,'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                else if(string($config//input[@name = $p]/@element) != '') then
                    concat("[ft:query(.//",string($config//input[@name = $p]/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                else ()    
            else (),'')
};

(:
 : General keyword anywhere search function 
:)
declare function data:keyword-search(){
    if(request:get-parameter('keyword', '') != '') then 
        for $query in request:get-parameter('keyword', '') 
        return concat("[ft:query(descendant-or-self::tei:body,'",data:clean-string($query),"',data:search-options()) or ft:query(ancestor-or-self::tei:TEI/descendant::tei:teiHeader,'",data:clean-string($query),"',data:search-options())]")
    else if(request:get-parameter('q', '') != '') then 
        for $query in request:get-parameter('q', '') 
        return concat("[ft:query(descendant-or-self::tei:body,'",data:clean-string($query),"',data:search-options()) or ft:query(ancestor-or-self::tei:TEI/descendant::tei:teiHeader,'",data:clean-string($query),"',data:search-options())]")
    else ()
};

(:~
 : Add a generic relationship search to any search module. 
:)
declare function data:relation-search(){
    if(request:get-parameter('relation-id', '') != '') then
        if(request:get-parameter('relation-type', '') != '') then
            concat("[descendant::tei:relation[@passive[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')] or @mutual[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')]][@ref = '",request:get-parameter('relation-type', ''),"' or @name = '",request:get-parameter('relation-type', ''),"']]")
        else concat("[descendant::tei:relation[@passive[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')] or @mutual[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')]]]")
    else ()
};

(:
 : General search function to pass in any TEI element. 
 : @param $element element name must have a lucene index defined on the element
 : @param $query query text to be searched. 
:)
declare function data:element-search($element, $query){
    if(exists($element) and $element != '') then 
        if(request:get-parameter($element, '') != '') then 
            for $e in $element
            return concat("[ft:query(descendant::tei:",$element,",'",data:clean-string($query),"',data:search-options())]")            
        else ()
    else ()
};

(:
 : Add your custom search paths here: 
 : Example of a complex search used by Syriaca.org
 : Search for bibl records with matching URI
 declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := data:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($config:data-root || '/bibl')//tei:body[ft:query(.,$terms, data:search-options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()  
};
:)

(: Syriaca.org specific search functions :)
(:~
 : Generic search related places 
:)
declare function data:related-places() as xs:string?{
    if(request:get-parameter('related-place', '') != '') then
        let $related-place := request:get-parameter('related-place', '')
        let $ids := 
            if(matches($related-place,'^http://syriaca.org/')) then
                normalize-space($related-place)
            else 
                string-join(distinct-values(
                    for $r in collection($config:data-root || '/places')//tei:place[ft:query(tei:placeName,$related-place,data:search-options())]
                    let $id := $r//tei:idno[starts-with(.,'http://syriaca.org')]
                    return $id),'|')                   
        return 
            if($ids != '') then 
                if(request:get-parameter('place-type', '') !='' and request:get-parameter('place-type', '') !='any') then 
                    if(request:get-parameter('place-type', '') = 'birth') then 
                        concat("[descendant::tei:relation[@name ='born-at'][@passive[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')]]]")
                    else if(request:get-parameter('place-type', '') = 'death') then
                        concat("[descendant::tei:relation[@name ='died-at'][@passive[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')]]]")   
                    else if(request:get-parameter('place-type', '') = 'venerated') then 
                        concat("[descendant::tei:event[matches(@contains,'",$ids,"(\W.*)?$')]]")
                    else concat("[descendant::tei:relation[@name ='",request:get-parameter('place-type', ''),"'][@passive[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')]]]")             
                else concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"(\W.*)?$')] or @mutual[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')]]]")
           else ()     
    else ()
};

(:~
 : Generic search related persons 
:)
declare function data:related-persons() as xs:string?{
    if(request:get-parameter('related-persons', '') != '') then
        let $rel-person := request:get-parameter('related-persons', '')
        let $ids := 
            if(matches($rel-person,'^http://syriaca.org/')) then
                normalize-space($rel-person)
            else 
                string-join(distinct-values(
                    for $r in collection($config:data-root || '/persons')//tei:person[ft:query(tei:persName,$rel-person,data:search-options())]
                    let $id := $r//tei:idno[starts-with(.,'http://syriaca.org')]
                    return $id),'|')   
        return 
            if(request:get-parameter('person-type', '')) then
                let $relType := request:get-parameter('person-type', '')
                return 
                    concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')] or @mutual[matches(.,'",$ids,"(\W.*)?$')]][@ref = '",$relType,"' or @name = '",$relType,"']]")
            else concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"(\W.*)?$')] or @mutual[matches(.,'",$ids,"(\W.*)?$')] or @active[matches(.,'",$ids,"(\W.*)?$')]]]")
    else ()
};

(:~
 : Generic search related titles 
:)
declare function data:mentioned() as xs:string?{
    if(request:get-parameter('mentioned', '') != '') then 
        if(matches(request:get-parameter('mentioned', ''),'^http://syriaca.org/')) then 
            let $id := normalize-space(request:get-parameter('mentioned', ''))
            return concat("[descendant::*[@ref[matches(.,'",$id,"(\W.*)?$')]]]")
        else 
            concat("[descendant::*[ft:query(tei:title,'",data:clean-string(request:get-parameter('mentioned', '')),"',data:search-options())]]")
    else ()  
};

(:~ 
 : Adds sort filter based on sort prameter
 : Currently supports sort on title, author, publication date and person dates
 : @param $sort-option
:)
declare function data:add-sort-options-bibl($hit, $sort-option as xs:string*){
    if($sort-option != '') then
        if($sort-option = 'title') then 
            $hit/descendant::tei:body/tei:biblStruct/tei:title[1]
        else if($sort-option = 'author') then 
            if($hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:author[1]) then 
                if($hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:author[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:author[1]/descendant-or-self::tei:surname[1]
                else $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:author[1]
            else 
                if($hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:editor[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:editor[1]/descendant-or-self::tei:surname[1]
                else $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:editor[1]
        else if($sort-option = 'pubDate') then 
            $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:imprint[1]/descendant-or-self::tei:date[1]
        else if($sort-option = 'pubPlace') then 
            $hit/descendant::tei:body/tei:biblStruct/descendant-or-self::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
        else $hit
    else $hit
};

(:~
 : Generic id search
 : Searches record idnos
:)
declare function data:idno() as xs:string? {
    if(request:get-parameter('idno', '') != '') then 
        (:let $id := replace(request:get-parameter('idno', ''),'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/work/',$id)
        return concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
        :)
        concat("[descendant::tei:idno[normalize-space(.) = '",request:get-parameter('idno', ''),"']]")
    else ()    
};