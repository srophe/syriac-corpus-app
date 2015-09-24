xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(: Find app root, borrowed from config.xqm :)
declare variable $global:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
    ;
(: Get config.xml to parse global varaibles :)
declare variable $global:get-config := doc($global:app-root || '/config.xml');

(: Establish data app root :)
declare variable $global:data-root := 
    let $app-root := $global:get-config//app-root/text()  
    let $data-root := concat($global:get-config//data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;

(: Establish main navigation for app, used in templates for absolute links :)
declare variable $global:nav-base := 
    if($global:get-config//nav-base/text() != '') then $global:get-config//nav-base/text()
    else concat('/exist/apps/',$global:app-root);

(: Base URI used in tei:idno :)
declare variable $global:base-uri := $global:get-config//base_uri/text();

declare variable $global:app-title := $global:get-config//title/text();

declare variable $global:app-url := $global:get-config//url/text();

(: Name of logo, not currently used dynamically :)
declare variable $global:app-logo := $global:get-config//logo/text();

(: Map rendering, google or leaflet :)
declare variable $global:app-map-option := $global:get-config//maps/option[@selected='true']/text();

(:
 : Addapted from https://github.com/eXistSolutions/hsg-shell
 : Recurse through menu output absolute urls based on config.xml values. 
:)
declare function global:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(html:a) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element(html:form) return
                let $action := replace($node/@action, "\$app-root", $global:nav-base)
                return
                    <form action="{$action}">
                        {$node/@* except $node/@action, global:fix-links($node/node())}
                    </form>      
            case element() return
                element { node-name($node) } {
                    $node/@*, global:fix-links($node/node())
                }
            default return
                $node
};

declare function global:srophe-dashboard($data, $rec-head as xs:string?, $rec-text as node()?,$contrib-text as node()?,$data-text as node()?){
let $rec-num := count($data)
let $contributors := for $contrib in distinct-values(for $contributors in $data//tei:respStmt/tei:name return $contributors) return <li>{$contrib}</li>
let $contrib-num := count($contributors)
let $data-points := count($data//tei:body/descendant::text())
return
<div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
    <div class="panel panel-default">
        <div class="panel-heading" role="tab" id="dashboardOne">
            <h4 class="panel-title">
                <a role="button" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                    <i class="glyphicon glyphicon-dashboard"></i> The Syriac Gazetteer Dashboard
                </a>
            </h4>
        </div>
        <div id="collapseOne" class="panel-collapse collapse in" role="tabpanel" aria-labelledby="dashboardOne">
            <div class="panel-body dashboard">
                <div class="row" style="padding:2em;">
                    <div class="col-md-4">
                        <div class="panel panel-primary">
                            <div class="panel-heading">
                                <div class="row">
                                    <div class="col-xs-3"><i class="glyphicon glyphicon-file"></i></div>
                                    <div class="col-xs-9 text-right"><div class="huge">{$rec-num}</div><div>{$rec-head}</div></div>
                                </div>
                            </div>
                            <div class="collapse panel-body" id="recCount">
                                {$rec-text} 
                                <span><a href="browse.html"> See records <i class="glyphicon glyphicon-circle-arrow-right"></i></a></span>
                            </div>
                            <a role="button" 
                                data-toggle="collapse" 
                                href="#recCount" 
                                aria-expanded="false" 
                                aria-controls="recCount">
                                <div class="panel-footer">
                                    <span class="pull-left">View Details</span>
                                    <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                    <div class="clearfix"></div>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="panel panel-success">
                            <div class="panel-heading">
                                <div class="row">
                                    <div class="col-xs-3"><i class="glyphicon glyphicon-user"></i></div>
                                    <div class="col-xs-9 text-right"><div class="huge">{$contrib-num}</div><div>Contributors</div></div>
                                </div>
                            </div>
                            <div class="panel-body collapse" id="contribCount">
                                {($contrib-text,
                                <ul style="padding-left: 1em;">{$contributors}</ul>)} 
                                
                            </div>
                            <a role="button" 
                                data-toggle="collapse" 
                                href="#contribCount" 
                                aria-expanded="false" 
                                aria-controls="contribCount">
                                <div class="panel-footer">
                                    <span class="pull-left">View Details</span>
                                    <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                    <div class="clearfix"></div>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="panel panel-info">
                            <div class="panel-heading">
                                <div class="row">
                                    <div class="col-xs-3"><i class="glyphicon glyphicon-stats"></i></div>
                                    <div class="col-xs-9 text-right"><div class="huge"> {$data-points}</div><div>Data points</div></div>
                                </div>
                            </div>
                            <div id="dataPoints" class="panel-body collapse">
                                {$data-text}  
                            </div>
                            <a role="button" 
                            data-toggle="collapse" 
                            href="#dataPoints" 
                            aria-expanded="false" 
                            aria-controls="dataPoints">
                                <div class="panel-footer">
                                    <span class="pull-left">View Details</span>
                                    <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                    <div class="clearfix"></div>
                                </div>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
};
(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
    transform:transform($nodes, doc($global:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
    </parameters>
    )
};


