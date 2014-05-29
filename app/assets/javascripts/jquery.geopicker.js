(function( $ ){
  $.fn.geopicker = function(options) {  
    
    var settings = {
      width: '100%',
      height: 400,
      mapOptions: {
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false,
        scaleControl: true,
        streetViewControl: false,    
        maxZoom: 16
      },
      getLatLng: function() {},
      getZoom: function() {},
      set: function() {},
      clear: null,
      clearElement: null,
      address: null,
      guessElement: null,
      guessFailedMessage: "Sorry, we couldn't guess from that address.",
      defaultZoom: 5,
      defaultCenter: new google.maps.LatLng(53,-1),
      icon: null
    }
    
    return this.each(function() {
      if(options) { 
        $.extend(settings, options);
      }
          
      var container = this;    
      var mapCanvas = $('<div></div>').prependTo(container).width(settings.width).height(settings.height)[0];      
      var map = new google.maps.Map(mapCanvas, settings.mapOptions);          
      var marker = new google.maps.Marker({
        draggable: true,
        icon: settings.icon       
      });         
      
      google.maps.event.addListener(map, 'click', function(event) {
        placeMarker(event.latLng);
        set();
      });    
      
      google.maps.event.addListener(marker, 'dragend', function(event) {
        set();
      });    

      google.maps.event.addListener(map, 'zoom_changed', function(event) {
        if(marker.getMap())
          set();
      });          
      
      
      if(settings.clear) {
        $(settings.clearElement).click(function(e) {
          e.preventDefault();
          marker.setMap(null)
          settings.clear(container);
        });      
      }
      
      if(settings.address) {
        $(settings.guessElement).click(function(e) {
          e.preventDefault();  
          geocoder = new google.maps.Geocoder();
          geocoder.geocode( {
            'address': settings.address(container)
          }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
              var latLng = results[0].geometry.location;
              placeMarker(latLng);
              resetBounds();
              set();
            } else {
              alert(settings.guessFailedMessage);
            }
          });    
        });    
      }
      
      // initialize
      var latLng = settings.getLatLng(container);
      if(latLng) {
        placeMarker(latLng);
        var zoom = settings.getZoom(container);
        if (zoom) {
          map.setZoom(zoom);
          map.setCenter(latLng);          
        } else {
          resetBounds();
        }
      } else {      
        map.setZoom(settings.defaultZoom);
        map.setCenter(settings.defaultCenter);
      }
      
      // data
      $(container).data('geopicker', {
        mapCanvas : mapCanvas,
        map: map,
        marker: marker
      });     
          
      // helpers
      function set() {
        settings.set(container, marker.getPosition(), map.getZoom());
      }
      function resetBounds() {
        var bounds = new google.maps.LatLngBounds();
        bounds.extend(marker.getPosition());   
        map.fitBounds(bounds);           
      }      
      function placeMarker(latLng) {
        marker.setMap(map);
        marker.setPosition(latLng);
      }
    
    });
  };
})( jQuery );
