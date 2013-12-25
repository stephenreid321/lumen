$(function() {

  $("select.chosen").chosen({allow_single_deselect: true});

  $(window).resize(function() {
    if (document.documentElement.clientWidth < 992) {
      $('.tabs-left-please').removeClass('tabs-left');
    } else {
      $('.tabs-left-please').addClass('tabs-left');
    }
  });
  $(window).resize();

});
