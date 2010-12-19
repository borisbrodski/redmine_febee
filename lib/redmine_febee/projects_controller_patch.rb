require_dependency 'projects_controller'

module RedmineFebee
  module ProjectsControllerPatch
    module InstanceMethods
      include FebeeProjectConfigurationsHelper
      def settings_with_febee
        settings_without_febee
        load_project_and_project_configuration
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
      
      receiver.class_eval do
        alias_method_chain :settings, :febee
      end
    end
  end
end