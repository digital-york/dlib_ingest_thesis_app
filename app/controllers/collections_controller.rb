class CollectionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @collections_list = login
  end
end