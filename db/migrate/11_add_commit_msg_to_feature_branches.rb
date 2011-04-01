class AddCommitMsgToFeatureBranches < ActiveRecord::Migration
  def self.up
    change_table :feature_branches do |t|
      t.text :commit_msg
    end
  end
  
  def self.down
    change_table :feature_branches do |t|
      t.remove :commit_msg
    end
  end
end
