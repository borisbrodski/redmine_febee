require_dependency 'projects_helper'

module RedmineFebee
  module ProjectsHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
  
      base.class_eval do
        alias_method_chain :project_settings_tabs, :febee
      end
    end
    
    module InstanceMethods
      # Adds a FeBEE tab to the project settings page
      def project_settings_tabs_with_febee
        tabs = project_settings_tabs_without_febee
        if User.current.allowed_to? :manage_febee_project_configuration, @project then
          tabs << { :name => 'febee',
                    :action => :manage_febee_project_configuration,
                    :partial => 'projects/settings/redmine_febee_project_configuration',
                    :label => :febee_project_configuration
          }
        end
        tabs
      end
    end
  end
end
