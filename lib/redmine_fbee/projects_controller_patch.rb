require_dependency 'projects_controller'

module RedmineFbee
  module ProjectsControllerPatch
    module InstanceMethods
      include FbeeProjectConfigurationsHelper
      def settings_with_fbee
        settings_without_fbee
        load_project_and_project_configuration
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
      
      receiver.class_eval do
        alias_method_chain :settings, :fbee
      end
    end
  end
end