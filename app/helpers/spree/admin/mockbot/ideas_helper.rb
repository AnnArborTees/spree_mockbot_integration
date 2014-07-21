module Spree::Admin::Mockbot::IdeasHelper

  # TODO MONDAY
  # Get these guys up and functioning in the index.html.erb for spree_mockbot_integration.
  # After that, add the search!

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
    if idea.status == 'Ready to Publish'
      link_to 'Publish', "/admin/mockbot/ideas/publish/please-implement-me"
    elsif idea.status == 'Published'
      link_to 'Republish', "/admin/mockbot/ideas/publish/please-implement-me"
    else
      "Can't publish yet"
    end
  end
end
