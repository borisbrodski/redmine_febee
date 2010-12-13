class FbeeProjectConfigurationsController < ApplicationController
  unloadable

  helper :fbee_project_configurations
  include FbeeProjectConfigurationsHelper
  
  def update
    load_project_and_project_configuration
    @fbee_project_configuration.attributes = params[:fbee_project_configuration]
    @fbee_project_configuration.save
    render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end
end
