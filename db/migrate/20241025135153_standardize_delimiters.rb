class StandardizeDelimiters < ActiveRecord::Migration[8.0]
  def up
    # Replace " + " with ", " in medication field
    HeadacheLog.find_each do |log|
      if log.medication.present?
        updated_medication = log.medication.gsub(" + ", ", ")
        log.update_column(:medication, updated_medication)
      end
    end
  end

  def down
    # Replace ", " with " + " in medication field
    HeadacheLog.find_each do |log|
      if log.medication.present?
        original_medication = log.medication.gsub(", ", " + ")
        log.update_column(:medication, original_medication)
      end
    end
  end
end
