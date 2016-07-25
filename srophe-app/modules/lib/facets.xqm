xquery version "3.0";
(:~
 : Facet library for Syriaca.org
 : Formats facets, facet filter to be added to xpath and add/remove facet buttons.  
 :)
 
module namespace facets="http://syriaca.org/facets";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(: External facet parameters :)
declare variable $facets:limit {request:get-parameter('limit', 5) cast as xs:integer};
declare variable $facets:fq {request:get-parameter('fq', '') cast as xs:string};

(:
NOTES about facet module
Will have to have a special cases to handle the crazyness of @ref facets
add facet parameters and functionality to browse.xm and search.xqm?
:)

(:
 : XPath filter to be passed to browse or search function
 : creates XPath based on facet node name.
:)
declare function facets:facet-filter(){
    if($facets:fq != '') then
        string-join(
        for $facet in tokenize($facets:fq,'fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            if($facet-value != '') then 
                if($facet-name = 'title') then 
                    concat("[ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[@level='a'][. = '",$facet-value,"']]")
                else if($facet-name = 'keyword') then 
                    concat("[descendant::*[matches(@ref,'(^|\W)",$facet-value,"(\W|$)') | matches(@target,'(^|\W)",$facet-value,"(\W|$)')]]")    
                else
                    concat('[descendant::tei:',$facet-name,'[normalize-space(.) = "',$facet-value,'"]]')
            else(),'')    
    else ()   
};

(:~ 
 : Builds new facet params. 
 :)
declare function facets:url-params(){
    string-join(for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if(request:get-parameter($param, '') = ' ') then ()
        else if(request:get-parameter($param, '') = '') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
};

(:~
 : Display selected facets, and button to remove from results set
:)
declare function facets:selected-facet-display(){
    for $facet in tokenize($facets:fq,' fq-')
    let $title := if(contains($facet,'http:')) then 
                    lower-case(functx:camel-case-to-words(substring-after($facet[1],'/keyword/'),' '))
                   else substring-after($facet,':')
    let $new-fq := string-join(for $facet-param in tokenize($facets:fq,' fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat('fq-',$facet-param),' ')
    let $href := concat('?fq=',$new-fq,facets:url-params())
    return 
        <span class="facet" title="Remove {$title}">
            <span class="label label-facet" title="{$title}">{$title} 
                <a href="{$href}" class="facet icon">
                    <span class="glyphicon glyphicon-remove" aria-hidden="true"></span>
                </a>
            </span>
        </span>
};

(:~
 : Build facets menus from facet nodes 
 : @param $facets nodes to facet on
:)
declare function facets:facets($facets as node()*){
<div>
    <span class="facets applied">
        {
            if($facets:fq) then facets:selected-facet-display()
            else ()            
        }
    </span>
    {
        for $facet-group in $facets
        group by $category := node-name($facet-group)
        return 
        <div>{(
            facets:display-grp($category),
            facets:display-labels($facet-group,$category))
            }</div>
    }
</div>
};

declare function facets:display-grp($category as xs:string*){
        <h4>{
                if(string($category) = 'persName') then 'Person' 
                else if(string($category) = 'placeName') then 'Place'
                else if(string($category) = 'event') then 'Keyword'
                else if(string($category) = 'title') then 'Source Text' 
                else string(functx:capitalize-first($category))
                }</h4>  
};

declare function facets:display-labels($facet-group, $category){
    if($facets:limit) then 
    let $count := count(facets:facet-type($facet-group,$category))
    return
        <div>
            <div class="facet-list show">{
                for $facet-list at $l in subsequence(facets:facet-type($facet-group,$category),1,$facets:limit)
                return $facet-list
            }</div>
            <div class="facet-list collapse" id="{concat('show',string($category))}">{
                for $facet-list at $l in subsequence(facets:facet-type($facet-group,$category),$facets:limit + 1)
                return $facet-list
            }</div>
            {if($count gt ($facets:limit - 1)) then 
                <a class="facet-label togglelink btn btn-info" data-toggle="collapse" data-target="#{concat('show',string($category))}" data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
            else()}
        </div>
    else facets:facet-type($facet-group,$category)
};

(:~ 
 : Handles @ref vrs element() facets  
 :)
declare function facets:facet-type($facets,$category){
    if(string($category) = 'keyword') then 
        facets:keyword($facets)
    (:else if($category = 'title') then facets:title($facets):)
    else if(string($category) = ('persName','placeName','title')) then facets:build-facet($facets, $category)
    else facets:build-facet-node($facets, $category)
};

(:~
 : NOTE need to rename to facets:build-facet-ref but need to address facets in events.xqm
 : Build individual facet lists for each facet category
 : @param $nodes nodes to facet on
:)
declare function facets:build-facet($nodes, $category){
    for $facet in $nodes
    group by $facet-grp := $facet/@ref
    order by count($facet) descending
    return  
        let $facet-val := $facet[1]
        let $facet-query := concat('fq-',$category,':',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($facet-val)} <span class="count">  ({count($facet)})</span></a>
};

(:~
 : Build individual facet lists for each facet category
 : @param $nodes nodes to facet on
:)
declare function facets:build-facet-node($nodes, $category){
    for $facet in $nodes
    group by $facet-grp := $facet/text()
    order by count($facet) descending
    return  
        let $facet-val := $facet[1]
        let $facet-query := concat('fq-',$category,':',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return <a href="?{$new-fq}{facets:url-params()}" class="facet-label btn btn-default" style="text-align:left;">{string($facet-val)} <span class="count">  ({count($facet)})</span></a>
};

(:~
 : Build individual facet lists for title facet category
 : Special because it is a parent of returned div, not child
 : @param $nodes nodes to facet on
:)
declare function facets:title($nodes){
    for $facet in $nodes
    group by $facet-grp := $facet/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[@level='a']/text()
    order by count($facet) descending
    return  
        let $facet-val := $facet-grp[1]
        let $facet-query := concat('fq-title:',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return 
            <a href="?{$new-fq}{facets:url-params()}" class="facet-label">
                {string($facet-val)} 
                <span class="count">  ({count($facet)})</span>
            </a>
};

(:~
 : Special handling for keywords which are in attributes and must be tokenized
 : @param $nodes nodes to build keyword list
:)
declare function facets:keyword-list($nodes){
    (for $keyword in $nodes//@target[contains(.,'/keyword/')]
    return 
        for $key in tokenize($keyword,' ')
        return <p>{$key}</p>,
    for $keyword in $nodes//@ref[contains(.,'/keyword/')]
    return
    for $key in tokenize($keyword,' ')
        return <p>{$key}</p>)
};

(:~
 : Special handling for keywords which are in attributes and must be tokenized
 : Facets on keyword list generated from events nodes passed to facets:facet()
 : @param $nodes nodes to build keyword list
:)
declare function facets:keyword($nodes){
    for $k in facets:keyword-list($nodes)
    group by $k := $k
    order by count($k) descending
    return
        let $khref := string($k[1])
        let $kpretty := lower-case(functx:camel-case-to-words(substring-after($k[1],'/keyword/'),' '))
        let $facet-query := concat('fq-keyword:',normalize-space($khref))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return
        <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($kpretty)} <span class="count"> ({count($k)})</span></a>
};