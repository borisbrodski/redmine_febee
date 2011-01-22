class AddBranchFolderConfigurationToFebeeProjectConfigurations < ActiveRecord::Migration
  def self.up
    change_table :febee_project_configurations do |t|
      t.string :feature_branch_folder_name
      t.string :closed_feature_branch_folder_name
      t.string :main_branch_folder_name
    end
  end
  
  def self.down
    change_table :febee_project_configurations do |t|
      t.remove :feature_branch_folder_name
      t.remove :closed_feature_branch_folder_name
      t.remove :main_branch_folder_name
    end
  end
end
