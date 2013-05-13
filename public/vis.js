var width = 940,
    height = 512;

var color = d3.scale.category20();

var force = d3.layout.force()
    .charge(-360)
    .linkDistance(100)
    .size([width, height]);

var svg = d3.select(".vis").append("svg")
    .attr("width", width)
    .attr("height", height);

d3.json('/vis/data.json',function(graph) {

	force
	    .nodes(graph.nodes)
	    .links(graph.links)
	    .start();

	var link = svg.selectAll(".link")
	    .data(graph.links)
	  .enter().append("line")
	    .attr("class", "link");

	var node = svg.selectAll(".node")
	    .data(graph.nodes)
	  .enter().append("circle")
	    .attr("class", "node")
	    .attr("r", 32)
	    .style("fill", function(d) { return "#cdf"; })
	    .call(force.drag);

	node.append("title")
	    .text(function(d) { return d.name; });

	force.on("tick", function() {
	  link.attr("x1", function(d) { return d.source.x; })
	      .attr("y1", function(d) { return d.source.y; })
	      .attr("x2", function(d) { return d.target.x; })
	      .attr("y2", function(d) { return d.target.y; });

	  node.attr("cx", function(d) { return d.x; })
	      .attr("cy", function(d) { return d.y; });
	});
	
});
