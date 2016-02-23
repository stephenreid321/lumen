
webshims.polyfill();

$(function () {

  function timeago() {
    $("abbr.timeago").timeago()
  }

  function wysify() {
    $('textarea.wysiwyg').not('textarea.wysified').each(function () {
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
          ['insert', ['picture', 'link', 'video']],
        ],
        height: 200,
        codemirror: {
          theme: 'monokai'
        }
      });
      $('.note-image-input').parent().hide();
      $(textarea).prop('required', false);
      $(summernote).code($(textarea).val());
      $(textarea).addClass('wysified').hide();
      $(textarea.form).submit(function () {
        $(textarea).val($(summernote).code());
      });
    });
  }

  function containedPagination() {
    $('.pagination a').click(function (e) {
      if ($(this).attr('href') != '#') {
        $(this).closest('.page-container').load($(this).attr('href'), function () {
          scroll(0, 0);
        });
      }
      return false;
    });
  }

  function placeholdersOnly() {
    $('form.placeholders-only label[for]').each(function () {
      var input = $(this).next().children().first()
      if (!$(input).attr('placeholder'))
        $(input).attr('placeholder', $.trim($(this).text()))
      $(this).hide()
    });
  }

  function opengraph() {
    $('.opengraph textarea, .opengraph input[type=text]').typing({
      stop: function (event, $elem) {
        var urlPattern = /(http|ftp|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:\/~+#-]*[\w@?^=%&amp;\/~+#-])?/
        var m = $($elem).val().match(urlPattern);
        var resource = $($elem).attr('name').split('[')[0]
        var displayContainer = $($elem).closest('.form-group').next()
        var fieldContainer = displayContainer.next()
        if (m) {
          $(displayContainer).html('<i style="position: absolute; top: 0; right: 5px;" class="fa fa-spinner fa-spin"></i>')
          $(displayContainer).load('/opengraph?url=' + encodeURIComponent(m[0]), function () {
            var r = $('<a style="position: absolute; top: 0; right: 5px;" class="edit" title="Remove link" href="javascript:;"><i class="fa fa-times"></i></a>');
            r.click(function () {
              $(displayContainer).html('')
              $(fieldContainer).html('')
            });
            r.prependTo(displayContainer);
          });
          $(fieldContainer).html('')
          $.getJSON('/opengraph.json?url=' + encodeURIComponent(m[0]), function (data) {
            $.each(['title', 'url', 'description', 'player', 'picture'], function (i, x) {
              if (data[x])
                $(fieldContainer).append('<input type="hidden" name="' + resource + '[link_' + x + ']" value="' + data[x] + '">')
            });
          })
        }
      },
      delay: 400
    });
  }

  function modalTrigger() {
    $('a.modal-trigger').click(function () {
      $('#modal .modal-content').load(this.href, function () {
        $('#modal').modal('show');
      });
      return false;
    });
  }

  $(document).ajaxComplete(function () {
    wysify();
    containedPagination();
    placeholdersOnly();
    opengraph();
    modalTrigger();
    timeago();
  });
  wysify();
  placeholdersOnly();
  opengraph();
  modalTrigger();
  timeago();

  $('form').submit(function () {
    $('button[type=submit]', this).attr('disabled', 'disabled').html('Submitting...');
  });

  $('a[data-toggle="tab"]').on('show.bs.tab', function (e) {
    $('.fc-event').popover('destroy');
  });

  Array.prototype.unique = function () {
    var unique = [];
    for (var i = 0; i < this.length; i++) {
      if (unique.indexOf(this[i]) == -1) {
        unique.push(this[i]);
      }
    }
    return unique;
  };

  $(document).on('click', 'a[data-confirm]', function (e) {
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      e.preventDefault();
      e.stopped = true;
    }
  });

  $(document).on('change', 'input[type=file]', function (e) {
    if (typeof FileReader !== "undefined") {
      var file = this.files[0]
      if (file) {
        var size = file.size;
        if (size > 5 * 1024 * 1024) {
          alert("That file exceeds the maximum attachment size of 5MB. Upload it elsewhere and include a link to it instead.")
          $(this).val('');
        }
      }
    }
  });

  $('.geopicker').geopicker({
    width: '100%',
    getLatLng: function (container) {
      var lat = $('input[name$="[lat]"]', container).val()
      var lng = $('input[name$="[lng]"]', container).val()
      if (lat.length && lng.length)
        return new google.maps.LatLng(lat, lng)
    },
    set: function (container, latLng) {
      $('input[name$="[lat]"]', container).val(latLng.lat());
      $('input[name$="[lng]"]', container).val(latLng.lng());
    }
  });

  $(document).on('click', 'a.popup', function (e) {
    window.open(this.href, null, 'scrollbars=yes,width=600,height=600,left=150,top=150').focus();
    return false;
  });

  $('#results-form').submit(function (e) {
    e.preventDefault();
    $('#filter-spin').show();
    $('#results').load($(this).attr('action') + '?' + $(this).serialize(), function () {
      $('#filter-spin').hide();
    });
  });

  $('#results-form input[type=radio], #results-form select').change(function () {
    $(this.form).submit();
  });

  $('#results-form').submit();

  if ($('th[data-fieldname]').length > 0) {
    var params = $.deparam(location.href.split('?')[1] || '');
    $('th').hover(function () {
      $('a.odn', this).css('visibility', 'visible')
    }, function () {
      $('a.odn', this).css('visibility', 'hidden')
    });
    $('a.od').click(function () {
      params['o'] = $(this).closest('th').data('fieldname')
      params['d'] = params['d'] == 'asc' ? 'desc' : 'asc'
      location.assign(location.pathname + '?' + $.param(params));
    });
  }

});
