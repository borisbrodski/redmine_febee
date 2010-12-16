require 'grit'
require 'tempfile'

class GitRepository
  attr :local_path

  include ExecHelper
  
  def initialize(local_path, private_key)
    @local_path = local_path
    @private_key = private_key
    begin
      @grit_repository = Grit::Repo.new(local_path)
    rescue
    end
  end

  def repository_initialized?
    @repository_initialized ||= @grit_repository.heads.count > 0 if @grit_repository
  end
  
  def access_git
    prepare_keys
    fetch_from_server
    yield self
  ensure
    remove_keys
  end

  def reinitialize_repository
    # Try to prevent 'rm -rf /'
    unless !@local_path.blank? && @local_path =~ /[^\\\/]/
      raise "Removing '#{@local_path}' is too dangerous."
    end
    puts "Removing #{File.join @local_path, '*'}"
    FileUtils.rm_rf Dir.glob(File.join(@local_path, '*'))
    FileUtils.rm_rf Dir.glob(File.join(@local_path, '.*')).select {|f| f !~ /\/..?$/}
    initialize_repository
  end
  
  def initialize_repository
    run_with_git "clone ssh://redmine@localhost:29418/SERVER .", "Cloning project repository from ssh://redmine@localhost:29418/SERVER"
    nil
  rescue ExecError => e
     e.message
  end

  def base_branches
    branches.select{|name| name !~ /\//}
  end
  
  def branches
    return @branches if @branches

    output = run_with_git "branch -r", "Retrieving remote branches"
    @branches = (output.split "\n").select{|line| line.gsub! /\s+origin\//, ''; line !~ /->|\// }
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
    return if @private_key.blank?
    @private_key_full_path = generate_random_filename('pk', '', "#{Rails.root}/tmp")
    puts "@private_key_full_path=#{@private_key_full_path}"
    private_key_file = File.new(@private_key_full_path, 'w')
    private_key_file.write @private_key
    private_key_file.close
    
    @git_ssh_full_path = generate_random_filename('git_ssh', '.cmd', "#{Rails.root}/tmp")
    puts "@git_ssh_full_path=#{@git_ssh_full_path}"
    git_ssh_file = File.new(@git_ssh_full_path, 'w')
    git_ssh_file.write single_qoute(Setting.plugin_redmine_fbee['cmd_ssh'])
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
    run_with_bash "#{git_ssh}#{single_qoute(Setting.plugin_redmine_fbee['cmd_git'])} #{cmd}", description
  end

  def run_with_bash(cmd, description)
    bash_c_cmd = "cd #{single_qoute(@local_path)} && #{cmd}"
    bash_cmd = "#{single_qoute(Setting.plugin_redmine_fbee['cmd_bash'])} -c #{single_qoute(bash_c_cmd)}"
    run_cmd bash_cmd, description
  end
  
  def single_qoute cmd
    "'#{cmd.gsub("'", "'\\\\''")}'"
  end
end