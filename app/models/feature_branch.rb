class FeatureBranch < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  belongs_to :last_merge_try_user, :class_name => 'User', :foreign_key => 'last_merge_try_user_id'
  belongs_to :last_to_gerrit_user, :class_name => 'User', :foreign_key => 'last_to_gerrit_user_id'
  belongs_to :created_user,        :class_name => 'User', :foreign_key => 'created_user_id'

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
end

