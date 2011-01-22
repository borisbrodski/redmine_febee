class RemovePublicKeyFromFebeeProjectConfigurations < ActiveRecord::Migration
  def self.up
    change_table :febee_project_configurations do |t|
      t.remove :public_key
    end
  end
  
  def self.down
    change_table :febee_project_configurations do |t|
      t.text :public_key
    end
  end
end
