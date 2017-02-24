xquery version "3.0";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by browse, search, and view records.  
 :
 : @see lib/facet.xqm for facets
 : @see lib/paging.xqm for sort options
 : @see lib/global.xqm for global variables 
 :)

module namespace data="http://syriaca.org/data";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "../facet-defs.xqm";
import module namespace page="http://syriaca.org/page" at "paging.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Set a default value for language, default sets to English, used in setting browse options. 
 : @param $data:lang language parameter from URL
:)
declare variable $data:computed-lang{ 
    if(request:get-parameter('lang', '') != '') then request:get-parameter('lang', '')
    else if(request:get-parameter('lang', '') = '' and request:get-parameter('sort', '')) then 'en'
    else if(request:get-parameter('view', '') = '') then 'en'
    else ()
};

(:
 : Generic get record function
 : Manuscripts and SPEAR recieve special treatment as individule parts may be treated as full records. 
 : Syriaca.org uses tei:idno for record IDs 
 : @param $id syriaca.org uri for record or part. 
:)
declare function data:get-rec($id as xs:string?){  
    if(contains($id,'/spear/')) then 
        for $rec in collection($global:data-root)//tei:div[@uri = $id]
        return 
            <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec}</tei:TEI>   
    else if(contains($id,'/manuscript/')) then
    (: Descrepency in how id's are handled, why dont the msPart id's have '/tei'?  :)
        for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = $id]
        return 
            if($rec/ancestor::tei:msPart) then
               <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$rec/ancestor::tei:msPart}</tei:TEI>
            else $rec/ancestor::tei:TEI
    else 
        if($global:id-path != '') then
            for $rec in util:eval(concat('collection($global:data-root)//tei:TEI[',$global:id-path,' = $id]'))
            return $rec
        else
            for $rec in collection($global:data-root)//tei:TEI[.//tei:idno[@type='URI'][text() = concat($id,'/tei')]]
            return $rec 
};

(:~
 : Get record title if record exists, otherwise return $uri
 : @param $uri
:)
declare function data:get-title($uri as xs:string?) as xs:string?{
    let $doc := collection($global:data-root)//tei:TEI[.//tei:idno = concat($uri,"/tei")][1]
    return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ',' ')
      else $uri 
};

(:~
 : Build browse path.
 : @param $collection as xs:string physical eXistdb collection
 : @param $series as xs:string defined by seriesStmt
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection, seriesStmt
 : Enhancement: It would be nice to be able to pass in multiple collections to browse function
:)
declare function data:build-browse-path($collection as xs:string?, $series as xs:string?) as xs:string?{  
    concat("collection('",$global:data-root,$collection,"')",data:build-series-path($series))
};

(:
 : Build browse path.
 : @param $series as xs:string defined by seriesStmt
 :)
declare function data:build-series-path($series as xs:string?) as xs:string? {
    if($series != '') then concat("//tei:title[. = '",data:parse-collections($series),"'][ancestor::tei:seriesStmt]/ancestor::tei:TEI")
    else '//tei:TEI'
};

(:~
 : Syriaca.org specific function to parse collection to match series name
 : @param $series
:)
declare function data:parse-collections($series as xs:string?) as xs:string? {
    if($series = ('persons','sbd')) then 'The Syriac Biographical Dictionary'
    else if($series = ('saints','q')) then 'Qadishe: A Guide to the Syriac Saints'
    else if($series = 'authors' ) then 'A Guide to Syriac Authors'
    else if($series = 'bhse' ) then 'Bibliotheca Hagiographica Syriaca Electronica'
    else if($series = 'nhsl' ) then 'New Handbook of Syriac Literature'
    else if($series = ('places','The Syriac Gazetteer')) then 'The Syriac Gazetteer'
    else if($series = ('spear','SPEAR: Syriac Persons, Events, and Relations')) then 'SPEAR: Syriac Persons, Events, and Relations'
    else if($series != '' ) then $series
    else ()
};

(:~
 : Make XPath language filter. 
 : @param $element used to select browse element: persName/placeName/title
:)
declare function data:lang-filter($element as xs:string?) as xs:string? {    
    if($data:computed-lang != '') then 
        concat("/descendant::",$element,"[@xml:lang = '", $data:computed-lang, "']")
    else ()
};

