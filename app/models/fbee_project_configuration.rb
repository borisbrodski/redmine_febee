
class FbeeProjectConfiguration < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  validates_presence_of :workspace, :git_url
  validates_format_of :git_url, :with => /ssh:\/\/[^:]+\/.*/,
                      :message => "Git url should have the format 'ssh://[username@]host[:port]/[path]"
  
  
  def validate
    unless workspace.blank? || (File.directory? workspace) then
      errors.add_to_base "Not a valid workspace directory: '#{workspace}'"
    end
  end

  def workspace_initialized?
    GitRepository.new(workspace).repository_initialized? if valid?
  end

end
