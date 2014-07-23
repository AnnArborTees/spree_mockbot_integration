// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/backend/all.js'

$(function () {
  $('#reset-mockbot-settings-button').click(function () {
    $.ajax({
      url: "/admin/mockbot/settings",
      type: 'POST',
      dataType: 'json'
    })
      .done(function (response) {
        $('#mockbot-settings-form > .form-group > input').each(function () {
          var fieldName = $(this).attr('name');
          fieldName = fieldName.replace('mockbot_settings[', '');
          fieldName = fieldName.replace(']', '');

          $(this).attr('value', response[fieldName]);
        });
      })

      .fail(function (jqXHR, textStatus) {
        alert("Couldn't reach server.");
      });

    return false;
  });
});