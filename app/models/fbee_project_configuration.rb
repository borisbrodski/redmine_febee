
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

  def workspace_initialized?
    GitRepository.new(workspace).repository_initialized? if valid?
  end

end
