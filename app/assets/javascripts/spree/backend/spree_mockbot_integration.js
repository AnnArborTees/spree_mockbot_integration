// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/backend/all.js'

$(document).ready(function () {

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

});
