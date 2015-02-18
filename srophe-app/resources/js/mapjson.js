    var terrain = L.tileLayer(
            'http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', 
            {attribution: "ISAW, 2012"});
            
            /* Not added by default, only through user control action */
     var streets = L.tileLayer(
            'http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', 
            {attribution: "ISAW, 2012"});
            
     var imperium = L.tileLayer(
            'http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
            attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC',
            maxZoom: 11 });

    var building = new L.LayerGroup();	
    var church = new L.LayerGroup();
    var diocese = new L.LayerGroup();
    var fortification = new L.LayerGroup();	
    var island = new L.LayerGroup();	
    var madrasa = new L.LayerGroup();	
    var monastery = new L.LayerGroup();
    var mosque = new L.LayerGroup();
    var mountain = new L.LayerGroup();
    var openWater = new L.LayerGroup();
    var parish = new L.LayerGroup();	
    var province = new L.LayerGroup();
    var quarter = new L.LayerGroup();
    var region = new L.LayerGroup();
    var river = new L.LayerGroup();	
    var settlement = new L.LayerGroup();
    var state = new L.LayerGroup();
    var synagogue = new L.LayerGroup();
    var temple = new L.LayerGroup();
    var unknown = new L.LayerGroup();
    $.getJSON('/exist/apps/srophe/modules/geojson.xql',function(data){
          var geojson = L.geoJson(data, {
            onEachFeature: function (feature, layer){
            var type = feature.properties.placeType;
            var popupContent = "<a href='" + feature.properties.uri + "'>" +
            feature.properties.name + " - " + feature.properties.placeType + "</a>";
            layer.bindPopup(popupContent);
            if(type == 'building') {
                layer.addTo(building);    
            }
            if(type == 'church') {
                layer.addTo(church);    
            }
            if(type == 'diocese') {
                layer.addTo(diocese);    
            }
            if(type == 'fortification') {
                layer.addTo(fortification);    
            }
            if(type == 'island') {
                layer.addTo(island);    
            }
            if(type == 'madrasa') {
                layer.addTo(madrasa);    
            }
            if(type == 'monastery') {
                layer.addTo(monastery);    
            }
            if(type == 'mosque') {
                layer.addTo(mosque);    
            }
            if(type == 'mountain') {
                layer.addTo(mountain);    
            }
            if(type == 'openWater') {
                layer.addTo(openWater);    
            }
            if(type == 'parish') {
                layer.addTo(parish);    
            }
            if(type == 'province') {
                layer.addTo(province);    
            }
            if(type == 'quarter') {
                layer.addTo(quarter);    
            }
            if(type == 'region') {
                layer.addTo(region);    
            }
            if(type == 'river') {
                layer.addTo(river);    
            }
            if(type == 'settlement') {
                layer.addTo(settlement);    
            }
            if(type == 'state') {
                layer.addTo(state);    
            }
            if(type == 'synagogue') {
                layer.addTo(synagogue);    
            }                     
            if(type == 'temple') {
                layer.addTo(temple);    
            }
            if(type == 'unknown') {
                layer.addTo(unknown);    
            }
            }
         }) 
         
        var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 4});

       	var baseLayers = {
       			"Terrain (default)": terrain,
                "Streets": streets,
                "Imperium": imperium
       		};
       
       	var overlays = {
       	        "All" : geojson,
       			"building" : building, 	
                "church" : church, 
                "diocese" : diocese,
                "fortification" : fortification, 	
                "island" : island, 	
                "madrasa" : madrasa, 	
                "monastery" : monastery,
                "mosque" : mosque, 
                "mountain" : mountain, 
                "open water" : openWater,
                "parish" : parish, 	
                "province" : province, 
                "quarter" : quarter,
                "region" : region,
                "river" : river, 	
                "settlement" : settlement, 
                "state" : state,
                "synagogue" : synagogue,
                "temple" : temple, 
                "unknown" : unknown
       		};
       	L.control.layers(baseLayers,overlays).addTo(map);
       	terrain.addTo(map);
        geojson.addTo(map);
        /* Add two column display for type controls*/
        $('.leaflet-control-layers-list').css({"-moz-column-count":"2"});
        $('.leaflet-control-layers-list').css({"-moz-column-gap":"10px"});
        $('.leaflet-control-layers-list').css({"-webkit-column-count":"2"});
        $('.leaflet-control-layers-list').css({"-webkit-column-gap":"10px"});
        });
            
        //resize
            $('#map').height(function(){
                return $(window).height() * 0.7;
            });
            