(:~
  : Select correct tei element to base browse list on. 
  : Places use tei:place/tei:placeName
  : Persons use tei:person/tei:persName
  : Defaults to tei:title
:)
declare function data:element($element as xs:string?, $series as xs:string?) as xs:string?{
    (: Syriaca.org defaults :)
    if($series = ('persons','sbd','saints','q','authors')) then 
        if($data:computed-lang = ('en','syr')) then 
            'tei:person/tei:persName[@syriaca-tags="#syriaca-headword"]'
        else 'tei:person/tei:persName'
    else if($series = ('places','geo','The Syriac Gazetteer')) then 
        if($data:computed-lang = ('en','syr')) then 
            'tei:place/tei:placeName[@syriaca-tags="#syriaca-headword"]'
        else 'tei:place/tei:placeName'
    else if($series = ('bhse','nhsl')) then 
        if($data:computed-lang = ('en','syr')) then 
            'tei:body/tei:bibl/tei:title[@syriaca-tags="#syriaca-headword"]'
        else 'tei:body/tei:bibl/tei:title'            
    (: Default browse is by tei:title:)   
    else if(request:get-parameter('element', '') != '') then 
        request:get-parameter('element', '') 
    else if($element) then $element        
    else "tei:title"  
};

(:~
  : Select correct exist-db collection 
  : @param $collection as xs:string
:)
declare function data:collection-path($collection as xs:string?) as xs:string{
    (: Syriaca.org defaults :)
    if($collection = ('persons','sbd','saints','q','authors')) then 
        '/persons'
    else if($collection = ('places','geo','The Syriac Gazetteer')) then 
        '/places'
    else if($collection = ('bhse','nhsl')) then  
        '/works' 
    else if($collection = ('bibl')) then 
        '/bibl'  
    else if($collection = ('spear')) then 
        '/spear'           
    (: Default browse is by all directories under data-root :)
    else if(request:get-parameter('collection', '') != '') then 
        concat('/',request:get-parameter('collection', '')) 
    else if($collection) then 
        concat('/',$collection)        
    else '' 
};

(:
 : Main browse function 
 : @param $collection as xs:string physical eXistdb collection
 : @param $series as xs:string defined by seriesStmt
 : @param $element as xs:string, element to be used browse on, xpath: ex: //tei:titleStmt/tei:author defaults to //tei:titleStmt/tei:title
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection, seriesStmt
:)
declare function data:get-browse-data($collection as xs:string*, $series as xs:string*, $element as xs:string?){
    let $element := if($series != '') then data:element($element, $series)
                    else data:element($element, $collection)
    let $facets := if($series != '') then $series
                   else $collection
    let $sort := if(request:get-parameter('sort', '') != '') then request:get-parameter('sort', '') 
                 else if(request:get-parameter('sort-element', '') != '') then request:get-parameter('sort-element', '')
                 else ()        
    let $hits-main := util:eval(concat(data:build-browse-path(data:collection-path($collection), $series),facet:facet-filter(facet-defs:facet-definition($facets)),data:lang-filter($element)))
    return 
    (:<p>{concat(data:build-browse-path(data:collection-path($collection), $series),facet:facet-filter(facet-defs:facet-definition($series)),data:lang-filter($element))}</p>:)
    (: Special SPEAR options:)
        if($collection = 'spear') then util:eval(concat(data:build-browse-path($collection, $series),'//tei:div[parent::tei:body]'))
    (: Special places browse by type:)
        else if($collection = ('places','geo') and request:get-parameter('view', '') = 'type') then 
             let $hits := util:eval(concat("$hits-main[descendant::tei:place[contains(@type,'", request:get-parameter('type', ''),"')]]"))
             for $hit in $hits
             let $title := global:build-sort-string($hit,$data:computed-lang)
             order by $title collation "?lang=en&lt;syr&amp;decomposition=full"
             return $hit/ancestor-or-self::tei:TEI
    (: Special bibl options :)
        else if($collection = 'bibl' and not(request:get-parameter('view', ''))) then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}','i')]
            where $hit[matches(substring(global:build-sort-string(.,$data:computed-lang),1,1),data:get-alpha-filter(),'i')]
            order by global:build-sort-string(page:add-sort-options($hit,$sort),'')
            return $hit/ancestor::tei:TEI
        else if(request:get-parameter('view', '') = 'A-Z') then 
            for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}','i')]
            where $hit[matches(substring(global:build-sort-string(.,$data:computed-lang),1,1),data:get-alpha-filter(),'i')]
            order by global:build-sort-string(page:add-sort-options($hit,$sort),'')
            return $hit/ancestor::tei:TEI
        else if(request:get-parameter('view', '') = 'ܐ-ܬ') then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsSyriac}','i')]
            order by global:build-sort-string(page:add-sort-options($hit,$sort),'') collation "?lang=syr&amp;decomposition=full"
            return $hit/ancestor::tei:TEI                            
        else if(request:get-parameter('view', '') = 'ا-ي') then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][matches(.,'\p{IsArabic}','i')]
            order by  global:build-sort-string(page:add-sort-options($hit,$sort),'ar') collation "?lang=ar&amp;decomposition=full"
            return $hit/ancestor::tei:TEI 
        else if(request:get-parameter('view', '') = 'other') then
            for $hit in $hits-main//tei:titleStmt/tei:title[1][not(matches(substring(global:build-sort-string(.,''),1,1),'\p{IsSyriac}|\p{IsArabic}|\p{IsBasicLatin}|\p{IsLatin-1Supplement}|\p{IsLatinExtended-A}|\p{IsLatinExtended-B}|\p{IsLatinExtendedAdditional}','i'))]
            order by global:build-sort-string(page:add-sort-options($hit,$sort),'') collation "?lang=en&lt;syr&lt;ar&amp;decomposition=full"
            return $hit/ancestor::tei:TEI         
        else if(request:get-parameter('view', '') = 'all') then
            for $hit in $hits-main/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]
            order by global:build-sort-string(page:add-sort-options($hit,$sort),'') collation "?lang=en&lt;syr&amp;decomposition=full"
            return $hit/ancestor::tei:TEI
    (: Generic options :)        
        else if($data:computed-lang != '') then 
            for $hit in $hits-main[matches(substring(global:build-sort-string(.,$data:computed-lang),1,1),data:get-alpha-filter(),'i')]
            let $title := global:build-sort-string($hit,$data:computed-lang)
            order by $title collation "?lang=en&lt;syr&amp;decomposition=full"
            return <browse xmlns="http://www.tei-c.org/ns/1.0" sort-title="{$hit}">{$hit/ancestor::tei:TEI}</browse>
        else if(request:get-parameter('view', '') = 'numeric') then
            for $hit in $hits-main/ancestor::tei:TEI/descendant::tei:idno[starts-with(.,$global:base-uri)][1]
            let $rec-id := tokenize(replace($hit,'/tei|/source',''),'/')[last()]
            order by xs:integer($rec-id)
            return $hit/ancestor::tei:TEI    
        else
            for $hit in $hits-main
            let $title := global:build-sort-string($hit,$data:computed-lang)
            order by $title collation "?lang=en&lt;syr&amp;decomposition=full"
            return $hit/ancestor-or-self::tei:TEI

       
};

