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
          @project.febee_project_configuration.access_git do |git|
            @main_branch_names = git.main_branches
          end unless @main_branch_names
        end
        if User.current.allowed_to? :view_feature_branches, @project
          @feature_branches = FeatureBranch.find_all_by_issue_id(params[:id])
        end
      end

      def febee_edit
        if params[:create_feature_branch] then
          schedule_git_task do |git|
            base_branch_name = params[:base_branch_name]
            if @base_branches.include? base_branch_name
              new_branch_name = git.create_feature_branch base_branch_name, params[:id]
              
              create_feature_branch new_branch_name, base_branch_name, 'xxx TODO'
              flash[:notice] = "Feature branch created: #{new_branch_name}"
            else
              flash[:error] = "Base branch not found #{base_branch_name}"
            end
          end
          execute_git_tasks
          redirect_to :action => :show
        end
      end
    end

    def create_feature_branch new_branch_name, base_branch_name, last_base_sha1
      feature_branch = FeatureBranch.new(:issue_id => params[:id],
                                         :name => new_branch_name,
                                         :based_on_name => base_branch_name,
                                         :last_base_sha1 => last_base_sha1)
      feature_branch.prepare_create
      feature_branch.save
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
