require 'grit'
require 'tempfile'

class GitRepository
  attr :local_path

  include ExecHelper

  def initialize(project_configuration)
    @project_configuration = project_configuration
    begin
      @grit_repository = Grit::Repo.new(project_configuration.workspace)
    rescue
    end
  end

  def repository_initialized?
    @repository_initialized ||= @grit_repository.heads.count > 0 if @grit_repository
  end

  def access_git for_initialization = false
    prepare_keys
    fetch_from_server unless for_initialization
    yield self
  ensure
    remove_keys
  end

  def reinitialize_repository
    local_path = @project_configuration.workspace
    # Try to prevent 'rm -rf /'
    unless !local_path.blank? && local_path =~ /[^\\\/]/
      raise "Removing '#{local_path}' is too dangerous."
    end
    puts "Removing #{File.join local_path, '*'}"
    FileUtils.rm_rf Dir.glob(File.join(local_path, '*'))
    FileUtils.rm_rf Dir.glob(File.join(local_path, '.*')).select {|f| f !~ /\/..?$/}
    initialize_repository
  end
  
  def initialize_repository
    url = @project_configuration.git_url
    run_with_git "clone #{url} .", "Cloning project repository from #{url}"
    nil
  rescue ExecError => e
     e.message
  end

  def base_branches
    @base_branches ||= branches.select{|name| name !~ /\//}
  end
  
  def branches
    return @branches if @branches

    # TODO use grit here
    output = run_with_git "branch -r", "Retrieving remote branches"
    @branches = (output.split "\n").select{|line| line.gsub! /\s+origin\//, ''; line !~ /->/ }
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

private

  def fetch_from_server
    run_with_git "fetch origin +refs/heads/*:refs/remotes/origin/*", "Fetching from the git repository"
  end
  
  def generate_random_filename prefix, postfix, dir
    for i in 1..100
      name = "#{prefix}#{rand(10000000)}#{rand(10000000)}#{postfix}"
      file_name = File.join(dir, name)
      return File.expand_path(file_name) unless File.exists?(file_name)
    end
    raise "Can't pick a unique temporary file name"
  end

  def prepare_keys
    private_key = @project_configuration.private_key
    return if private_key.blank?
    @private_key_full_path = generate_random_filename('pk', '', "#{Rails.root}/tmp")
    puts "@private_key_full_path=#{@private_key_full_path}"
    private_key_file = File.new(@private_key_full_path, 'w')
    private_key_file.write private_key
    private_key_file.close
    
    @git_ssh_full_path = generate_random_filename('git_ssh', '.cmd', "#{Rails.root}/tmp")
    puts "@git_ssh_full_path=#{@git_ssh_full_path}"
    git_ssh_file = File.new(@git_ssh_full_path, 'w')
    git_ssh_file.write single_qoute(Setting.plugin_redmine_febee['cmd_ssh'])
    git_ssh_file.write " -i #{single_qoute(@private_key_full_path)} $@"
    git_ssh_file.close
    
    run_with_bash "chmod 0600 #{single_qoute(@private_key_full_path)} ; " +
                  "chmod 0777 #{single_qoute(@git_ssh_full_path)}",
                  "Set permissions on the temporary key and the git_ssh files"
  end

  def remove_keys
    File.delete @private_key_full_path unless @private_key_full_path.blank?
    File.delete @git_ssh_full_path unless @git_ssh_full_path.blank?
  end


  def run_with_git(cmd, description)
    git_ssh = "GIT_SSH=#{single_qoute(@git_ssh_full_path)} " unless @git_ssh_full_path.blank?
    run_with_bash "#{git_ssh}#{single_qoute(Setting.plugin_redmine_febee['cmd_git'])} #{cmd}", description
  end

  def run_with_bash(cmd, description)
    bash_c_cmd = "cd #{single_qoute(@project_configuration.workspace)} && #{cmd}"
    bash_cmd = "#{single_qoute(Setting.plugin_redmine_febee['cmd_bash'])} -c #{single_qoute(bash_c_cmd)}"
    run_cmd bash_cmd, description
  end
  
  def single_qoute cmd
    "'#{cmd.gsub("'", "'\\\\''")}'"
  end
end