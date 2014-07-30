Spree::Product.class_eval do
  has_many :updates, as: :updatable
end