class CreateFbeeProjectConfigurations < ActiveRecord::Migration
  def self.up
    create_table :fbee_project_configurations do |t|
      t.column :project_id, :int
      t.column :git_url, :string
      t.column :workspace, :string
    end
  end

  def self.down
    drop_table :fbee_project_configurations
  end
end
