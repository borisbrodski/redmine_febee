require File.dirname(__FILE__) + '/../test_helper'

class FebeeWorkspaceTest < ActiveSupport::TestCase
  include ExecHelper
  include FebeeUtils
  
  fixtures :projects, :febee_project_configurations, :febee_workspaces

  def setup
    @project_configuration = febee_project_configurations(:febee_project_configuration_without_gerrit)
    @git_repository = GitRepository.new @project_configuration

    git_repository_path = "#{redmine_tmp_path}/git_repository"

    ensure_empty_directory(git_bare_repository_path)
    ensure_empty_directory(git_repository_path)
    run_git_cmd "Initialize bare repository", git_bare_repository_path, "init --bare"
    run_git_cmd "Clone repository", git_repository_path, "clone #{git_bare_repository_path} ."
    run_git_cmd "Set git name", git_repository_path, "config user.name test-initializer"
    run_git_cmd "Set git name", git_repository_path, "config user.email test-initializer@local"
    FileUtils.touch "#{git_repository_path}/file1.txt"
    FileUtils.touch "#{git_repository_path}/file2.txt"
    run_git_cmd "Stage new files", git_repository_path, "add ."
    run_git_cmd "Commit", git_repository_path, "commit -m 'Two new files'"
    FileUtils.touch "#{git_repository_path}/file3.txt"
    FileUtils.touch "#{git_repository_path}/file4.txt"
    run_git_cmd "Stage new files", git_repository_path, "add ."
    run_git_cmd "Commit", git_repository_path, "commit -m 'Another two new files'"
    run_git_cmd "Push", git_repository_path, "push origin master:refs/heads/master"

    # Create a release-branch
    run_git_cmd "Create local branch", git_repository_path, "checkout -b release-1.x"
    FileUtils.touch "#{git_repository_path}/file5-release-1.x.txt"
    FileUtils.touch "#{git_repository_path}/file6-release-1.x.txt"
    run_git_cmd "Stage new files", git_repository_path, "add ."
    run_git_cmd "Commit", git_repository_path, "commit -m 'Release-1.x: Yet another two new files'"
    run_git_cmd "Push", git_repository_path, "push origin HEAD:refs/heads/release-1.x"
    
    
    

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

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
