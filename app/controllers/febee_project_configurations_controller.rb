class FebeeProjectConfigurationsController < ApplicationController
  unloadable

  helper :febee_project_configurations
  include FebeeProjectConfigurationsHelper
  
  include ExecHelper
  include Redmine::I18n
  
  def update
    save_changes
    render(:update) {|page| page.replace_html "tab-content-febee", :partial => 'projects/settings/redmine_febee_project_configuration'}
  end

  def save_changes
    load_project_and_project_configuration

    @febee_project_configuration.attributes = params[:febee_project_configuration]
    @initialized = @febee_project_configuration.workspace_initialized?
    @febee_project_configuration.save
  end

  def initialize_git_repository
    if save_changes
      if @initialized then
        flash.now[:error] = l :repository_already_initialized
      else
        begin
          @febee_project_configuration.access_git do |git|
            git.initialize_repository
            flash.now[:notice] = l :initialized_successfully
            @initialized = true
          end
        rescue FebeeError => e
          flash.now[:error] = ERB::Util::h(e.message).gsub /(\r)?\n/, '<br/>'
        end
      end
    end
    render(:update) {|page| page.replace_html "tab-content-febee", :partial => 'projects/settings/redmine_febee_project_configuration'}
  end

  def reinitialize_git_repository
    if save_changes
      unless @initialized then
        flash.now[:error] = l :repository_not_initialized 
      else
        begin
          @febee_project_configuration.access_git do |git|
            git.reinitialize_repository
            flash.now[:notice] = l :reinitialized_successfully
          end
        rescue FebeeError => e
          flash.now[:error] = ERB::Util::h(e.message).gsub /(\r)?\n/, '<br/>'
        end
      end
    end
    render(:update) {|page| page.replace_html "tab-content-febee", :partial => 'projects/settings/redmine_febee_project_configuration'}
  end
end
