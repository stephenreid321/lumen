(function ($) {
  $.fn.lookup = function (options) {

    var settings = {}

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
            $.get(options['lookup_url'], {id: id}, function (data) {
              callback(data);
            });
          }
        }
      });

    });
  };
})(jQuery);
