class FebeeWorkspace < ActiveRecord::Base
  unloadable
  
  belongs_to :febee_project_configuration
end
