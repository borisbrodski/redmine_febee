class FebeeWorkspace < ActiveRecord::Base
  unloadable
  
  belongs_to :febee_project_configuration
  
  # Returns updated GitRepository object
  def git_repository
    @git_repository ||= GitRepository.new(self)
    PerRequestCache.fetch(:update_workspace) do
      if !update_interval || !last_git_fetch ||
        last_git_fetch < update_interval.seconds.ago
        @git_repository.fetch_from_server
      end
    end
    @git_repository
  end
end
