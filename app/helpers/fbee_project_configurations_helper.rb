module FbeeProjectConfigurationsHelper
  def load_project_and_project_configuration
    @project = Project.find(params[:id])
    @fbee_project_configuration =
            @project.fbee_project_configuration ||
            FbeeProjectConfiguration.new(:project => @project)
    @initialized = @fbee_project_configuration.workspace_initialized?
  end
end
