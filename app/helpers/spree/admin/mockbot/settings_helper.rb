module Spree::Admin::Mockbot::SettingsHelper
  def settings_label(name, display)
    label_tag("mockbot_settings[#{name}]", display)
  end

  def settings_input(name)
    text_field_tag("mockbot_settings[#{name}]", @settings.send(name), class: 'form-control')
  end

  def label_and_input_for(name, label_display)
    settings_label(name, label_display) + settings_input(name)
  end
end