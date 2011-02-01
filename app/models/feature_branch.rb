class FeatureBranch < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  belongs_to :last_merge_try_user, :class_name => 'User', :foreign_key => 'last_merge_try_user_id'
  belongs_to :last_to_gerrit_user, :class_name => 'User', :foreign_key => 'last_to_gerrit_user_id'
  belongs_to :created_user,        :class_name => 'User', :foreign_key => 'created_user_id'

  attr_reader :commits_count
  attr_reader :branch_problems

  # Status
  STATUS_PENDING = 0
  STATUS_MERGED = 1
  STATUS_ABANDONED = 2

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
end

