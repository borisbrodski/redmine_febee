require 'grit'

class GitRepository
  attr :local_path
  
  def initialize(local_path)
    @local_path = local_path
    begin
      @grit_repository = Grit::Repo.new(local_path)
    rescue
    end
  end

  def repository_initialized?
    @repository_initialized ||= @grit_repository.heads.count > 0 if @grit_repository
  end
  
  def initialize_repository
    
  end
end