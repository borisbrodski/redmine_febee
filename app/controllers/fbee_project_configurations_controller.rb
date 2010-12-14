class FbeeProjectConfigurationsController < ApplicationController
  unloadable

  helper :fbee_project_configurations
  include FbeeProjectConfigurationsHelper
  
  include ExecHelper
  
  def update
    load_project_and_project_configuration
    @fbee_project_configuration.attributes = params[:fbee_project_configuration]
    @fbee_project_configuration.save
    render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end

  def initialize_git_repository
    load_project_and_project_configuration

    #ExecHelper::
    puts '------------------'
    puts run_cmd1 "ls -la", "Running test program"
    puts '------------------'

    flash.now[:notice] = 'Initialized successfully'
      render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end

  def reinitialize_git_repository
    load_project_and_project_configuration
    flash.now[:notice] = 'Re-initialized successfully'
      render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end
end
