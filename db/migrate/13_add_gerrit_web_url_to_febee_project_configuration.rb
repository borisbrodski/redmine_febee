class AddGerritWebUrlToFebeeProjectConfiguration < ActiveRecord::Migration
  def self.up
    change_table :febee_project_configurations do |t|
      t.text :gerrit_web_url
    end
  end
  
  def self.down
    change_table :febee_project_configurations do |t|
      t.remove :gerrit_web_url
    end
  end
end
