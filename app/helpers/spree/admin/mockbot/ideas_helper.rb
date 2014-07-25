module Spree::Admin::Mockbot::IdeasHelper

  def mockbot_idea_remote_url(idea)
    return "#{Figaro.env['mockbot_home'].chomp('/')}/ideas/#{idea.sku.strip}"
  end

  def links_to_product_from_idea(idea)
    s = idea.associated_spree_products.map{ |x|
      link_to x.sku, spree.edit_admin_product_path(x)
    }.join(',').html_safe
    s.empty? ? "No matching products" : s
  end

  def import_idea_to_product_link(idea)
    publish_path = spree.admin_mockbot_idea_publish_path(idea.sku)
    if idea.status == 'Ready to Publish'
      button_to 'Publish', publish_path
    elsif idea.status == 'Published'
      button_to 'Republish', publish_path
    else
      button_to "Can't publish yet", publish_path, disabled: 'disabled'
    end
  end
end
