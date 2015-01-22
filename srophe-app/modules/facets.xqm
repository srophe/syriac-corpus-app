xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace facets="http://syriaca.org//facets";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $facets:limit {request:get-parameter('limit', 5) cast as xs:integer};
declare variable $facets:fq {request:get-parameter('fq', '') cast as xs:string};

(:
NOTES about facet module
Will have to have a special cases to handle the crazyness of @ref facets
add facet parameters and functionality to browse.xm and search.xqm?
:)

(:
 : Filter by facets to be passed to browse or search function
:)
declare function facets:facet-filter(){
    if($facets:fq != '') then
        string-join(
        for $facet in tokenize($facets:fq,'fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            if($facet-value != '') then 
                concat('[descendant::tei:',$facet-name,'[normalize-space(.) = "',$facet-value,'"]]')
            else(),'')    
    else ()   
};

(:~
 : Build facets menus from nodes passed by search or browse
 : @param $facets nodes to facet on
 : @param $facets:limit number of facets per catagory to display, defaults to 5
:)
declare function facets:facets($facets as node()*){
<div>
    <!--<div>{facets:facet-filter()}</div>-->
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
            <div class="category">
                {
                    if(string($category) = 'event') then 
                        <div>
                            <h4>Keyword</h4>
                            {
                                if($facets:limit) then 
                                    for $facet-list at $l in subsequence(facets:keyword($facets),1,$facets:limit)
                                    return $facet-list
                                else facets:keyword($facets)  
                            }
                        </div>    
                    else 
                        <div>
                            <h4>{string($category)}</h4>
                            {
                                if($facets:limit) then 
                                    for $facet-list at $l in subsequence(facets:build-facet($facet-group,string($category)),1,$facets:limit)
                                    return $facet-list
                                else facets:build-facet($facet-group,string($category))   
                            }
                        </div>
                }     
            </div>
    }
</div>
};

declare function facets:url-params(){
    string-join(for $param in request:get-parameter-names()
                return 
                    if($param = 'fq') then ()
                    else if($param != '' and $param != ' ') then concat('&amp;',$param, '=',normalize-space(request:get-parameter($param, '')))
                    else (),'')                    
};

(:~
 : Display selected facets, and button to remove from results set
:)
declare function facets:selected-facet-display(){
    for $facet in tokenize($facets:fq,' fq-')
    let $title := substring-after($facet,':')
    let $new-fq := 
        string-join(for $facet-param in tokenize($facets:fq,' fq-') 
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
 : Build individual facet lists for each facet category
 : @param $nodes nodes to facet on
:)
declare function facets:build-facet($nodes, $category){
    for $facet in $nodes
    group by $facet-grp := $facet
    order by count($facet) descending
    return  
        let $facet-val := $facet-grp[1]
        let $facet-query := concat('fq-',$category,':',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        let $uri := string($facet-val/@ref)
        return 
        <li><a href="?{$new-fq}{facets:url-params()}">{string($facet-val)}</a> ({count($facet)})</li>
};

(:~
 : Special handling for keywords which are in attributes and must be tokenized
 : @param $nodes nodes to build keyword list
:)
declare function facets:keyword-list($nodes){
    (for $keyword in $nodes//@target[contains(.,'/keyword/')]
    return <p>{tokenize($keyword,' ')}</p>,
    for $keyword in $nodes//@ref[contains(.,'/keyword/')]
    return <p>{tokenize($keyword,' ')}</p>)
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
        return
        <li><a href="{$khref}">{string($kpretty)}</a> [{count($k)}]</li>
};

