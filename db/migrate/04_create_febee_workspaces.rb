class CreateFebeeWorkspaces < ActiveRecord::Migration
  def self.up
    create_table :febee_workspaces do |t|
      t.column :febee_project_configuration_id, :int
      t.column :path, :string
      t.column :last_git_fetch, :timestamp
    end
  end

  def self.down
    drop_table :febee_workspaces
  end
end
