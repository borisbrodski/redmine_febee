require 'grit'

class GitRepository

  REMOTE_NAME='origin'

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
    initialize_repository
  end
  
  def initialize_repository
    empty_non_root_directory(@workspace.path)
    url = @project_configuration.git_url
    run_with_git "clone #{single_qoute(url)} .", "Cloning project repository from #{url}"
  end

  def feature_branch_commit_ids(feature_branch, main_branch)
    main = "#{@project_configuration.main_branch_folder_path}#{main_branch}"
    feature = "#{@project_configuration.feature_branch_folder_path}#{feature_branch}"
    log = run_with_git "log --format=format:%H '#{REMOTE_NAME}/#{main}..#{REMOTE_NAME}/#{feature}'",
      "Retrieve commits ids on the feature branch"
    log.split("\n")
  end

  def main_branches
    return @main_branches if @main_branches && @remote_branches

    main_branch_folder_path = @project_configuration.main_branch_folder_path
    if main_branch_folder_path.blank?
      @main_branches = remote_branches.select{|name| name !~ /\//}
    else
      @main_branches = remote_branches.select{|name| name.start_with?(main_branch_folder_path)}.
        collect{|name| name[main_branch_folder_path.length..-1]}
    end
  end

  def feature_branches
    return @feature_branches if @feature_branches && @remote_branches

    feature_branch_folder_path = @project_configuration.feature_branch_folder_path
    if feature_branch_folder_path.blank?
      @feature_branches = remote_branches.select{|name| name !~ /\//}
    else
      @feature_branches = remote_branches.select{|name| name.start_with?(feature_branch_folder_path)}.
        collect{|name| name[feature_branch_folder_path.length..-1]}
    end
  end

  def remote_branches
    return @remote_branches if @remove_branches

    output = run_with_git("branch -r", "Retrieving remote branches")
    @remote_branches = (output.split "\n").select{|line| line.gsub! /\s+#{REMOTE_NAME}\//, ''; line !~ /->/ }
    @main_branches = nil
    @feature_branches = nil
    @remote_branches
  end

  def create_feature_branch main_branch_name, issue_id
    return nil unless main_branches.include? main_branch_name
    name = unique_feature_branch_name "issue_#{issue_id}", main_branch_name

    main_branch_folder_path = @project_configuration.main_branch_folder_path
    feature_branch_folder_path = @project_configuration.feature_branch_folder_path
    run_with_git "push #{REMOTE_NAME} refs/remotes/#{REMOTE_NAME}/#{main_branch_folder_path}#{main_branch_name}:refs/heads/#{feature_branch_folder_path}#{name}",
                 "Create feature branch '#{name}' based on '#{main_branch_name}'"
    @remote_branches = nil
    name
  end

  def fetch_from_server
    @remote_branches = nil
    run_with_git "fetch --prune #{REMOTE_NAME} +refs/heads/*:refs/remotes/#{REMOTE_NAME}/*", "Fetching from the git repository"
  end

private

  def unique_feature_branch_name(issue_name, main_branch_name)
    counter = 0
    begin
      name = issue_name.dup
      name << "_#{main_branch_name}" unless main_branch_name == "master"
      name << "_#{counter}" unless counter == 0
      counter += 1
    end while feature_branches.include? name
    name
  end

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
