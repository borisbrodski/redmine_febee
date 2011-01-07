class FebeeWorkspace < ActiveRecord::Base
  unloadable
  
  belongs_to :febee_project_configuration
  
  # Returns updated GitRepository object
  def git_repository
    @git_repository ||= GitRepository.new(febee_project_configuration)
    PerRequestCache.fetch(:update_workspace) do
      if update_interval && last_git_fetch
        return if last_git_fetch > update_interval.seconds.ago
      end
      @git_repository.fetch_from_server
    end
    @git_repository
  end
end
