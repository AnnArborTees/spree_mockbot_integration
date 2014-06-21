module Spree::Admin::MockbotIdeasHelper

  def mockbot_idea_remote_url(idea)
    return "#{Figaro.env['mockbot_home'].chomp('/')}/ideas/#{idea.sku.strip}"
  end

  def links_to_product_from_idea(idea)
    Spree::Product.where(spree_variants: {sku: idea.sku}).joins(:master).map!{ |x|
      link_to x.sku, edit_admin_product_path(x)
    }.join(',').html_safe
  end

end
