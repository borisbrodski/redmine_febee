class RemoveWorkspaceFromFebeeProjectConfiguration < ActiveRecord::Migration
  def self.up
    change_table :febee_project_configurations do |t|
      t.remove :workspace
    end
  end
  
  def self.down
    change_table :febee_project_configurations do |t|
      t.string :workspace
    end
  end
end
