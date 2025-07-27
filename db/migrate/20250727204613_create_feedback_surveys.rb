class CreateFeedbackSurveys < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_surveys do |t|
      t.string :usage_duration
      t.text :versions
      t.text :most_useful_features
      t.text :additional_features
      t.integer :ease_of_use
      t.boolean :shared_with_doctor
      t.text :impact
      t.text :change_suggestion
      t.integer :recommendation_likelihood
      t.text :promotion_suggestions
      t.string :mobile_interest
      t.string :user_agent
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
