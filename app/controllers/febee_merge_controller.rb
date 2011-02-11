
class FebeeMergeController < ApplicationController
  unloadable

  before_filter :init
  helper FebeeMergeHelper
  include FebeeMergeHelper

  def new
    
  end

  def create
    redirect_to_issue
  end

private
  def init
    @move_to_gerrit = (params[:merge_method] == 'move_to_gerrit')

    @feature_branch = FeatureBranch.find(params[:feature_branch_id])
    @issue = @feature_branch.issue

    unless User.current.allowed_to?(params[:merge_method].to_sym, @issue.project)
      error "user_not_allowed_to_#{params[:merge_method]}"
      return
    end

    @febee_project_configuration = @issue.project.febee_project_configuration
    @febee_project_configuration.access_git do |git|
      @feature_branch.check_against_git_repository(git)
    end

    @febee_merge = FebeeMerge.create(:commit_msg => "Hello World")

    unless @feature_branch.status == FeatureBranch::STATUS_PENDING
      error :feature_branch_not_in_status_pending, :name =>@feature_branch.name
      return
    end

  end

private
  def error(message, options = {})
    flash[:error] = ll(message, options)
    redirect_to_issue
  end
  def redirect_to_issue
    redirect_to :controller => 'issues', :action => 'show', :id => @issue.id
  end
end
