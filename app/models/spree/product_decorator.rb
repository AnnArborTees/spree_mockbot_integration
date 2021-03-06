Spree::Product.class_eval do
  has_many :updates, as: :updatable, dependent: :destroy

  def log_update(info)
    return unless id
    updates << Spree::Update.new(info: info)
    info
  end

  def product_permalink
    "http://#{stores.first.domains.split(' ').first}/products/#{slug}" rescue nil
  end

  alias_method :original_destroy, :destroy
  def destroy
    update_attributes slug: "deleted-#{slug}"
    original_destroy
  end
end