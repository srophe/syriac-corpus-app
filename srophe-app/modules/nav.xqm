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
            <div class="container">
                    <div class="navbar-header">
                        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".navbar-collapse">
                            <span class="sr-only">Toggle navigation</span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                        </button>
                        <a class="navbar-brand" href="/geo/index.html">
                            <img src="/resources/img/icon-orange-text.png" alt="The Syriac Gazetteer"/>
                        </a>
                    </div>
                    <div class="navbar-collapse collapse">
                        <ul class="nav navbar-nav">
                                <li><a href="/geo/browse.html">index</a></li>
                                <li><a href="/geo/about.html">about</a></li>
                                <li><a href="/geo/help/index.html">help</a></li>
                                <li><a href="/geo/howtoadd.html">add new place</a></li>
                        </ul>
                        <ul class="nav navbar-nav navbar-right">
                            <li>
                                <a href="/geo/search.html">advanced search</a>
                            </li>
                        </ul>
                        <div class="col-xs-5 col-sm-3 navbar-right">
                            <form class="navbar-form navbar-right" role="search" action="/geo/search.html" method="get">
                                <div class="input-group">
                                    <input type="text" class="form-control" placeholder="Search" name="q" id="q"/>
                                        <div class="input-group-btn">
                                            <button class="btn btn-default" type="submit"><span class="glyphicon glyphicon-search"></span></button>
                                        </div>
                                </div>
                            </form>
                        </div>
                    </div><!--/.nav-collapse -->
                </div>
        else if (contains(request:get-uri(),'help/')) then 
                <div class="container">
                    <div class="navbar-header">
                        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".navbar-collapse">
                            <span class="sr-only">Toggle navigation</span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                        </button>
                        <a class="navbar-brand" href="../index.html">
                            <img src="../../resources/img/icon-orange-text.png" alt="The Syriac Gazetteer"/>
                        </a>
                    </div>
                    <div class="navbar-collapse collapse">
                        <ul class="nav navbar-nav">
                                <li><a href="../browse.html">index</a></li>
                                <li><a href="../about.html">about</a></li>
                                <li><a href="../help/index.html">help</a></li>
                                <li><a href="../howtoadd.html">add new place</a></li>
                        </ul>
                        <ul class="nav navbar-nav navbar-right">
                            <li>
                                <a href="../search.html">advanced search</a>
                            </li>
                        </ul>
                        <div class="col-xs-5 col-sm-3 navbar-right">
                            <form class="navbar-form navbar-right" role="search" action="../search.html" method="get">
                                <div class="input-group">
                                    <input type="text" class="form-control" placeholder="Search" name="q" id="q"/>
                                        <div class="input-group-btn">
                                            <button class="btn btn-default" type="submit"><span class="glyphicon glyphicon-search"></span></button>
                                        </div>
                                </div>
                            </form>
                        </div>
                    </div><!--/.nav-collapse -->
                </div>
        else
        <div class="container">
                    <div class="navbar-header">
                        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".navbar-collapse">
                            <span class="sr-only">Toggle navigation</span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                        </button>
                        <a class="navbar-brand" href="index.html">
                            <img class="img-responsive" src="../resources/img/icon-orange-text.png" alt="The Syriac Gazetteer"/>
                        </a>
                    </div>
                    <div class="navbar-collapse collapse">
                        <ul class="nav navbar-nav">
                             <li><a href="browse.html">index</a></li>
                             <li><a href="about.html">about</a></li>
                             <li><a href="help/index.html">help</a></li>
                             <li><a href="howtoadd.html">add new place</a></li>
                        </ul>
                        <ul class="nav navbar-nav navbar-right">
                            <li><a href="search.html">advanced search</a></li>
                        </ul>
                        <div class="col-xs-5 col-sm-3 navbar-right">
                            <form class="navbar-form navbar-right" role="search" action="search.html" method="get">
                                <div class="input-group">
                                    <input type="text" class="form-control" placeholder="Search" name="q" id="q"/>
                                        <div class="input-group-btn">
                                            <button class="btn btn-default" type="submit"><span class="glyphicon glyphicon-search"></span></button>
                                        </div>
                                </div>
                            </form>
                        </div>
                    </div><!--/.nav-collapse -->
                </div>
};
