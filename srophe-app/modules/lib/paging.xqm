xquery version "3.0";
(:~
 : Paging module for reuse by search and browse pages 
 :)
 
module namespace page="http://syriaca.org/page";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 : Build paging menu for browsing
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options true/false
:)
declare function page:pageination($hits as node()*, $start as xs:integer?, $perpage as xs:integer?, $sort as xs:boolean){
let $perpage := if($perpage) then xs:integer($perpage) else 20
let $start := if($start) then $start else 1
let $total-result-count := count($hits)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function, strip start parameter :)
let $url-params := string-join(replace(replace(request:get-query-string(), '&amp;start=\d+', ''),'start=\d+',''),'')
let $param-string := if($url-params != '') then concat('?',$url-params,'&amp;start=') else '?start='        
let $pagination-links := 
    <div xmlns="http://www.w3.org/1999/xhtml">
        {
        if($total-result-count gt $perpage) then 
            <ul class="pagination pull-right">
                {((: Show 'Previous' for all but the 1st page of results :)
                    if ($current-page = 1) then ()
                    else <li><a href="{concat($param-string, $perpage * ($current-page - 2)) }">Prev</a></li>,
                    (: Show links to each page of results :)
                    let $max-pages-to-show := 8
                    let $padding := xs:integer(round($max-pages-to-show div 2))
                    let $start-page := 
                                  if ($current-page le ($padding + 1)) then
                                      1
                                  else $current-page - $padding
                    let $end-page := 
                                  if ($number-of-pages le ($current-page + $padding)) then
                                      $number-of-pages
                                  else $current-page + $padding - 1
                    for $page in ($start-page to $end-page)
                    let $newstart := 
                                  if($page = 1) then 1 
                                  else $perpage * ($page - 1)
                    return 
                        if ($newstart eq $start) then <li class="active"><a href="#" >{$page}</a></li>
                         else <li><a href="{concat($param-string, $newstart)}">{$page}</a></li>,
                    (: Shows 'Next' for all but the last page of results :)
                    if ($start + $perpage ge $total-result-count) then ()
                    else <li><a href="{concat($param-string, $start + $perpage)}">Next</a></li>,
                    if($sort = true()) then 'Sort options'
                    else(), 
                    <li><a href="{concat('?start=1&amp;perpage=',$total-result-count)}">All</a></li>
                    )}
            </ul>
        else 
            <ul class="pagination pull-right">
            {
                if($sort = true()) then 'Sort options'
                else()
            }
            </ul>
        }
    </div>    
return 
   if(exists(request:get-parameter-names())) then $pagination-links
   else ()
};

(:~
 : Build paging menu for search results, includes search string
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options true/false
:)
declare function page:pageination($hits as node()*, $start as xs:integer?, $perpage as xs:integer?, $sort as xs:boolean, $collection as xs:string?, $search-string as xs:string*){
let $perpage := if($perpage) then xs:integer($perpage) else 20
let $start := if($start) then $start else 1
let $total-result-count := count($hits)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function, strip start parameter :)
let $url-params := replace(request:get-query-string(), '&amp;start=\d+', '')
let $param-string := if($url-params != '') then concat('?',$url-params,'&amp;start=') else '?start='        
let $pagination-links := 
    <div class="row" xmlns="http://www.w3.org/1999/xhtml">
            <div class="col-sm-5">
                <h4 class="hit-count">Search results:</h4>
                <p class="col-md-offset-1 hit-count">{$total-result-count} matches for {$search-string}.</p>
            </div>
            <div class="col-md-7">
                {
                if($total-result-count gt $perpage) then 
                <ul class="pagination pull-right">
                    {((: Show 'Previous' for all but the 1st page of results :)
                        if ($current-page = 1) then ()
                        else <li><a href="{concat($param-string, $perpage * ($current-page - 2)) }">Prev</a></li>,
                        (: Show links to each page of results :)
                        let $max-pages-to-show := 8
                        let $padding := xs:integer(round($max-pages-to-show div 2))
                        let $start-page := 
                                      if ($current-page le ($padding + 1)) then
                                          1
                                      else $current-page - $padding
                        let $end-page := 
                                      if ($number-of-pages le ($current-page + $padding)) then
                                          $number-of-pages
                                      else $current-page + $padding - 1
                        for $page in ($start-page to $end-page)
                        let $newstart := 
                                      if($page = 1) then 1 
                                      else $perpage * ($page - 1)
                        return 
                            if ($newstart eq $start) then <li class="active"><a href="#" >{$page}</a></li>
                             else <li><a href="{concat($param-string, $newstart)}">{$page}</a></li>,
                        (: Shows 'Next' for all but the last page of results :)
                        if ($start + $perpage ge $total-result-count) then ()
                        else <li><a href="{concat($param-string, $start + $perpage)}">Next</a></li>,
                        if($sort = true()) then page:sort-options($param-string,$start, $collection)
                        else(), 
                        <li class="pull-right"><a href="search.html"><span class="glyphicon glyphicon-search"/> New</a></li>
                        )}
                </ul>
                else 
                <ul class="pagination pull-right">
                {
                    if($sort = true()) then page:sort-options($param-string, $start, $collection)
                    else()
                }
                <li class="pull-right"><a href="search.html"><span class="glyphicon glyphicon-search"/> New</a></li>
                </ul>
                }
            </div>
    </div>    
return 
   if(exists(request:get-parameter-names())) then $pagination-links
   else ()
};


(:~
 : Build sort options menu for search results, includes search string
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options true/false
:)
declare function page:sort-options($param-string as xs:string?,$start as xs:integer?, $collection as xs:string*){
<li xmlns="http://www.w3.org/1999/xhtml">
    <div class="btn-group">
        <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
            <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dropdownMenu1">
                <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat(replace($param-string,'&amp;sort=(\w+)', ''),$start,'&amp;sort=rel')}" id="rel">Relevance</a></li>
                <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat(replace($param-string,'&amp;sort=(\w+)', ''),$start,'&amp;sort=alpha')}" id="alpha">Alphabetical (Title)</a></li>
                {if($collection != 'places|geo') then
                    <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat(replace($param-string,'&amp;sort=(\w+)', ''),$start,'&amp;sort=date')}" id="date">Date</a></li>
                 else()}
            </ul>
        </div>
    </div>
</li>
};
