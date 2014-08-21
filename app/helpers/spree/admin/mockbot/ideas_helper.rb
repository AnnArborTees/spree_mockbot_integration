module Spree::Admin::Mockbot::IdeasHelper

  def mockbot_idea_remote_url(idea)
    return "#{Figaro.env['mockbot_homepage'].chomp('/')}/ideas/#{idea.sku.strip}"
  end

  def links_to_product_from_idea(idea)
    s = idea.associated_spree_products.map{ |x|
      link_to x.sku, spree.edit_admin_product_path(x)
    }.join(',').html_safe
    s.empty? ? "No matching products" : s
  end

  def import_idea_to_product_link(idea)
    publish_path = spree.new_admin_mockbot_idea_publisher_path(idea.sku)
    if idea.status == 'Ready to Publish'
      link_to 'Publish', publish_path, class: 'button'
    elsif idea.status == 'Published'
      link_to 'Republish', publish_path, class: 'button'
    else
      link_to "Can't publish yet", publish_path, disabled: 'disabled', class: 'button'
    end
  end

end
