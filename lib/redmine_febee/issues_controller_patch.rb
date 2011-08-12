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
        if User.current.allowed_to? :view_feature_branches, @project
          with_git do |git|
            if User.current.allowed_to? :create_feature_branch, @project
              @main_branch_names = git.main_branches
            end
            @feature_branches = FeatureBranch.find_all_by_issue_id(params[:id])
            FeatureBranch.check_against_git_repository(@feature_branches, git)
            @gerrit_web_url = @project.febee_project_configuration.gerrit_web_url_with_slash
          end
        end
      end

      def febee_edit
        return unless @main_branch_names
        if params[:create_feature_branch] then
          with_git do |git|
            main_branch_name = params[:main_branch_name]
            if @main_branch_names.include? main_branch_name
              new_branch_name = git.create_feature_branch main_branch_name, params[:id] do |name|
                FeatureBranch.find_by_name(name)
              end
              create_feature_branch new_branch_name, main_branch_name, 'xxx TODO'
              flash[:notice] = "Feature branch created: #{new_branch_name}"
            else
              flash[:error] = "Main branch not found #{main_branch_name}"
            end
          end
          redirect_to :action => :show
        end
        if params.keys.find { |k| k =~ /^try_to_merge_([0-9]+)$/ }
          puts "'try to merge' feature branch with id #{$1}"
          redirect_to :controller => :febee_merge, :action => :new,
            :issue_id => params[:id],
            :feature_branch_id => $1.to_i,
            :merge_method => 'try_to_merge'
        end
        if params.keys.find { |k| k =~ /^move_to_gerrit_([0-9]+)$/ }
          puts "'move to gerrit' feature branch with id #{$1}"
          redirect_to :controller => :febee_merge, :action => :new,
            :issue_id => params[:id],
            :feature_branch_id => $1.to_i,
            :merge_method => 'move_to_gerrit'
        end
      end
    end

    def create_feature_branch new_branch_name, base_branch_name, last_base_sha1
      feature_branch = FeatureBranch.create(:issue_id => params[:id],
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
        
        alias_method_chain :show, :febee
        alias_method_chain :update, :febee
        alias_method_chain :edit, :febee
      end
    end
  end
end
