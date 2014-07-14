class Spree::Admin::MockbotIdeasController < Spree::Admin::BaseController

  def index
    params[:page] = 1 unless !params[:page].nil?
    ideas = Mockbot::Idea.all(params: { page: params[:page], per_page: params[:per_page]})
    @ideas = Kaminari::PaginatableArray.new( ideas,{
        :limit => ideas.http_response['Pagination-Limit'].to_i,
        :offset => ideas.http_response['Pagination-Offset'].to_i,
        :total_count => ideas.http_response['Pagination-TotalEntries'].to_i
      }
    )
  end

  def show
    @idea = Mockbot::Idea.find(params[:id])
  end

  def publish
    @idea = Mockbot::Idea.find(params[:id])
  end

end
