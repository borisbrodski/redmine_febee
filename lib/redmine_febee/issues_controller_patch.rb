require_dependency 'issues_controller'

module RedmineFebee
  module IssuesControllerPatch
    module InstanceMethods

      def show_with_febee
        show_without_febee
      end
      
      def update_with_febee
        update_without_febee
      end
      
      def edit_with_febee
        edit_without_febee
      end

      def febee_load
        if User.current.allowed_to? :create_feature_branch, @project
          schedule_git_task do |git|
            @base_branches = git.base_branches
          end unless @base_branches
        end
      end

      def febee_edit
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
      receiver.send :include, FebeeHelper

      receiver.class_eval do
        before_filter :febee_load, :only => [:show, :edit, :update]
        before_filter :febee_edit, :only => [:update, :edit]
        before_filter :execute_git_tasks, :only => [:show, :edit, :update]
        
        alias_method_chain :show, :febee
        alias_method_chain :update, :febee
        alias_method_chain :edit, :febee
      end
    end
  end
end