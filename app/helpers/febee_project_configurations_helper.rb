module FebeeProjectConfigurationsHelper
  def load_project_and_project_configuration
    @project = Project.find(params[:id])
    @febee_project_configuration =
            @project.febee_project_configuration ||
            FebeeProjectConfiguration.new(:project => @project)
    @initialized = @febee_project_configuration.workspace_initialized?
  end
end
