var w = 1020,
    h = 600,
    r = 6,
    z = d3.scale.category20c();


//Cribbed from https://github.com/ktym/d3sparql/blob/master/d3sparql.js
var d3xquery = {
  version: "d3xquery.js version 2015-11-19",
  debug: false  // set to true for showing debug information
}

//Call xquery with parameters
//NOTE: enhancements will include a collections parameter. 
d3xquery.query = function(endpoint, rel, event, uri, callback) {
  var url = endpoint + '?rel=' + rel + '&event=' + event + '&uri=' + uri
  var mime = "application/json"
  d3.xhr(url, mime, function(data) {
    var json = data.responseText
    callback(JSON.parse(json))
  })
};


d3xquery.forcegraph = function(json, config) {

    var edges = [];
    
    //Relationship is mapped to type in edges. 
    //NOTE: may want to change that when I have a better grip on d3js 
    json.links.forEach(function(e) {
        var sourceNode = json.nodes.filter(function(n) {
            return n.id === e.source;
        })[0],
            targetNode = json.nodes.filter(function(n) {
                return n.id === e.target;
            })[0];
    
        edges.push({
            source: sourceNode,
            target: targetNode,
            type: e.relationship
        });
    });

  //Debugging  
    json.links.forEach(function(link, index, list) {
       if (typeof json.nodes[link.source] === 'undefined') {
           console.log('undefined source', link);
        }
        if (typeof json.nodes[link.target] === 'undefined') {
            console.log('undefined target', link);
        }
    });
    
    //set up svg container
    var svg = d3.select("#graph").append("svg:svg")
        //responsive SVG needs these 2 attributes and no width and height attr
        .attr("preserveAspectRatio", "xMinYMin meet")
        .attr("viewBox","0 0 " + w + " " + h)
        //class to make it responsive
        .classed("svg-content-responsive", true); 
        // .attr("width", w)
        // .attr("height", h);
      //.append("svg:g")
      //  .attr("transform", "translate(" + w / 4 + "," + h / 3 + ")");
      
    //Add rectangle to sv     
    svg.append("svg:rect")
        .attr("width", w)
        .attr("height", h)
        .style("stroke", "#000")
        .style("fill","#fff");

    
    //Set force graph variables
    var force = d3.layout.force()
        .gravity(0.05)
        .charge(-300)
        .linkDistance(50)
        //.size([w *= 2 / 3, h *= 2 / 3]);
        .size([w, h]);
    
   //Initialize graph     
   force
      .nodes(json.nodes)
      .links(edges)
      .on("tick", tick)
      .start();
      
    var link = svg.selectAll(".link")
        .data(force.links())
      .enter().append("svg:line")
        .attr("class", function (d) {
            return "link " + d.type;
        })
        .style("stroke", function(d) { return z(d.type); })
        .style("stroke-width", '1pt');
    
    //NOT working
    link.append("svg:text")
        .attr({'class':'linkLabels',
               'id':function(d,i){return 'linkLabels'+i},
               'dx':80,
               'dy':0,
               'font-size':10,
               'fill':'#aaa'})
        .text(function(d) { return d.type; });
        
  
    var node = svg.selectAll(".node")
        .data(force.nodes())
      .enter().append("svg:g")
        .call(force.drag);
    
    node.append("svg:circle")
        .attr("r", 8)
        .attr("r", function(d) { return (d.weight * .5) + 6 })
        .attr("class", "node")
        .style("fill", function(d) { return z(d.type); })
        .style("stroke", function(d) { return d3.rgb(z(d.type)).darker(); })
        //Expand circle on mouseover
        .on("mouseover", function(d){
                    d3.select(this).attr("r", function(d) { return (d.weight * .75) + 10 });
           })
            //Return to normal size        
        .on("mouseout", function(d){
                    d3.select(this).attr("r", function(d) { return (d.weight * .5) + 6 });
            });
    
    node.append("svg:text")
        .attr("x", 12)
        .attr("dy", ".35em")
        .text(function(d) { return d.name; });
        
    //Connecting linked nodes on click
    node.on("click", fade(.2));

    var linkedByIndex = {};
    
    edges.forEach(function(d) {
      linkedByIndex[d.source.index + "," + d.target.index] = 1;
    });
    
    function isConnected(a, b) {
        return linkedByIndex[a.index + "," + b.index] || linkedByIndex[b.index + "," + a.index] || a.index == b.index;
    }
    
    function neighboring(a, b) {
      return edges.some(function(d) {
        return (d.source === a && d.target === b)
            || (d.source === b && d.target === a) ? d.type : d.type ;
      });
    }
    
    //Highlight related
    function fade(opacity) {
        return function(d) {
            node.style("stroke-opacity", function(o) {
                thisOpacity = isConnected(d, o) ? 1 : opacity;
                this.setAttribute('fill-opacity', thisOpacity);
                return thisOpacity;
                return isConnected(d,o);
            });

            link.style("stroke-opacity", opacity).style("stroke-opacity", function(o) {
                return o.source === d || o.target === d ? 1 : opacity;
            });
            
            getNodeInfo(d.id);
            
        };
    };
    
    //Return names and descriptions
    //Trying to get relationships
    function getNodeInfo(uri){
        $.get( "get-names.xql", { id: uri} )
          .done(function( data ) {
              $( "#info-box" ).html(data);
              $( "#relationship-box" ).html(
                function(o) {
                      //return (isConnected(uri, o)) ? '<h4>Relationships</h4><p> There are links, i dont know how to get them '+ o.index + '</p>' : '<h4>Relationships</h4><p>No links.</p>';
                      return neighboring(uri, o);
                  });
              //$( "#relationship-box" ).html(
              // function(o) {
              //      return o.source === d || o.target === d ? d.source : '';
              //  });
              //$(data).appendTo( $( "#info-box" ) );
          });
    }
    

    function tick() {
      node.attr("cx", function(d) { return d.x = Math.max(15, Math.min(w - 15, d.x)); })
        .attr("cy", function(d) { return d.y = Math.max(15, Math.min(h - 15, d.y)); });

        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
        
        node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
    }

//    node.attr("cx", function(d) { return d.x = Math.max(r, Math.min(w - r, d.x)); })
//        .attr("cy", function(d) { return d.y = Math.max(r, Math.min(h - r, d.y)); });


  //Create filter based on type
    createFilter();
    // Method to create the filter, generate checkbox options on fly
    // force.links()
    //unique links: http://stackoverflow.com/questions/28572015/how-to-select-unique-values-in-d3-js-from-data
    //use d3.map to get unique values from data
    function createFilter() {
              d3.select(".filterContainer").selectAll("div")
                .data(d3.map(edges, function(d){return d.type;}).keys())
                .enter()  
                .append("div")
                .attr("class", "checkbox-container")
                .append("label")
                .each(function (d) {
                       d3.select(this).append("svg:rect")
                            .attr("width", 10)
                            .attr("height", 10)
                            .style("fill", function(d) { 
                                  var color = z(d.type);
                                  return color;
                              })
                      // create checkbox for each data
                      d3.select(this).append("input")
                        .attr("type", "checkbox")
                        .attr("id", function (d) {
                            return "chk_" + d;
                         })
                         .attr("class", function (d) {
                            return "chk " + d;
                         })
                        .attr("checked", true)
                        .on("click", function (d, i) {
                            // register on click event
                            var lVisibility = this.checked ? "visible" : "hidden";
                            filterGraph(d, lVisibility);
                         })
                      d3.select(this).append("span")
                          .text(function (d) {
                              return d;
                          });
              });
              $("#sidebar").show();
              console.log(d3.map(force.links, function(d){return d.type;}).keys());
          }
          
    function filterGraph(aType, aVisibility) {
            // change the visibility of the connection path
            link.style("visibility", function (o) {
                var lOriginalVisibility = $(this).css("visibility");
                return o.type === aType ? aVisibility : lOriginalVisibility;
            });
    
            // change the visibility of the node
            // if all the links with that node are invisibile, the node should also be invisible
            // otherwise if any link related to that node is visibile, the node should be visible
            node.style("visibility", function (o, i) {
                var lHideNode = true;
                link.each(function (d, i) {
                    if (d.source === o || d.target === o) {
                        if ($(this).css("visibility") === "visible") {
                            lHideNode = false;
                            // we need show the text for this circle
                            d3.select(d3.selectAll(".nodeText")[0][i]).style("visibility", "visible");
                            return "visible";
                        }
                    }
                });
                
                if (lHideNode) {
                    // we need hide the text for this circle 
                    d3.select(d3.selectAll(".nodeText")[0][i]).style("visibility", "hidden");
                    return "hidden";
                }
            });
        }
        


}   