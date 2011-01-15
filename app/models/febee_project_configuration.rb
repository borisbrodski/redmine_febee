
class FebeeProjectConfiguration < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  has_one :febee_workspace
  validates_presence_of :workspace_path, :git_url, :git_user_name, :git_email_name
  validates_format_of :git_url, :with => /ssh:\/\/[^\/]+\/.*/,
                      :message => "Git url should have the format 'ssh://[username@]host[:port]/[path]"
  
  def validate
    unless workspace_path.blank? || (File.directory? workspace_path) then
      errors.add_to_base "Not a valid workspace directory: '#{workspace_path}'"
    end
  end

  def access_git
    yield git_repository
  end

  def workspace_initialized?
    git_repository.repository_initialized? if valid?
  end

  def workspace_path
    febee_workspace.path if febee_workspace
  end

  def workspace_path=(path)
    self.febee_workspace ||= FebeeWorkspace.new
    febee_workspace.path = path
  end

private
  def git_repository
    @git_repository ||= GitRepository.new(febee_workspace)
  end
end
