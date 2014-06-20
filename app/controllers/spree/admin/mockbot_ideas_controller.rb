class Spree::Admin::MockbotIdeasController < ApplicationController

  def index
    @ideas = MockbotIdea.all
  end

end
