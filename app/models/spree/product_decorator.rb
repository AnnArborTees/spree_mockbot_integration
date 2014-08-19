Spree::Product.class_eval do
  has_many :updates, as: :updatable

  def log_update(info)
    updates << Spree::Update.new(info: info)
    info
  end
end