class FbeeProjectConfigurationsController < ApplicationController
  unloadable

  helper :fbee_project_configurations
  include FbeeProjectConfigurationsHelper
  
  include ExecHelper
  include Redmine::I18n
  
  def update
    load_project_and_project_configuration
    @fbee_project_configuration.attributes = params[:fbee_project_configuration]
    @fbee_project_configuration.save#{std_out}
    render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end

  def initialize_git_repository
    load_project_and_project_configuration

    if @initialized then
      flash.now[:error] = l :repository_already_initialized
    else
      @fbee_project_configuration.access_git(true) do |git|
        error_message = git.initialize_repository
        if error_message
          flash.now[:error] = ERB::Util::h(error_message).gsub /(\r)?\n/, '<br/>'
        else
          flash.now[:notice] = l :initialized_successfully
          @initialized = true
        end
      end
    end
    render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end

  def reinitialize_git_repository
    load_project_and_project_configuration
    unless @initialized then
      flash.now[:error] = l :repository_not_initialized 
    else
      @fbee_project_configuration.access_git true do |git|
        error_message = git.reinitialize_repository
        if error_message
          flash.now[:error] = ERB::Util::h(error_message).gsub /(\r)?\n/, '<br/>'
        else
          flash.now[:notice] = l :reinitialized_successfully
        end
      end
    end
    render(:update) {|page| page.replace_html "tab-content-fbee", :partial => 'projects/settings/redmine_fbee_project_configuration'}
  end
end
