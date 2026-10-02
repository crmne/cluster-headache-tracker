class Users::ReviewPromptsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.review_prompted
    head :no_content
  end
end
