xquery version "3.0";

module namespace d3="http://syriaca.org//d3";

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace json="http://www.json.org";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:
    NOTES on display,
    headline should be person names perhaps Events: PersName
    credit syriaca.org?
    xqjson:serialize-json
:)
declare function d3:relationships($data as node()*){
<script>
<![CDATA[
//Constants for the SVG
var width = 800,
height = 500;

//Set up the colour scale
var color = d3.scale.category20();

//Set up the force layout
var force = d3.layout.force().charge(-120).linkDistance(30).size([width, height]);

//Append a SVG to the body of the html page. Assign this SVG as an object to svg
var svg = d3.select("#viz").append("svg").attr("width", width).attr("height", height);

//Read the data from the mis element
var mis = ']]>{d3:data($data)}<![CDATA[';
graph = mis;

//Creates the graph data structure out of the json data
force.nodes(graph.nodes).links(graph.links).start();

//Create all the line svgs but without locations yet
var link = svg.selectAll(".link").data(graph.links).enter().append("line").attr("class", "link").style("stroke-width", function (d) {
    return Math.sqrt(d.value);
});

//Do the same with the circles for the nodes - no
var node = svg.selectAll(".node").data(graph.nodes).enter().append("circle").attr("class", "node").attr("r", 8).style("fill", function (d) {
    return color(d.group);
}).call(force.drag);


//Now we are giving the SVGs co-ordinates - the force layout is generating the co-ordinates which this code is using to update the attributes of the SVG elements
force.on("tick", function () {
    link.attr("x1", function (d) {
        return d.source.x;
    }).attr("y1", function (d) {
        return d.source.y;
    }).attr("x2", function (d) {
        return d.target.x;
    }).attr("y2", function (d) {
        return d.target.y;
    });
    
    node.attr("cx", function (d) {
        return d.x;
    }).attr("cy", function (d) {
        return d.y;
    });
});
]]>
</script>
};

declare function d3:data($data as node()*){
xqjson:serialize-json(
<json type="object">
    {(d3:nodes($data),d3:links($data))}
</json>)
};

declare function d3:nodes($data as node()*){
<pair name="nodes"  type="array">
{
for $rec in collection('/db/apps/srophe/data/persons/tei')//tei:idno[@type='URI'] = 'http://syriaca.org/person/13'
let $uri := tokenize(string($rec),'/')[last()]
let $group := 
    if(contains($rec,'person')) then '1'
    else if(contains($rec,'place')) then '2'
    else if(contains($rec,'bibl')) then '3'
    else 1
return
        <item type="object">
            <pair name="name"  type="string">{$uri}</pair>
            <pair name="group"  type="number">{$group}</pair>
        </item>

 }   
</pair>

};

declare function d3:links($data as node()*){
<pair name="links"  type="array">
    {
    for $rec in collection('/db/apps/srophe/data/spear/tei')//tei:div[descendant::*[@ref = 'http://syriaca.org/person/13']]
    let $rec-id := string($rec/@xml:id)
    let $uri := tokenize(string($rec),'/')[last()]
    let $group := 
        if(contains($rec,'person')) then '1'
        else if(contains($rec,'place')) then '2'
        else if(contains($rec,'bibl')) then '3'
        else 1
    return
        <item type="object">
            <pair name="source"  type="string">{position() - 1}</pair>
            <pair name="target"  type="string">{$group}</pair>
        </item>
    }
</pair>    
};
