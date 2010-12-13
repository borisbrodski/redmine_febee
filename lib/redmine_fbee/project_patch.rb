require_dependency 'project'

module RedmineFbee
  # Patches Redmine's Project dynamically. Adds a relationship
  # FbeeProjectConfiguration +belongs_to+ to Project
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
  
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        has_one :fbee_project_configuration
      end
    end
    
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end