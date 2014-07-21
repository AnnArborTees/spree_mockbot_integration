module Spree::Admin::Mockbot::IdeasHelper

  def mockbot_idea_remote_url(idea)
    return "#{Figaro.env['mockbot_home'].chomp('/')}/ideas/#{idea.sku.strip}"
  end

  def links_to_product_from_idea(idea)
    s = Spree::Product.where(spree_variants: {sku: idea.sku}).joins(:master).map{ |x|
      link_to x.sku, edit_admin_product_path(x)
    }.join(',').html_safe
    s.empty? ? "No matching products" : s
  end

  def import_idea_to_product_link(idea)
    publish_path = "/admin/mockbot/ideas/publish/please-implement-me"
    if idea.status == 'Ready to Publish'
      button_to 'Publish', publish_path, class: 'btn btn-default'
    elsif idea.status == 'Published'
      button_to 'Republish', publish_path, class: 'btn btn-default'
    else
      button_to "Can't publish yet", publish_path, class: 'btn btn-default', disabled: 'disabled'
    end
  end
end
