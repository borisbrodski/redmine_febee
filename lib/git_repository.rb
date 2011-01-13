require 'grit'
#require 'tempfile'

class GitRepository
  attr :local_path

  include ExecHelper
  include FebeeUtils

  def initialize(workspace)
    @project_configuration = workspace.febee_project_configuration
    @workspace = workspace
    begin
      @grit_repository = Grit::Repo.new(@workspace.path)
    rescue StandardError => e
      logger.debug "Uninitialized git repository in workspace: '#{@workspace.path}': #{e}"
    end
    unless @project_configuration.private_key.blank?
      init_private_key 
    end
  end

  def repository_initialized?
    @repository_initialized ||= @grit_repository.heads.count > 0 if @grit_repository
  end

  def reinitialize_repository
    local_path = @workspace.path
    empty_non_root_directory local_path
    initialize_repository
  end
  
  def initialize_repository
    url = @project_configuration.git_url
    run_with_git "clone #{single_qoute(url)} .", "Cloning project repository from #{url}"
  end

  def base_branches
    @base_branches ||= branches.select{|name| name !~ /\//}
  end
  
  def remote_branches
    return @remote_branches if @remove_branches

    # TODO use grit here
    output = run_with_git "branch -r", "Retrieving remote branches"
    @remote_branches = (output.split "\n").select{|line| line.gsub! /\s+origin\//, ''; line !~ /->/ }
  end

  def create_feature_branch base_branch_name, issue_id
    return nil unless base_branches.include? base_branch_name
    name = unique_feature_branch_name "issue_#{issue_id}", base_branch_name
    create_branch name, base_branch_name
    name
  end

  def unique_feature_branch_name feature_branch_name, base_branch_name
    counter = 0
    begin
      name = "feature/#{feature_branch_name}"
      name << "_#{base_branch_name}" unless base_branch_name == 'master'
      name << "_#{counter}" unless counter == 0
      counter += 1
    end while branches.include? name
    name
  end

  def create_branch new_branch_name, base_branch_name
    run_with_git "push origin refs/remotes/origin/#{base_branch_name}:refs/heads/#{new_branch_name}",
                 "Create feature branch '#{new_branch_name}' based on '#{base_branch_name}'"
  end

  def fetch_from_server
    run_with_git "fetch --prune origin +refs/heads/*:refs/remotes/origin/*", "Fetching from the git repository"
  end

private

  def init_private_key
    @git_ssh_filename, private_key_filename, complete_filename = private_key_filenames
    with_file_lock(complete_filename) do
      unless File.exists?(@git_ssh_filename) && File.exists?(private_key_filename)
        prepare_private_key private_key_filename
      end
    end
  end
  
  def private_key_filenames
    hash_code = private_key_file_content.hash ^ (git_ssh_file_content '').hash
    name = "pc_#{@project_configuration.id}_#{hash_code}"
    ["#{name}_git_ssh.cmd", "#{name}_private_key", "#{name}_complete"].map do |file|
       File.join("#{Rails.root}/tmp", file)
    end
  end

  def prepare_private_key(private_key_filename)
    logger.debug "Generating #{@git_ssh_filename}, #{private_key_filename}"
    File.open(private_key_filename, 'w') do |file|
      file.write private_key_file_content
    end

    File.open(@git_ssh_filename, 'w') do |file|
      file.write git_ssh_file_content private_key_filename
    end
    
    run_with_bash "chmod 0600 #{single_qoute(private_key_filename)} ; " +
                  "chmod 0777 #{single_qoute(@git_ssh_filename)}",
                  "Set permissions on the temporary key and the git_ssh files"
  end

  def private_key_file_content
    @project_configuration.private_key
  end

  def git_ssh_file_content private_key_filename
    content = single_qoute(Setting.plugin_redmine_febee['cmd_ssh'])
    content += " -i #{single_qoute(private_key_filename)}"
    content += " $@"
  end

  def run_with_git(cmd, description)
    git_ssh = "GIT_SSH=#{single_qoute(@git_ssh_filename)} " unless @git_ssh_filename.blank?
    run_with_bash "#{git_ssh}#{single_qoute(Setting.plugin_redmine_febee['cmd_git'])} #{cmd}", description
  end

  def run_with_bash(cmd, description)
    bash_c_cmd = "cd #{single_qoute(@workspace.path)} && #{cmd}"
    bash_cmd = "#{single_qoute(Setting.plugin_redmine_febee['cmd_bash'])} -c #{single_qoute(bash_c_cmd)}"
    run_cmd description, bash_cmd
  end
end
