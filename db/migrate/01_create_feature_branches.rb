class CreateFeatureBranches < ActiveRecord::Migration
  def self.up
    create_table :feature_branches do |t|
      t.column :issue_id, :int
      t.column :name, :string
      t.column :based_on_name, :string
      t.column :status, :string
      t.column :created_user_id, :int
      t.column :last_merge_try_user_id, :int
      t.column :last_to_gerrit_user_id, :int
      t.column :change_id, :string
      t.column :last_base_sha1, :string
    end
  end

  def self.down
    drop_table :feature_branches
  end
end
