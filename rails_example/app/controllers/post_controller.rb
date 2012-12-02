class PostController < ApplicationController

  def index
    id = 1
    render :text => Post.find(id).to_json
  end
end
