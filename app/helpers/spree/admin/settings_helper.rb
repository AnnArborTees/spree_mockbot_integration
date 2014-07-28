module Spree::Admin::SettingsHelper
  def settings_label(settings, name, display)
    label_tag("#{settings.settings_name}[#{name}]", display)
  end

  def settings_input(settings, name)
    value = settings.send(name)
    text_field_tag("#{settings.settings_name}[#{name}]", value, class: 'form-control', 'data-initial-value' => value)
  end

  def label_and_input_for(settings, name, label_display)
    settings_label(settings, name, label_display) + settings_input(settings, name)
  end
end