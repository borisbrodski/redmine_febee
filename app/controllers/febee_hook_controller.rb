class FebeeHookController < ApplicationController
  unloadable
  
  skip_before_filter :check_if_login_required

  helper FebeeMergeHelper
  include FebeeMergeHelper

  def mark_as_merged
    mark_as(false)
  end
  
  def mark_as_abandoned
    mark_as(true)
  end

private
  def mark_as(abandon)
    change_id = params[:change_id]
    feature_branch = FeatureBranch.find_by_change_id(change_id)
    if feature_branch.nil?
      render :inline => "ERROR: No feature branch with change id #{change_id} was found\n"
      return
    end
    unless feature_branch.status == FeatureBranch::STATUS_PENDING
      render :inline => "ERROR: The feature branch #{feature_branch.name} of issue #{feature_branch.issue_id} not in the 'pending' status\n"      
      return
    end

    febee_project_configuration = feature_branch.issue.project.febee_project_configuration
    febee_project_configuration.access_git do |git|
      feature_branch.close_feature_branch(git, febee_project_configuration, abandon)
    end
    if feature_branch.save
      render :inline => "#{abandon ? 'Abandon' : 'Merge'} of the change id #{change_id} noted\n"
    else
      render :inline => "ERROR: Error saving changes to the feature branch object #{feature_branch.name} of issue #{feature.issue_id}\n"      
    end
  end
end