class MakeFeedbackSurveysUserIdIndexUnique < ActiveRecord::Migration[8.1]
  def change
    remove_index :feedback_surveys, :user_id
    add_index :feedback_surveys, :user_id, unique: true
  end
end
