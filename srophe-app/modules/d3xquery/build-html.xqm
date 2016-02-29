xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

(: Build HTML for force Graph, will add additional graphs later on. :)
declare function local:html(){
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
            <title>Assignment 2: Relationships</title>
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no"/>
            <!--[if lt IE 9]>
                <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
            <![endif]-->
            <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
            <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
            <link rel="stylesheet" type="text/css" href="$app-root/resources/css/bootstrap.min.css" />
            <link rel="stylesheet" href="$app-root/resources/css/main.css"/>
            <link rel="stylesheet" href="$app-root/modules/d3xquery/relationships.css"/>
            <link rel="stylesheet" href="$app-root/modules/d3xquery/pygment_trac.css"/>
            <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js" ></script>
            <script type='text/javascript' src="http://d3js.org/d3.v3.js"></script>
            <script type='text/javascript' src="https://cdnjs.cloudflare.com/ajax/libs/d3-legend/1.8.0/d3-legend.js"></script>
            <script src="$app-root/modules/d3xquery/force-d3js.js"></script>
            <script>
            <![CDATA[ 
                function exec(){
                    var endpoint = d3.select("#endpoint").property("value")
                    var rel = d3.select("#rel").property("value")
                    var event = d3.select("#event").property("value")
                    var uri = d3.select("#uri").property("value")
                    var reltype = d3.select("#reltype").property("value")
                    d3xquery.query(endpoint, rel, event, uri, reltype, render)   
                }
                

                
                function render(json) {
                    var config = {
                      "charge": -500,
                      "distance": 50,
                      "width": 1000,
                      "height": 750,
                      "selector": "#grpah"
                    }
                    d3xquery.forcegraph(json, config)
                  }
                  
                $(document).ready(function () { 
                    toggleFields(); //call this first so we start out with the correct visibility depending on the selected form values
                    $("#rel").change(function () {
                        toggleFields();
                    });
                });
               function toggleFields() {
                   if ($("#rel").val() === "event")
                       $("#eventGrp").show();
                   else
                       $("#eventGrp").hide();
                       
                   if ($("#rel").val() === "relationship")
                       $("#relGrp").show();                       
                   else
                       $("#relGrp").hide();
               }
            ]]>
            </script>

    </head>
    <body class="white">
        <div class="row">
            <div class="col-md-9">
                <div id="graph-container">   
                    <div id="graph"></div>
                </div>
            </div>
            <div class="col-md-3">
                <div id="sidebar">
                    <div>
                      <form class="form-horizontal" id="query">
                        <h4>Select graph to explore 
                        <a class="togglelink pull-right btn-link" 
                        data-toggle="collapse" data-target="#showForm" 
                        data-text-swap="show options">hide options 
                        <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"></span>
                        </a>
                        </h4>
                        <div id="showForm" class="collapse in">
                        <div class="form-group">
                            <label for="rel" class="col-sm-2 control-label">Type</label>
                            <div class="col-sm-10">
                                <select id="rel" class="form-control">
                                    <option value="all">-- Select Graph --</option>
                                    <option value="event">Event</option>
                                    <option value="relationship">Relationship</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group" id="eventGrp" >
                            <label for="event" class="col-sm-2 control-label">Events </label>
                            <div class="col-sm-10">
                                <select id="event" class="form-control">
                                    <option value="all">All Events</option>
                                    {local:get-events()}
                                </select>
                            </div>
                        </div>
                        <div class="form-group" id="relGrp" >
                            <label for="reltype" class="col-sm-2 control-label">Relationships </label>
                            <div class="col-sm-10">
                                <select id="reltype" class="form-control">
                                    <option value="all">All Relationships</option>
                                    {local:get-rels()}
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="uri" class="col-sm-2 control-label">Record </label>
                            <div class="col-sm-10">
                                <input type="text" class="form-control" id="uri" placeholder="Example: http://syriaca.org/person/51"/>
                            </div>
                        </div>
                        <input id="endpoint" class="span5" value="get-relationships.xql" type="hidden"/>
                        <button type="button" class="btn btn-primary" onclick="exec()">Query</button> &#160;
                        <input class="btn btn-warning" type="reset" value="Reset"/>
                        </div>
                    </form>
                    </div>
                    <hr style="margin-top:1em;"/>
                    <div class="item-group">
                        <h4 class="item-label">Filter
                        <a class="togglelink pull-right btn-link" 
                        data-toggle="collapse" data-target="#filterContainer" 
                        data-text-swap="show options">hide options 
                        <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"></span>
                        </a>
                        </h4>
                        <div id="filterContainer" class="filterContainer checkbox-interaction-group collapse in"></div>
                    </div>
                    <hr/>
                    <div id="info-box"></div>
                    <div id="relationship-box"></div>
                </div>
            </div>
        </div> 
        <script type="text/javascript" src="$app-root/resources/js/bootstrap.min.js"></script>
    </body>
</html>
};

(: Get all events for drop down menu :)
(: Eventually add collection filter :)
declare function local:get-events(){
    let $events := distinct-values(for $event in collection($global:data-root || '/spear/tei')//tei:event/@ref
                    return tokenize($event,'/')[last()])
    for $e in $events
    return 
    <option value="{$e}">{$e}</option>
};

(: Get all relationships for drop down menu :)
(: Eventually add collection filter :)
declare function local:get-rels(){
    let $rels := distinct-values(for $rel in collection($global:data-root || '/spear/tei')//tei:relation/@name
                    return replace($rel,'^(.*?):','')[last()])
    for $r in $rels
    return 
    <option value="{$r}">{$r}</option>
};
local:html()