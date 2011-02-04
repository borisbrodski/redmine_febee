class FeatureBranch < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  belongs_to :last_merge_try_user, :class_name => 'User', :foreign_key => 'last_merge_try_user_id'
  belongs_to :last_to_gerrit_user, :class_name => 'User', :foreign_key => 'last_to_gerrit_user_id'
  belongs_to :created_user,        :class_name => 'User', :foreign_key => 'created_user_id'

  attr_reader :commits_count
  attr_reader :branch_problems

  # Status
  STATUS_ENUM = [:pending, :merged, :abandoned]
  STATUS_PENDING = STATUS_ENUM.find_index(:pending)
  STATUS_MERGED = STATUS_ENUM.find_index(:merged)
  STATUS_ABANDONED = STATUS_ENUM.find_index(:abandoned)

  def prepare_create
    self.status = STATUS_PENDING
    self.created_user = User.current
  end

  def checkout_cmd
    pc = issue.project.febee_project_configuration
    "git checkout '#{pc.feature_branch_folder_path}#{name}'"
  end

  def self.check_against_git_repository(feature_branches, git_repository)
    feature_branches.each {|feature_branch| feature_branch.check_against_git_repository(git_repository)}
  end

  def check_against_git_repository(git_repository)
    @branch_problems ||= []
    feature_branch_names = git_repository.feature_branches

    unless git_repository.main_branches.include? based_on_name
      @branch_problems <<= (l :main_branch_doesnt_exists) + ": #{based_on_name}"
    end
    problem_found = false
    if [STATUS_MERGED, STATUS_ABANDONED].include? status
      unless git_repository.closed_feature_branches.include? name
        @branch_problems <<= l :closed_feature_branch_not_found
      end
    else
      if git_repository.feature_branches.include? name
        @commits_count = git_repository.feature_branch_commit_ids(name, based_on_name).count
      else
        @branch_problems <<= l :feature_branch_not_found
      end
    end
  end

  def status_text
    l "feature_branch_status.#{STATUS_ENUM[status].to_s}"
  end

  def status_text_tooltip
    l "feature_branch_status_tooltip.#{STATUS_ENUM[status].to_s}"
  end

  def can_move_to_gerrit?(project)
    is_ok_and_pending_with_commits? && User.current.allowed_to?(:move_to_gerrit, project)
  end

  def can_try_to_merge?(project)
    is_ok_and_pending_with_commits? && User.current.allowed_to?(:try_to_merge, project)
  end

private
  def is_ok_and_pending_with_commits?
    STATUS_ENUM[status] == :pending &&
      branch_problems.empty? &&
      commits_count &&
      commits_count > 0
  end
end

