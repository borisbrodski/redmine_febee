
class FebeeMergeController < ApplicationController
  unloadable

  helper FebeeMergeHelper
  include FebeeMergeHelper
  before_filter :init

  def new
    commit_msgs = [@feature_branch.commit_msg, '']
    @febee_project_configuration.access_git do |git|
      @feature_branch.check_against_git_repository(git)
      @commits = git.commits(@feature_branch.commit_ids)
      unless @febee_merge
        @commits.each do |commit|
          commit_msgs << "\n"
          commit_msgs << "## Commit id: #{commit.sha}"
          commit_msgs << "## Author: #{commit.author}"
          commit_msgs << "## Date: #{commit.date.strftime '%d.%m.%Y&nbsp;%H:%M:%S'}"
          (commit.message.split "\n").each do |line|
            commit_msgs << "# #{line}"
          end
        end
        @febee_merge = FebeeMerge.create(:commit_msg => commit_msgs.join("\n"))
      end
    end

    unless @feature_branch.status == FeatureBranch::STATUS_PENDING
      error :feature_branch_not_in_status_pending, :name =>@feature_branch.name
      return
    end

    if @feature_branch.commits_count < 1
      error :no_commits_to_merge, :name =>@feature_branch.name
      return
    end
  end

  def create
    @febee_merge = FebeeMerge.create(params[:febee_merge])
    @feature_branch.commit_msg = @febee_merge.commit_msg_without_comments
    redirect_to_issue
    if @feature_branch.save
      flash[:notice] = ll "merged_flash_#{params[:merge_method]}", :count => 0, :name => @feature_branch.based_on_name # TODO fix number of commits
    else
      flash[:error] = "Error occured"
    end
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
