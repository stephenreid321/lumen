(function ($) {
  $.fn.lookup = function (options) {

    var settings = {lookup_url: null, placeholder: null, qtype: null, id_param: null}

    return this.each(function () {
      if (options) {
        $.extend(settings, options);
      }

      $(this).select2({
        placeholder: options['placeholder'],
        allowClear: true,
        minimumInputLength: 1,
        width: '100%',
        ajax: {
          url: options['lookup_url'],
          dataType: 'json',
          data: function (term) {
            return {
              q: term,
              qtype: options['qtype']
            };
          },
          results: function (data) {
            return {results: data.results};
          }
        },
        initSelection: function (element, callback) {
          var id = $(element).val();
          if (id !== '') {
            var data = {};
            data[(options['id_param'] || $(element).attr('name'))] = id;
            data['qtype'] = options['qtype']
            $.get(options['lookup_url'], data, function (data) {              
              var result = data['results'].filter(function(result) {
                return result['id'] == id
              })[0]
              callback(result);
            });
          }
        }
      });

    });
  };
})(jQuery);
