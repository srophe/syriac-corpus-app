xquery version "3.0";

module namespace d3="http://syriaca.org//d3";

(:~
 : Testing D3js for data visualizations
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
(<script>
<![CDATA[
$(document).ready(function(){ /// jQuery function that starts JavaScript when DOM loads
        /// Data in JSON format. In this type of JSON variables before ":" are called keys, after semicolon are called values.
           var data = [{"date":"2015-01-20","total":3},{"date":"2015-01-21","total":8},{"date":"2015-01-22","total":2},{"date":"2015-01-23","total":10},{"date":"2015-01-24","total":3},{"date":"2015-01-25","total":20},{"date":"2015-01-26","total":12}];
        
        var margin = {top: 40, right: 40, bottom: 40, left:40}, //// The concept of margins is best explained here: http://bl.ocks.org/mbostock/3019563
            width = 600, ///width and height of the SVG image 
            height = 500;
        
        var x = d3.time.scale() /// D3 has multiple scales (I will discuss scales later in this lesson). This is a time scale. this scale is used to draw the x-axis.Pay attention to how we specify domain and rangeBound for this scale. rangeBound you can find only in time scales
            .domain([new Date(data[0].date), d3.time.day.offset(new Date(data[data.length - 1].date), 1)])/// domain is an array that contains the beginning of the range and the end of the range. new Date(XXX) in Javascript means a date.
            /// data[0].date is a reference to the first value in our JSON array.
            .rangeRound([0, width - margin.left - margin.right]); /// the rangeBound extends from 0 to the maximum width (width-margins!!!).
        
        
        var y = d3.scale.linear() /// This is a linear scale. This scale is used to draw the y-axis. 
            .domain([0, d3.max(data, function(d) { return d.total;})]) /// Similarly to the time scale,this scale has a domain as well. 
            ///The domain start at 0 and continues to the largest number in JSON array. d3.max is a function in D3 that allows to determine the largest number in the array.
            //// function(d) { return d.total;} -- this function extracts all values with the key total from the data.
            .range([height - margin.top - margin.bottom, 0]); /// this scale has a range, not a rangeBound. The range extends from the max height to 0
        
        var xAxis = d3.svg.axis() /// Specification for xAxis
            .scale(x) // link to x scale
            .orient('bottom') /// position
            .ticks(d3.time.days, 1) /// Change this to .ticks(d3.time.days, 3). Observe what happens. 
            //The ticks method will split your domain in (more or less) n convenient, 
            //human-readable values, and return an array of these values. This is especially useful to label axes. 
            //Passing these values to the scale allows them to position ticks nicely on an axis.
            .tickFormat(d3.time.format('%m-%d-%Y')) /// d3.time.format('%m-%d-%Y') is a function in d3.js You can read more about it here: https://github.com/mbostock/d3/wiki/Time-Formatting
            /// try to change this format to day of the year as a decimal number [001,366].
            .tickSize(0) /// tickSize is specified in pixels. tickSize and tickPadding are similar to CSS.
            ///tickPadding pushes elements in, away from the edges of the SVG, to prevent them from being clipped. 
            .tickPadding(8);
        
        var yAxis = d3.svg.axis() /// Specification for yAxis
            .scale(y) // link to y scale
            .orient('left')
            .tickPadding(8);
            
        var xAxis1 = d3.svg.axis() //// this is an additional xAxis scale for gridlines
            .scale(x) // link to x scale
            .orient('bottom'); /// important to keep orientation for the gridlines.
        
        var yAxis1 = d3.svg.axis()
            .scale(y)
            .orient('left');
        
        var svg = d3.select('#bar-demo').append('svg') /// append an SVG chart to the div with id #bar-demo
            .attr('class', 'chart') /// Attach a CSS class (see styles above). This class can have any oher name
            .attr('width', width) // a reference to width which was specified earlier in this file
            .attr('height', height) // a reference to height which was specified earlier in this file
          .append('g') /// here we specify that the chart will conatin a group of elements
            .attr('transform', 'translate(' + margin.left + ', ' + margin.top + ')'); /// the position of the chart should start not at 0,0,but at 40,40.
        
        
        
        svg.append("g") /// append a group of grid lines         
                .attr("class", "grid") /// append CSS class "grid". See styles above
                .attr("transform", "translate(0," + (height - margin.bottom - margin.top)+")") /// the grid should not start at 0,0. Where shoud it start,can you compute?
                .call(xAxis1 /// a reference to xAxis1
                .ticks(d3.time.hours, 12) /// close this line. See what happens. You will have ticks for each day
                .tickSize(-(height-margin.top-margin.bottom), 0, 0) /// please note that these ticks are larger
                .tickFormat("")
        );            
        svg.append('g') /// Append xAxis
            .attr('class', 'axis') /// A reference to a CSS class
            .attr('transform', 'translate(0, ' + (height - margin.top - margin.bottom) + ')') ///position
            .call(xAxis); //A reference to xAxis
            
        svg.append('g') /// Append yAxis
          .attr('class', 'axis') ///A reference to a CSS class
          .call(yAxis); //Reference to yAxis
        
        svg.append("g") /// Append yAxis        
                .attr("class", "grid") /// A reference to a CSS class
                .call(yAxis1 //A reference to yAxis1
                .ticks(20) /// try to close this line, see what happens. By default, you will have gridlines for each bar
                .tickSize(-(width-margin.left-margin.right), 0, 0)
                 .tickFormat("")
                );
        
        svg.selectAll('.chart') /// Here we select the CSS class chart. (Remember we assigned it earlier?)
            .data(data) //Bind the chart to data.
            .enter()
            .append('rect') // add SVG rectangles
            .attr('class', 'bar') // Add a CSS class
            .attr('x', function(d) { return x(new Date(d.date)); }) /// A reference to valriables on x scale
            .attr('y', function(d) { return height - margin.top - margin.bottom - (height - margin.top - margin.bottom - y(d.total)) })
            /// Specification how tall bars should be in pixels
            .attr('width', 25) // Width of bar charts
            .attr('height', function(d) { return height - margin.top - margin.bottom - y(d.total) }); //height of bars in pixel
        
         svg.selectAll(".rect") /// select all DOM elements that have rect class
             .data(data) /// bind to data
           .enter().append("svg:text") //append text labels with values
             .attr("x", function(d) { return x(new Date(d.date)); }) // position
             .attr("y", function(d) { return y(d.total); })/// position of the text label
             .attr("dx", "0.5em") // padding-right
             .attr("dy", "1.50em") // padding-left
             .attr("text-anchor", "left") // text-align: left
             .text(function(d) { return d.total }); /// Text	
             
        //// Adding graph Title     
        svg.append("text")
                .attr("x", (width / 2))             
                .attr("y", 0 - (margin.top / 2))
                .attr("text-anchor", "middle")  
                .style("font-size", "20px") 
                .text("Totals in January");		
        	
        });
]]>
</script>,
 <div id="bar-demo"  style="position: relative; top: 3px; left: 20px;"></div>)
};

declare function d3:relationships2($data as node()*){
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
