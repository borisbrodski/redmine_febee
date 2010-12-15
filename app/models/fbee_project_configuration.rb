
class FbeeProjectConfiguration < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  validates_presence_of :workspace, :git_url, :git_user_name, :git_email_name
  validates_format_of :git_url, :with => /ssh:\/\/[^:]+\/.*/,
                      :message => "Git url should have the format 'ssh://[username@]host[:port]/[path]"
  
  
  def validate
    unless workspace.blank? || (File.directory? workspace) then
      errors.add_to_base "Not a valid workspace directory: '#{workspace}'"
    end
    if public_key.blank? ^ private_key.blank?
      errors.add_to_base "Public and private keys should be both set or both unset."
    end
  end

  def git_repository
    @git_repository ||= GitRepository.new(workspace)
  end

  def initialize_repository
    git_repository.initialize_repository private_key
  end

  def reinitialize_repository
    git_repository.reinitialize_repository private_key
  end

  def do_with_private_key 
    git_repository.do_with_private_key(private_key) {yield}
  end

  def workspace_initialized?
    git_repository.repository_initialized? if valid?
  end

end
