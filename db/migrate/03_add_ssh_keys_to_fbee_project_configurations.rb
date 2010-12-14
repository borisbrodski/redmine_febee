class AddSshKeysToFbeeProjectConfigurations < ActiveRecord::Migration
  def self.up
    add_column :fbee_project_configurations, :is_gerrit, :boolean
    add_column :fbee_project_configurations, :private_key, :text
    add_column :fbee_project_configurations, :public_key, :text
    add_column :fbee_project_configurations, :git_user_name, :string
    add_column :fbee_project_configurations, :git_email_name, :string
  end

  def self.down
    remove_column :fbee_project_configurations, :is_gerrit
    remove_column :fbee_project_configurations, :private_key
    remove_column :fbee_project_configurations, :public_key
    remove_column :fbee_project_configurations, :git_user_name, :string
    remove_column :fbee_project_configurations, :git_email_name, :string
  end
end
