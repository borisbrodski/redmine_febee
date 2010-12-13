class FeatureBranch < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  belongs_to :last_merge_try_user, :class_name => 'User', :foreign_key => 'last_merge_try_user_id'
  belongs_to :last_to_gerrit_user, :class_name => 'User', :foreign_key => 'last_to_gerrit_user_id'
  
end

