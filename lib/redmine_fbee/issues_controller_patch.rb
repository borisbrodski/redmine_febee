require_dependency 'issues_controller'

module RedmineFbee
  module IssuesControllerPatch
    module InstanceMethods

      def show_with_fbee
        show_without_fbee
      end
      
      def update_with_fbee
        update_without_fbee
      end
      
      def edit_with_fbee
        edit_without_fbee
      end

      def fbee_load
        if User.current.allowed_to? :create_feature_branch, @project
          schedule_git_task do |git|
            @base_branches = git.base_branches
          end unless @base_branches
        end
      end

      def fbee_edit
        if params[:create_feature_branch] then
          schedule_git_task do |git|
            name = params[:create_feature_branch_name]
            if @base_branches.include? name
              git.create_feature_branch
            else
              flash[:error] = "Base branch not found #{name}"
            end
          end
          execute_git_tasks
          redirect_to :action => :show
        end
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.send :include, FbeeHelper

      receiver.class_eval do
        before_filter :fbee_load, :only => [:show, :edit, :update]
        before_filter :fbee_edit, :only => [:update, :edit]
        before_filter :execute_git_tasks, :only => [:show, :edit, :update]
        
        alias_method_chain :show, :fbee
        alias_method_chain :update, :fbee
        alias_method_chain :edit, :fbee
      end
    end
  end
end