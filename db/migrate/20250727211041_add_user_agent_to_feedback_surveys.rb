class AddUserAgentToFeedbackSurveys < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:feedback_surveys, :user_agent)
      add_column :feedback_surveys, :user_agent, :string
    end
  end
end
