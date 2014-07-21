module Spree
  class MockbotSettings
    def self.respond_to?(*args)
      super or MockbotSetting.instance.respond_to?(*args)
    end

    def self.method_missing(name, *args, &block)
      if MockbotSetting.instance.respond_to?(name)
        MockbotSetting.instance.send(name,*args,&block)
      else
        MockbotSetting.send(name,*args,&block)
      end
    end
  end
end