require File.dirname(__FILE__) + '/../test_helper'

class GitRepositoryTest < ActiveSupport::TestCase
  include ExecHelper
  include FebeeUtils
  
  fixtures :projects, :febee_project_configurations, :febee_workspaces

  def setup
    @project_configuration = febee_project_configurations(:febee_project_configuration_without_gerrit)
    @git_repository = GitRepository.new @project_configuration

    @git_repository_path = "#{redmine_tmp_path}/git_repository"

    ensure_empty_directory(git_bare_repository_path)
    ensure_empty_directory(@git_repository_path)
    ensure_empty_directory(git_workspace_without_gerrit_path)
    
    run_git_cmd "Initialize bare repository", git_bare_repository_path, "init --bare"
    run_git_cmd "Clone repository", @git_repository_path, "clone #{git_bare_repository_path} ."
    run_git_cmd "Set git name", @git_repository_path, "config user.name test-initializer"
    run_git_cmd "Set git name", @git_repository_path, "config user.email test-initializer@local"
    FileUtils.touch "#{@git_repository_path}/file1.txt"
    FileUtils.touch "#{@git_repository_path}/file2.txt"
    run_git_cmd "Stage new files", @git_repository_path, "add ."
    run_git_cmd "Commit", @git_repository_path, "commit -m 'Two new files'"
    FileUtils.touch "#{@git_repository_path}/file3.txt"
    FileUtils.touch "#{@git_repository_path}/file4.txt"
    run_git_cmd "Stage new files", @git_repository_path, "add ."
    run_git_cmd "Commit", @git_repository_path, "commit -m 'Another two new files'"
    run_git_cmd "Push", @git_repository_path, "push origin master:refs/heads/master"

    # Create a release-branch
    run_git_cmd "Create local branch", @git_repository_path, "checkout -b release-1.x HEAD^"
    FileUtils.touch "#{@git_repository_path}/file5-release-1.x.txt"
    FileUtils.touch "#{@git_repository_path}/file6-release-1.x.txt"
    run_git_cmd "Stage new files", @git_repository_path, "add ."
    run_git_cmd "Commit", @git_repository_path, "commit -m 'Release-1.x: Yet another two new files'"
    run_git_cmd "Push", @git_repository_path, "push origin HEAD:refs/heads/release-1.x"
    
    
    

    # Init git repository and do some commits
    #run_cmd "Init new git repository", ""
    
    
#    p project_configuration
#    p project_configuration.project
#    p project_configuration.febee_workspace
  end

  def run_git_cmd description, path, cmd
    run_bash_cmd description, "cd #{single_qoute(path)}; git #{cmd}"
  end

  def run_bash_cmd description, cmd
    run_cmd description, FEBEE_TEST_CONFIG['cmd_bash'], '-c', cmd
  end

  test "Git repository initialization" do
    git_repository = GitRepository.new @project_configuration
    assert !git_repository.repository_initialized?, "Empty directory detected as a initialized repository"
    git_repository.initialize_repository
    git_repository = GitRepository.new @project_configuration
    assert File.exists?("#{git_workspace_without_gerrit_path}/.git"), "Workspace git repository doesn't get initialized"
    assert File.exists?("#{git_workspace_without_gerrit_path}/file1.txt")
    assert File.exists?("#{git_workspace_without_gerrit_path}/file2.txt")
    assert File.exists?("#{git_workspace_without_gerrit_path}/file3.txt")
    assert File.exists?("#{git_workspace_without_gerrit_path}/file4.txt")
    assert git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
  end

  test "Git repository reinitialization" do
    git_repository = GitRepository.new @project_configuration
    assert !git_repository.repository_initialized?, "Empty directory detected as a initialized repository"
    git_repository.initialize_repository
    git_repository = GitRepository.new @project_configuration
    assert git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
    FileUtils.touch "#{@git_repository_path}/abcd.txt"
    git_repository.reinitialize_repository
    assert !File.exists?("#{git_workspace_without_gerrit_path}/abcd.txt")
    assert git_repository.repository_initialized?, "A directory after reinitialization detected as not initialized"
  end
  
  test "Generate filenames from private key" do
    git_repository = GitRepository.new @project_configuration
    filenames = git_repository.send :private_key_filenames
    assert_equal 3, filenames.count
    filenames.each do |filename|
      assert filename.start_with? "#{Rails.root}/tmp/", "Wrong path (filename: '#{filename}')"
    end
    filenames.map! {|name| name.slice("#{Rails.root}/tmp/".length..-1)}
    assert filenames[0] =~ /pc_[0-9]+_[-0-9]+_git_ssh.cmd/, "Wrong filename 0: '#{filenames[0]}'"
    assert filenames[1] =~ /pc_[0-9]+_[-0-9]+_private_key/, "Wrong filename 1: '#{filenames[1]}'"
    assert filenames[2] =~ /pc_[0-9]+_[-0-9]+_complete/, "Wrong filename 2: '#{filenames[2]}'"
  end
end
