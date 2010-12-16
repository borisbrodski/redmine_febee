require_dependency 'projects_helper'

module RedmineFbee
  module ProjectsHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
  
      base.class_eval do
        alias_method_chain :project_settings_tabs, :fbee
      end
    end
    
    module InstanceMethods
      # Adds a FBEE tab to the project settings page
      def project_settings_tabs_with_fbee
        tabs = project_settings_tabs_without_fbee
        if User.current.allowed_to? :manage_fbee_project_configuration, @project then
          tabs << { :name => 'fbee',
                    :action => :manage_fbee_project_configuration,
                    :partial => 'projects/settings/redmine_fbee_project_configuration',
                    :label => :fbee_project_configuration
          }
        end
        tabs
      end
    end
  end
end
