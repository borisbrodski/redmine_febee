class AddCreatedOnUpdatedOnToFeatureBranches < ActiveRecord::Migration
  def self.up
    change_table :feature_branches do |t|
      t.timestamp :created_on
      t.timestamp :updated_on
    end
  end
  
  def self.down
    change_table :feature_branches do |t|
      t.remove :created_on
      t.remove :updated_on
    end
  end
end
