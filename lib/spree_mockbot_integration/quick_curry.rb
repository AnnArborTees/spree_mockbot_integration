module SpreeMockbotIntegration
  module QuickCurry
    def curry(method_name, *arity)
      method(method_name).to_proc.curry(*arity)
    end
  end
end