$(function() {

  $("select.chosen").chosen({allow_single_deselect: true});

  $('textarea.wysiwyg').wysihtml5({html: true});

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

  Array.prototype.unique = function() {
    var unique = [];
    for (var i = 0; i < this.length; i++) {
      if (unique.indexOf(this[i]) == -1) {
        unique.push(this[i]);
      }
    }
    return unique;
  };

});
