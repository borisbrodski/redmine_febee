
class FebeeProjectConfiguration < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  has_one :febee_workspace
  validates_presence_of :workspace_path, :git_url, :git_user_name, :git_email_name
  validates_format_of :git_url, :with => /ssh:\/\/[^\/]+\/.*/,
                      :message => "Git url should have the format 'ssh://[username@]host[:port]/[path]"
  after_save :save_workspace
  
  def initialize *args
    super *args
    self.febee_workspace = FebeeWorkspace.new(:febee_project_configuration => self)
  end
  def save_workspace
    febee_workspace.save
  end
  
  def validate
    unless workspace_path.blank? || (File.directory? workspace_path) then
      errors.add_to_base "Not a valid workspace directory: '#{workspace_path}'" # TODO to yml
    end
    if is_gerrit && gerrit_web_url.blank?
      errors.add_to_base "Gerrit web frontend URL should be specified in order to enable reviews." # TODO to yml
    end

  end

  def access_git
   yield febee_workspace.git_repository
  end

  def workspace_initialized?
    febee_workspace.git_repository.repository_initialized? if valid?
  end

  def workspace_path
    febee_workspace.path if febee_workspace
  end

  def workspace_path=(path)
    febee_workspace.path = path
  end

  # Return '' or main branch folder name followed by the slash
  def main_branch_folder_path
    "#{main_branch_folder_name}#{'/' unless main_branch_folder_name.blank?}"
  end

  # Return '' or feature branch folder name followed by the slash
  def feature_branch_folder_path
    "#{feature_branch_folder_name}#{'/' unless feature_branch_folder_name.blank?}"
  end

  # Return '' or closed feature branch folder name followed by the slash
  def closed_feature_branch_folder_path
    "#{closed_feature_branch_folder_name}#{'/' unless closed_feature_branch_folder_name.blank?}"
  end
end
