xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)

module namespace nav="http://syriaca.org//nav";

import module namespace config="http://syriaca.org//config" at "config.xqm";
import module namespace place="http://syriaca.org//place" at "place.xql";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~
 : @depreciated  
 : Builds nav with relative paths for gazetteer
 :) 
declare function nav:build-nav($node as node(), $model as map(*)){
    for $active-page in tokenize(request:get-uri(), '/')[last()]
    return
        if(starts-with($active-page,'place')) then 
            (<a class="brand" href="/geo/index.html">
               <img src="/resources/img/icon-orange-text.png" style="height:45px;" alt="The Syriac Gazetteer"/></a>,
                <ul class="nav">
                    <li><a href="/geo/browse.html">index</a></li>
                    <li><a href="/geo/about.html">about</a></li>
                    <li><a href="/geo/help/index.html">help</a></li>
                </ul>,
                <p class="navbar-text nav pull-right advanced-search" style="margin-left:1em; margin-right:1em;">
                    <a class="pull-right" href="/geo/search.html">advanced search</a>
                </p>,
                <form class="navbar-search pull-right s-asearch form-search" action="/geo/search.html" method="get">
                    <div class="input-append">
                        <input class="search-query" type="text" placeholder="search" name="q"/>     
                            <button type="submit" class="btn">Go</button>
                    </div>
                </form>
                )
        else if (contains(request:get-uri(),'help/')) then 
                (<a class="brand" href="../index.html">
                       <img alt="The Syriac Gazetteer" src="../../resources/img/icon-orange-text.png" style="height:45px;"/>
                </a>,
                <ul class="nav">
                    <li><a href="../browse.html">index</a></li>
                    <li><a href="../about.html">about</a></li>
                    <li class="selected"><a href="index.html">help</a></li>
                </ul>,
                <p class="navbar-text nav pull-right advanced-search" style="margin-left:1em; margin-right:1em;">
                    <a class="pull-right" href="../search.html">advanced search</a>
                </p>,
                <form class="navbar-search pull-right s-asearch form-search" action="../search.html" method="get">
                    <div class="input-append">
                        <input class="search-query" type="text" placeholder="search the Syriac Gazetteer" name="q"/>     
                            <button type="submit" class="btn">Go</button>
                    </div>
                </form>
                )        
        else
            (<a class="brand" href="index.html">
                   <img src="../resources/img/icon-orange-text.png" style="height:45px;" alt="The Syriac Gazetteer"/></a>,
            <ul class="nav">
                <li><a href="browse.html">index</a></li>
                <li><a href="about.html">about</a></li>
                <li><a href="help/index.html">help</a></li>
            </ul>,
            <p class="navbar-text nav pull-right advanced-search" style="margin-left:1em; margin-right:1em;">
                <a class="pull-right" href="search.html">advanced search</a>
            </p>,
            <form class="navbar-search pull-right s-asearch form-search" action="search.html" method="get">
                <div class="input-append">
                    <input class="search-query" type="text" placeholder="search" name="q"/>     
                        <button type="submit" class="btn">Go</button>
                </div>
            </form>
            )
};

(:
 : Function to add gazetteer header to documentation when referring url is from gazetteer
 : Function does not currently work, would need to enable session data. 
:)
declare function nav:build-documentation-nav(){
    if(contains(request:get-uri(),'documentation/')) then
      (<a class="brand" href="/geo/index.html">
               <img src="/resources/img/icon-orange-text.png" style="height:45px;" alt="The Syriac Gazetteer"/></a>,
                <ul class="nav">
                    <li><a href="">{request:get-uri()}</a></li>
                    <li><a href="">{$active-page}</a></li>
                    <li><a href="/geo/browse.html">index</a></li>
                    <li><a href="/geo/about.html">about</a></li>
                    <li><a href="/geo/help/index.html">help</a></li>
                </ul>,
                <p class="navbar-text nav pull-right advanced-search" style="margin-left:1em; margin-right:1em;">
                    <a class="pull-right" href="/geo/search.html">advanced search</a>
                </p>,
                <form class="navbar-search pull-right s-asearch form-search" action="/geo/search.html" method="get">
                    <div class="input-append">
                        <input class="search-query" type="text" placeholder="search" name="q"/>     
                            <button type="submit" class="btn">Go</button>
                    </div>
                </form>
                ) 
    else 
        (
            <a class="brand" href="/index.html"><img alt="Syriac.org" src="/exist/apps/srophe/resources/img/syriaca-orange-text.png" style="height:45px;"/></a>,
                   <div>
                        <ul class="nav">
                            <li>
                                <a href="geo/index.html">gazetteer</a>
                            </li>
                            <li>
                                <a href="documentation/index.html">documentation</a>
                            </li>
                        </ul>
                    </div>
        )
};

declare function nav:build-nav-syr(){
(
            <a class="brand" href="/index.html"><img alt="Syriac.org" src="/exist/apps/srophe/resources/img/syriaca-orange-text.png" style="height:45px;"/></a>,
                   <div>
                        <ul class="nav">
                            <li>
                                <a href="geo/index.html">gazetteer</a>
                            </li>
                            <li>
                                <a href="documentation/index.html">documentation</a>
                            </li>
                        </ul>
                    </div>
        )
};