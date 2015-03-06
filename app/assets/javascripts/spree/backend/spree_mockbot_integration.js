// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/backend/all.js'

$(document).ready(function () {

  if ($('.progress-dots').length) {
    var dotCount = 0;
    setInterval(function () {
      dotCount += 1;
      if (dotCount > 5)
        dotCount = 1;
      var dotStr = "";
      for (var i = 1; i <= dotCount; i++) {
        dotStr += '.';
      }

      $('.progress-dots').text(dotStr);
    }, 300);

    $('#start-publish').click(function() {
      $('.publish-step.active > .progress-dots').removeClass('hidden-dots');
      return true;
    });
  }

  $('a').click(function() {
    if ($(this).prop('disabled'))
      return false;
    else
      return true;
  });

});

var MockbotPublish = {
  clearActives: function() {
    $('.publish-step.active').each(function() {
      var $this = $(this);
      $this.removeClass('active');
      $this.addClass('complete');

      $icon = $this.find('i');
      $icon.removeClass('icon-play');
      $icon.addClass('icon-check');
    });
  },

  updatePublisher: function(url) {
    $.ajax({
      url: url,
      type: 'PUT',
      dataType: 'script'
    })
      .fail(function (jqXHR, textStatus) {
        if (textStatus == 'error') { return; }
        alert(textStatus);
      });
  }
}
