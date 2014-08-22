Spree::Product.class_eval do
  has_many :updates, as: :updatable, dependent: :destroy

  def log_update(info)
    return unless id
    updates << Spree::Update.new(info: info)
    info
  end
end