xquery version "3.0";
(:~
   A facet library module
   
   Builds facets from nodes passed by search or browse modules. 
   Uses group by 
   Built for use with eXistdb, if using with eXistdb be sure to define your range 
   indexes in your collectio.xconf file for best performance.

:)
 
module namespace facets="http://syriaca.org//facets";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $facets:limit {request:get-parameter('limit', 5) cast as xs:integer};
declare variable $facets:fq {request:get-parameter('fq', '') cast as xs:string};

(:~
 : Creates the xpath string to be passed to browse or search function
 : Assumes tei namespace
:)
declare function facets:facet-filter() as xs:string?{
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
 : Build facets menu from nodes passed by search or browse module
 : @param $facets nodes to facet on
 : @param $facets:limit number of facets per catagory to display, defaults to 5
:)
declare function facets:facets($facets as node()*) as element(){
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
            let $cat := node-name($facet-group[1])
            return
            <div class="category">
                <div>
                    <h4>{$cat}</h4>
                        {
                            if($facets:limit) then 
                                for $facet-list at $l in subsequence(facets:build-facet($facet-group,string($cat)),1,$facets:limit)
                                return $facet-list
                            else facets:build-facet($facet-group,string($cat))   
                        }
                </div>
            </div>
            
    }
</div>
};

(:~
 : Build facet parameters for passing to URL
:)
declare function facets:url-params() as xs:string?{
    string-join(for $param in request:get-parameter-names()
                return 
                    if($param = 'fq') then ()
                    else if($param != '' and $param != ' ') then concat('&amp;',$param, '=',normalize-space(request:get-parameter($param, '')))
                    else (),'')                    
};

(:~
 : Display selected facets and button to remove from results set
:)
declare function facets:selected-facet-display() as node()*{
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
            <span class="label label-info" title="{$title}">{$title} 
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
declare function facets:build-facet($nodes, $category) as node()*{
    for $facet in $nodes
    group by $facet-grp := $facet
    order by count($facet) descending
    return  
        let $facet-val := $facet[1]
        let $facet-query := concat('fq-',$category,':',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        let $uri := string($facet-val/@ref)
        return 
        <li><a href="?{$new-fq}{facets:url-params()}">{string($facet-val)}</a> ({count($facet)})</li>
};
