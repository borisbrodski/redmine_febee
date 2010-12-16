require_dependency 'issues_controller'

module RedmineFbee
  module IssuesControllerPatch
    module InstanceMethods

      def show_with_fbee
        if User.current.allowed_to? :create_feature_branch, @project
          @project.fbee_project_configuration.access_git do |git|
            @base_branches = git.base_branches
          end
        end
        show_without_fbee
      end
      def update_with_fbee
        update_without_fbee
      end
      def edit_with_fbee
        @base_branches = [[:a, 1], [:b, 2]]
        edit_without_fbee
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        alias_method_chain :show, :fbee
        alias_method_chain :update, :fbee
        alias_method_chain :edit, :fbee
      end
    end
  end
end