(:
 : Limit results by per-page browse function 
 : @param $collection as xs:string physical eXistdb collection
 : @param $series as xs:string defined by seriesStmt
 : @param $element as xs:string, element to be used browse on, xpath: ex: //tei:titleStmt/tei:author defaults to //tei:titleStmt/tei:title
 : @param $start
 : @part $perpage
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection, seriesStmt
:)
declare function data:browse-data-pages($collection as xs:string*, $series as xs:string*, $element as xs:string?, $start as xs:integer?, $perpage as xs:integer?){
    for $hit in subsequence(data:get-browse-data($collection, $series, $element), $start, $perpage)
    return $hit    
};

(: Search functions :)
declare function data:search($query-string as xs:string?){
    if(exists(request:get-parameter-names()) or (request:get-parameter('view', '') = 'all')) then 
        if(request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance' or request:get-parameter('view', '') = 'all') then 
            for $hit in util:eval($query-string)
            order by global:build-sort-string(page:add-sort-options($hit,request:get-parameter('sort-element', '')),'') ascending
            return $hit   
        else if(request:get-parameter('rel', '') != '' and (request:get-parameter('sort-element', '') = '' or not(exists(request:get-parameter('sort-element', ''))))) then 
            for $hit in util:eval($query-string)
            let $part := xs:integer($hit/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('child-rec', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
            order by $part
            return $hit                                                                                               
        else 
            for $hit in util:eval($query-string)
            (: let $expanded := util:expand($hit, "expand-xincludes=no")
               let $headword := count($expanded/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][descendant::*:match])
                let $headword := if($headword gt 0) then $headword + 15 else 0:)
            order by ft:score($hit) + (count($hit/descendant::tei:bibl) div 100) descending
            return $hit
    else ()  
};

(:
 : Limit results by per-page search function 
 : @param $query-string
 : @param $start
 : @part $perpage
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection, seriesStmt
:)
declare function data:search-pages($query-string as xs:string*, $start as xs:integer?, $perpage as xs:integer?){
    for $hit in subsequence(data:search($query-string), $start, $perpage)
    return $hit    
};

(:~
 : Search options passed to ft:query functions
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
    else replace(replace($query-string,'<|>|@',''), '(\.|\[|\]|\\|\||\-|\^|\$|\+|\{|\}|\(|\)|(/))','\\$1') (: Escape special characters. Fixes error, but does not return correct results on URIs see: http://viaf.org/viaf/sourceID/SRP|person_308 :)

};

(:
 : Build full-text keyword search over full record data 
:)
declare function data:keyword(){
    if(request:get-parameter('q', '') != '') then 
        if(starts-with(request:get-parameter('q', ''),'http://syriaca.org/')) then
           concat("[ft:query(descendant::*,'&quot;",request:get-parameter('q', ''),"&quot;',data:search-options())]")
        else concat("[ft:query(descendant::*,'",data:clean-string(request:get-parameter('q', '')),"',data:search-options())]")
    else '' 
};

(:~
 : Add a generic relationship search to any search module. 
:)
declare function data:relation-search(){
if(request:get-parameter('rel', '') != '') then
    let $q := request:get-parameter('rel', '')
    return 
        if(request:get-parameter('relType', '') != '') then
            let $relType := request:get-parameter('relType', '')
            return 
                concat("[descendant::tei:relation[@passive[matches(.,'",$q,"(\W.*)?$')] or @active[matches(.,'",$q,"(\W.*)?$')] or @mutual[matches(.,'",$q,"(\W.*)?$')]][@ref = '",request:get-parameter('relType', ''),"' or @name = '",request:get-parameter('relType', ''),"']]")
        else concat("[descendant::tei:relation[@passive[matches(.,'",$q,"(\W.*)?$')] or @active[matches(.,'",$q,"(\W.*)?$')] or @mutual[matches(.,'",$q,"(\W.*)?$')]]]")
else ''
};

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
                    for $r in collection($global:data-root || '/places')//tei:place[ft:query(tei:placeName,$related-place,data:search-options())]
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
                    for $r in collection($global:data-root || '/persons')//tei:person[ft:query(tei:persName,$rel-person,data:search-options())]
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
 : Generic id search
 : Searches record idnos
:)
declare function data:idno() as xs:string? {
    if(request:get-parameter('idno', '') != '') then 
        let $id := replace(request:get-parameter('idno', ''),'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/work/',$id)
        return concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    else ''    
};

(:~
 : Generic URI search
 : Searches record URIs and also references to record ids.
:)
declare function data:uri() as xs:string? {
    if(request:get-parameter('uri', '') != '') then 
        let $q := request:get-parameter('uri', '')
        return 
        concat("
        [ft:query(descendant::*,'&quot;",$q,"&quot;',data:search-options()) or 
            .//@passive[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@mutual[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@active[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@ref[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@target[matches(.,'",$q,"(\W.*)?$')]
        ]")
    else ''    
};

(:
 : General search function to pass in any tei element. 
 : @param $element element name must have a lucene index defined on the element
 : @param $query query text to be searched. 
:)
declare function data:element-search($element, $query){
    if(exists($element) and $element != '') then 
        for $e in $element
        return concat("[ft:query(descendant::tei:",$element,",'",data:clean-string($query),"',data:search-options())]") 
    else '' 
};


(:~
 : Matches English letters and their equivalent letters as established by Syriaca.org
 : @param $data:sort indicates letter for browse
 :)
declare function data:get-alpha-filter(){
let $sort := request:get-parameter('alpha-filter', '')
return 
    if($sort != '') then
        if(request:get-parameter('lang', '') = 'ar') then
            data:ar-sort()
        else
            if($sort = 'A') then '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
            else if($sort = 'D') then '(D|d|đ|Đ)'
            else if($sort = 'S') then '(S|s|š|Š|ṣ|Ṣ)'
            else if($sort = 'E') then '(E|e|ễ|Ễ)'
            else if($sort = 'U') then '(U|u|ū|Ū)'
            else if($sort = 'H') then '(H|h|ḥ|Ḥ)'
            else if($sort = 'T') then '(T|t|ṭ|Ṭ)'
            else if($sort = 'I') then '(I|i|ī|Ī)'
            else if($sort = 'O') then '(O|Ō|o|Œ|œ)'
            else $sort
    else '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
};

(:~
 : Matches Arabic letters and their equivalent letters as established by Syriaca.org
 : @param $data:sort indicates letter for browse
 :)
declare function data:ar-sort(){
let $sort := request:get-parameter('alpha-filter', '')
return 
    if($sort = 'ٱ') then '(ٱ|ا|آ|أ|إ)'
        else if($sort = 'ٮ') then '(ٮ|ب)'
        else if($sort = 'ة') then '(ة|ت)'
        else if($sort = 'ڡ') then '(ڡ|ف)'
        else if($sort = 'ٯ') then '(ٯ|ق)'
        else if($sort = 'ں') then '(ں|ن)'
        else if($sort = 'ھ') then '(ھ|ه)'
        else if($sort = 'ۈ') then '(ۈ|ۇ|ٷ|ؤ|و)'
        else if($sort = 'ى') then '(ى|ئ|ي)'
        else $sort
};