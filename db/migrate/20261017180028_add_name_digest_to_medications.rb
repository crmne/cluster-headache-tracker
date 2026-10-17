# Medication names are encrypted, so the database can no longer compare them.
# A keyed digest of the lowercased name takes over the unique index on
# lower(name) and the lookups by name.
class AddNameDigestToMedications < ActiveRecord::Migration[8.1]
  class Medication < ActiveRecord::Base
    self.table_name = "medications"
  end

  def up
    add_column :medications, :name_digest, :string

    # Names are still plain text here: encryption only starts with this release.
    Medication.reset_column_information
    Medication.find_each do |medication|
      medication.update_columns name_digest: ::Medication.digest_name(medication.name)
    end

    change_column_null :medications, :name_digest, false
    remove_index :medications, name: "index_medications_on_user_id_and_lower_name"
    add_index :medications, %i[ user_id name_digest ], unique: true
  end

  def down
    remove_index :medications, %i[ user_id name_digest ]
    add_index :medications, "user_id, lower(name)", unique: true, name: "index_medications_on_user_id_and_lower_name"
    remove_column :medications, :name_digest
  end
end
