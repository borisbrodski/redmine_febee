class AddSshKeysToFebeeProjectConfigurations < ActiveRecord::Migration
  def self.up
    add_column :febee_project_configurations, :is_gerrit, :boolean
    add_column :febee_project_configurations, :private_key, :text
    add_column :febee_project_configurations, :public_key, :text
    add_column :febee_project_configurations, :git_user_name, :string
    add_column :febee_project_configurations, :git_email_name, :string
  end

  def self.down
    remove_column :febee_project_configurations, :is_gerrit
    remove_column :febee_project_configurations, :private_key
    remove_column :febee_project_configurations, :public_key
    remove_column :febee_project_configurations, :git_user_name
    remove_column :febee_project_configurations, :git_email_name
  end
end
