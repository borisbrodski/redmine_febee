class AddReviewCommitCountToFeatureBranches < ActiveRecord::Migration
  def self.up
    change_table :feature_branches do |t|
      t.integer :review_commit_count
    end
  end
  
  def self.down
    change_table :feature_branches do |t|
      t.remove :review_commit_count
    end
  end
end
