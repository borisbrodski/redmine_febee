require File.dirname(__FILE__) + '/../test_helper'

class GitRepositoryTest < ActiveSupport::TestCase
  include ExecHelper
  include FebeeUtils

  fixtures :projects, :febee_project_configurations, :febee_workspaces

  def setup
    ensure_empty_directory(git_workspace_without_gerrit_path)
    ensure_empty_directory(git_workspace_with_gerrit_path)
    @@git_repos_initialized ||= initialize_git_repos || true
  end

  def setup_without_gerrit
    @project_configuration = febee_project_configurations(:febee_project_configuration_without_gerrit)
    @git_repository = GitRepository.new @project_configuration.febee_workspace
  end

  def setup_with_gerrit
    @project_configuration = febee_project_configurations(:febee_project_configuration_with_gerrit)
    @git_repository = GitRepository.new @project_configuration.febee_workspace
  end

  def initialize_git_repos
    ensure_empty_directory(git_bare_repository_path)
    run_direct_git_cmd "Initialize bare repository", git_bare_repository_path, "init --bare"

    setup_without_gerrit
    initialize_git_repo
    setup_with_gerrit
    initialize_git_repo
  end

  def initialize_git_repo
    tmp_repo_path = "#{redmine_tmp_path}/git_repository_"
    tmp_repo_path += @project_configuration.is_gerrit?.to_s
    ensure_empty_directory(tmp_repo_path)

    tmp_workspace = FebeeWorkspace.new(:path => tmp_repo_path)

    tmp_project_configuration = FebeeProjectConfiguration.new(
      :is_gerrit => @project_configuration.is_gerrit,
      :private_key => @project_configuration.private_key,
      :febee_workspace => tmp_workspace
    )
    tmp_workspace.febee_project_configuration = tmp_project_configuration
    tmp_repo = GitRepository.new(tmp_workspace)
 
#    run_git_cmd "Clone repository", tmp_repo_path, "clone #{git_bare_repository_path} ."
    run_git_cmd "Init tmp git repo", tmp_repo, "init"
    run_git_cmd "Add remote", tmp_repo, "remote add origin #{single_qoute(@project_configuration.git_url)}"
    run_git_cmd "Set git name", tmp_repo, "config user.name #{@project_configuration.git_user_name}"
    run_git_cmd "Set git name", tmp_repo, "config user.email #{@project_configuration.git_email_name}"
    FileUtils.touch "#{tmp_repo_path}/file1.txt"
    FileUtils.touch "#{tmp_repo_path}/file2.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Two new files'"
    FileUtils.touch "#{tmp_repo_path}/file3.txt"
    FileUtils.touch "#{tmp_repo_path}/file4.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Another two new files'"
    run_git_cmd "Push", tmp_repo, "push -f origin master:refs/heads/master"

    # Create a release-branch
    run_git_cmd "Create local branch", tmp_repo, "checkout -b release-1.x HEAD^"
    FileUtils.touch "#{tmp_repo_path}/file5-release-1.x.txt"
    FileUtils.touch "#{tmp_repo_path}/file6-release-1.x.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Release-1.x: Yet another two new files'"
    run_git_cmd "Push", tmp_repo, "push -f origin HEAD:refs/heads/release-1.x"
  end

  def run_git_cmd description, git_repository, cmd
    git_repository.send :run_with_git, cmd, description
#    run_bash_cmd description, "cd #{single_qoute(path)}; git #{cmd}"
  end

  def run_direct_git_cmd description, path, cmd
    run_bash_cmd description, "cd #{single_qoute(path)}; git #{cmd}"
  end

  def run_bash_cmd description, cmd
    run_cmd description, FEBEE_TEST_CONFIG['cmd_bash'], '-c', cmd
  end

  test "Git repository initialization without gerrit" do
    setup_without_gerrit
    do_test_git_repository_initialization
  end

  test "Git repository initialization with gerrit" do
    setup_with_gerrit
    do_test_git_repository_initialization
  end

  def do_test_git_repository_initialization
    assert !@git_repository.repository_initialized?, "Empty directory detected as a initialized repository"
    @git_repository.initialize_repository
    @git_repository = GitRepository.new @project_configuration.febee_workspace
    path = @project_configuration.febee_workspace.path
    assert File.exists?("#{path}/.git"), "Workspace git repository doesn't get initialized"
    assert File.exists?("#{path}/file1.txt")
    assert File.exists?("#{path}/file2.txt")
    assert File.exists?("#{path}/file3.txt")
    assert File.exists?("#{path}/file4.txt")
    assert @git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
  end

  test "Git repository reinitialization" do
    setup_without_gerrit
    assert !@git_repository.repository_initialized?, "Empty directory detected as a initialized repository"
    @git_repository.initialize_repository
    @git_repository = GitRepository.new @project_configuration.febee_workspace
    path = @project_configuration.febee_workspace.path
    assert @git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
    FileUtils.touch "#{path}/abcd.txt"
    @git_repository.reinitialize_repository
    assert !File.exists?("#{path}/abcd.txt"), "Reinitialization doesn't delete all files"
    assert @git_repository.repository_initialized?, "A directory after reinitialization detected as not initialized"
  end
  
  test "Generate filenames from private key" do
    setup_with_gerrit
    filenames = @git_repository.send :private_key_filenames
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

