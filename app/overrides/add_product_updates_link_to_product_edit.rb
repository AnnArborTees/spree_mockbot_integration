Deface::Override.new(:virtual_path  => "spree/admin/shared/_product_tabs",
                     :name          => "product_updates_link",
                     :insert_bottom => "[data-hook='admin_product_tabs']",
                     :partial  => "spree/admin/shared/product_updates_link",
                     :disabled => false)
