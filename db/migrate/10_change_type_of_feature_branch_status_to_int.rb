class ChangeTypeOfFeatureBranchStatusToInt < ActiveRecord::Migration
  def self.up
    change_table :feature_branches do |t|
      t.remove :status
      t.integer :status
    end
    FeatureBranch.update_all :status => 0
  end

  def self.down
    change_table :feature_branches do |t|
      t.remove :status
      t.string :status
    end
    FeatureBranch.update_all :status => '0'
  end
end

