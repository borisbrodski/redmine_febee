class AddUpdateIntervalToFebeeProjectConfiguration < ActiveRecord::Migration
  def self.up
    change_table :febee_project_configurations do |t|
      t.integer :update_interval
    end
  end
  
  def self.down
    change_table :febee_project_configurations do |t|
      t.remove :update_interval
    end
  end
end
