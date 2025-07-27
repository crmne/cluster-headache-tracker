class AddUserAgentToFeedbackSurveys < ActiveRecord::Migration[8.0]
  def change
    add_column :feedback_surveys, :user_agent, :string
  end
end
