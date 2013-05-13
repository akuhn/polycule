var width = 940,
    height = 512;

var color = d3.scale.category20();

var force = d3.layout.force()
    .charge(-24*24)
    .linkDistance(100)
    .size([width, height]);

var svg = d3.select(".vis").append("svg")
    .attr("width", width)
    .attr("height", height);
		
svg.append('clipPath')
		.attr('id','circle32')
		.append('circle')
		.attr('r', 31.5)
		.attr('cx', 0)
		.attr('cy', 0);

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
	  .enter().append("g")
    	.call(force.drag);
			
	node.append("circle")
	    .attr("class", "node")
	    .attr("r", 32)
			.attr("cx", 0)
			.attr("cy", 0)
	    .style("fill", function(d) { return "#cdf"; });

	node.append("title")
	    .text(function(d) { return d.name; });
			
	node.append('image')
      .attr('xlink:href', function(d) { return d.picture; })
      .attr('x', -32)
      .attr('y', -32)
      .attr('width', 64)
      .attr('height', 64)
			.attr('clip-path', 'url(#circle32)');	

	force.on("tick", function() {
	  link.attr("x1", function(d) { return d.source.x; })
	      .attr("y1", function(d) { return d.source.y; })
	      .attr("x2", function(d) { return d.target.x; })
	      .attr("y2", function(d) { return d.target.y; });

	  node.attr("transform", function(d) { return "translate(" + d.x + " " + d.y + ")"; });
	});
	
});
