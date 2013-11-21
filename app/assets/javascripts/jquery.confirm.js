$(function() { 
  $("a[data-confirm]").on('click', function(e) {
    var message = $(this).data('confirm');
    if (!confirm(message)) { e.preventDefault(); e.stopped = true; }
  });
});