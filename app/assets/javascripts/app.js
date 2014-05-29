$(function() {

  $("select.chosen").chosen({allow_single_deselect: true});

  function wysify() {
    $('textarea.wysiwyg').not('textarea.wysified').each(function() {
      var textarea = this;
      var summernote = $('<div class="summernote"></div>');
      $(summernote).insertAfter(this);
      $(summernote).summernote({
        toolbar: [
          ['view', ['codeview', 'fullscreen']],
          ['style', ['style']],
          ['font', ['bold', 'italic', 'underline', 'clear']],
          ['color', ['color']],
          ['para', ['ul', 'ol', 'paragraph']],
          ['height', ['height']],
          ['table', ['table']],
          ['insert', ['link', 'picture', 'video']],
        ],
        height: 200
      });
      $(summernote).code($(textarea).val());
      $(textarea).addClass('wysified').hide();
      $(textarea.form).submit(function() {
        $(textarea).val($(summernote).code());
      });
    });
  }

  $(document).ajaxComplete(function() {
    wysify();
  });
  wysify();

  $(window).resize(function() {
    if (document.documentElement.clientWidth < 992) {
      $('.tabs-left-please').removeClass('tabs-left');
    } else {
      $('.tabs-left-please').addClass('tabs-left');
    }
  });
  $(window).resize();

  $('form').submit(function() {
    $('button[type=submit]', this).attr('disabled', 'disabled').html('Submitting...');
  });

  $('a[data-toggle="tab"]').on('show.bs.tab', function(e) {
    $('.fc-event').popover('destroy');
  });

  Array.prototype.unique = function() {
    var unique = [];
    for (var i = 0; i < this.length; i++) {
      if (unique.indexOf(this[i]) == -1) {
        unique.push(this[i]);
      }
    }
    return unique;
  };

  $(document).on('click', 'a[data-confirm]', function(e) {
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      e.preventDefault();
      e.stopped = true;
    }
  });
  
  $('.geopicker').geopicker({
    width: '100%',
    getLatLng: function(container) {
      var lat = $('input[name$="[lat]"]', container).val()
      var lng = $('input[name$="[lng]"]', container).val()
      if (lat.length && lng.length)
        return new google.maps.LatLng(lat, lng)
    },
    set: function(container, latLng) {
      $('input[name$="[lat]"]', container).val(latLng.lat());
      $('input[name$="[lng]"]', container).val(latLng.lng());
    }
  });  

});
