require File.dirname(__FILE__) + '/../test_helper'

class GitRepositoryTest < ActiveSupport::TestCase
  extend SaveTestDescription
  include ExecHelper
  include FebeeUtils

  fixtures :projects, :febee_project_configurations, :febee_workspaces

  def setup
    @@pretest_initializations ||= pretest_initializations || true
  end

  def pretest_initializations
    ensure_empty_directory(git_bare_repository_path)
    run_direct_git_cmd "Initialize bare repository", git_bare_repository_path, "init --bare"
    @@git_repo_initialized = {}
  end

  def setup_test project_configuration, options = {}
    logger.info "Test #{@description} for pc-id: #{project_configuration.id}"
    if options[:reinitialize_git_repo] || !@@git_repo_initialized[project_configuration.id]
      initialize_git_repo(project_configuration, options[:empty_workspace])
    else
      if options[:empty_workspace]
        ensure_empty_directory(project_configuration.febee_workspace.path)
      end
    end
    @git_repository = GitRepository.new project_configuration.febee_workspace
  end

  def tmp_repository(project_configuration)
    @tmp_repo_cache ||= {}
    return @tmp_repo_cache[project_configuration] if @tmp_repo_cache[project_configuration]
    
    tmp_repo_path = "#{redmine_tmp_path}/git_repository_#{project_configuration.is_gerrit?.to_s}"

    tmp_workspace = FebeeWorkspace.new(:path => tmp_repo_path)

    tmp_project_configuration = FebeeProjectConfiguration.new(
      :is_gerrit => project_configuration.is_gerrit,
      :private_key => project_configuration.private_key,
      :febee_workspace => tmp_workspace
    )
    tmp_workspace.febee_project_configuration = tmp_project_configuration
    [GitRepository.new(tmp_workspace), tmp_repo_path]
  end

  def initialize_git_repo project_configuration, leave_workspace_empty
    ensure_empty_directory(project_configuration.febee_workspace.path)

    main_branch_folder_path = project_configuration.main_branch_folder_path
    
    tmp_repo, tmp_repo_path = tmp_repository(project_configuration)
    ensure_empty_directory(tmp_repo_path)
 
    run_git_cmd "Init tmp git repo", tmp_repo, "init"
    run_git_cmd "Add remote", tmp_repo, "remote add origin #{single_qoute(project_configuration.git_url)}"
    run_git_cmd "Set git name", tmp_repo, "config user.name #{project_configuration.git_user_name}"
    run_git_cmd "Set git name", tmp_repo, "config user.email #{project_configuration.git_email_name}"

    # Remove old branches in case gerrit git repository
    run_git_cmd "Stage new files", tmp_repo, "fetch origin"
    branches_to_delete = (run_git_cmd "Stage new files", tmp_repo, "branch -r").split("\n")
    branches_to_delete.each do |branch|
      branch = branch[/\/(.*)/,1]
      run_git_cmd "Delete branch", tmp_repo, "push origin ':refs/heads/#{branch}'" unless branch == "master"
    end

    FileUtils.touch "#{tmp_repo_path}/file1.txt"
    FileUtils.touch "#{tmp_repo_path}/file2.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Two new files'"
    FileUtils.touch "#{tmp_repo_path}/file3.txt"
    FileUtils.touch "#{tmp_repo_path}/file4.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Another two new files'"
    run_git_cmd "Push", tmp_repo, "push -f origin master:refs/heads/#{main_branch_folder_path}master"

    # Create a release-branch
    run_git_cmd "Create local branch", tmp_repo, "checkout -b release-1.x HEAD^"
    FileUtils.touch "#{tmp_repo_path}/file5-release-1.x.txt"
    FileUtils.touch "#{tmp_repo_path}/file6-release-1.x.txt"
    run_git_cmd "Stage new files", tmp_repo, "add ."
    run_git_cmd "Commit", tmp_repo, "commit -m 'Release-1.x: Yet another two new files'"
    run_git_cmd "Push", tmp_repo, "push -f origin HEAD:refs/heads/#{main_branch_folder_path}release-1.x"
    @@git_repo_initialized[project_configuration.id] = true

    unless leave_workspace_empty
      GitRepository.new(project_configuration.febee_workspace).initialize_repository
    end
  end

  def run_git_cmd description, git_repository, cmd
    git_repository.send :run_with_git, cmd, description
  end

  def run_direct_git_cmd description, path, cmd
    run_direct_bash_cmd description, "cd #{single_qoute(path)}; git #{cmd}"
  end

  def run_direct_bash_cmd description, cmd
    run_cmd description, FEBEE_TEST_CONFIG['cmd_bash'], '-c', cmd
  end

  test "Git repository initialization" do
    for_all_project_configurations do |project_configuration|
      setup_test project_configuration, :empty_workspace => true
      assert !@git_repository.repository_initialized?, "Empty directory detected as a initialized repository"
      path = project_configuration.febee_workspace.path
      FileUtils.touch("#{path}/xxx.txt")
      @git_repository.initialize_repository
      @git_repository = GitRepository.new project_configuration.febee_workspace
      assert File.exists?("#{path}/.git"), "Workspace git repository doesn't get initialized"
      assert File.exists?("#{path}/file1.txt")
      assert File.exists?("#{path}/file2.txt")
      assert File.exists?("#{path}/file3.txt")
      assert File.exists?("#{path}/file4.txt")
      assert @git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
    end
  end

  test "Git repository reinitialization" do
    for_all_project_configurations do |project_configuration|
      setup_test project_configuration
      path = project_configuration.febee_workspace.path
      assert @git_repository.repository_initialized?, "A directory after initialization detected as not initialized"
      FileUtils.touch "#{path}/abcd.txt"
      @git_repository.reinitialize_repository
      assert !File.exists?("#{path}/abcd.txt"), "Reinitialization doesn't delete all files"
      assert @git_repository.repository_initialized?, "A directory after reinitialization detected as not initialized"
    end
  end

  test "Git get remote branches" do
    for_all_project_configurations do |project_configuration|
      setup_test project_configuration
      branches = project_configuration.febee_workspace.git_repository.remote_branches
      main_branch_folder_path = project_configuration.main_branch_folder_path
      assert branches.count >= 2, "Count of remote branches less that 2. Branches: #{branches.join(', ')}"
      assert branches.index("#{main_branch_folder_path}master"),
        "master branch wasn't found within the list of remote branches: #{branches}.join(', ')"
      assert branches.index("#{main_branch_folder_path}release-1.x"),
        "release-1.x branch wasn't found within the list of remote branches: #{branches}.join(', ')"
      branches2 = project_configuration.febee_workspace.git_repository.remote_branches
      assert_equal branches, branches2, "Second call to the GitRepository.remote_branches returns different results"
    end
  end

  test "Git get main branches" do
    for_all_project_configurations do |project_configuration|
      setup_test project_configuration
      branches = project_configuration.febee_workspace.git_repository.main_branches
      assert_equal 2, branches.count, "2 main branches are expected: master & release-1.x. Branches: #{branches.join(', ')}"
      assert branches.index("master"),
        "master branch wasn't found within the list of remote branches: #{branches.join(', ')}"
      assert branches.index("release-1.x"),
        "release-1.x branch wasn't found within the list of remote branches: #{branches.join(', ')}"
      branches2 = project_configuration.febee_workspace.git_repository.main_branches
      assert_equal branches, branches2, "Second call to the GitRepository.remote_branches returns different results"
    end
  end

  test "Git create feature branch" do
    for_all_project_configurations do |project_configuration|
      setup_test project_configuration
      git = project_configuration.febee_workspace.git_repository
      branches = git.remote_branches
      git.main_branches.each do |main_branch|
        issue_id = rand(10000)
        name = git.create_feature_branch(main_branch, issue_id)
        branches_after_create = git.remote_branches
        new_branches = branches_after_create - branches

        assert !new_branches.empty?, "No branch was created"

        assert_equal 1, new_branches.count,
          "It was more, that just one new branch created. Created branches: #{new_branches.inspect}"

        new_branch = new_branches[0]

        assert new_branch.start_with?(project_configuration.feature_branch_folder_path),
          "The new feature branch was created within wrong folder. Expected folder: " + 
          "#{project_configuration.feature_branch_folder_path}. New branch: #{new_branch}"

        assert new_branch.index(issue_id.to_s),
          "The new branch name doesn't contains the issue id. Issue id: #{issue_id}, new branch: #{new_branch}"

        assert_equal "#{project_configuration.feature_branch_folder_path}#{name}", new_branch,
          "Returned new branch name doesn't match new created branch name. Returned: #{name}"

        assert (branches - branches_after_create).empty?,
          "During creation of a new feature branch some other branch was deleted."

        assert !name.index("master"),
          "The main branch name 'master' shouldn't appear in the feature branch name."

        branches = branches_after_create
        name2 = git.create_feature_branch(main_branch, issue_id)
        number2 = name2[/_([0-9]+)$/, 1].to_i
        if number2 == 1
          assert_equal "#{name}_1", name2, "Wrong branch name. First branch: '#{name}', second branch: '#{name2}'"
        else
          number = name[/_([0-9]+)$/, 1].to_i
          assert_equal number + 1, number2, "Wrong branch name. First branch: '#{name}', second branch: '#{name2}'"
        end
        branches = git.remote_branches #branches << "#{project_configuration.feature_branch_folder_path}name2"
      end
    end
  end

  test "Feature branch commit ids" do
    [1,2,5].each do |commits_to_test|
      for_all_project_configurations do |project_configuration|
        setup_test project_configuration
        feature_branch_folder_path = project_configuration.feature_branch_folder_path
        git = project_configuration.febee_workspace.git_repository
        git.remote_branches.each do |main_branch|
          feature_branch_name = git.create_feature_branch("master", "321")
          tmp_repo, tmp_repo_path = tmp_repository(project_configuration)
          run_git_cmd "Fetch from repo", tmp_repo, "fetch"
          run_git_cmd "Checkout a new feature branch", tmp_repo,
            "checkout -b '#{feature_branch_name}' 'origin/#{feature_branch_folder_path}#{feature_branch_name}'"
          expected_commit_ids = []
          commits_to_test.times do |number|
            FileUtils.touch "#{tmp_repo_path}/commit#{number}.txt"
            run_git_cmd "Add new files", tmp_repo, "add ."
            commit_message = run_git_cmd "Commit", tmp_repo, "commit -m 'Commit #{number}'"
            commit = commit_message[/^\[.* ([a-zA-Z0-9]+)\]/, 1]
            expected_commit_ids <<= commit
            assert expected_commit_ids, "Can't extract commit id from commit message: '#{commit_message}'"
          end
          run_git_cmd "Push", tmp_repo,
            "push origin #{feature_branch_name}:refs/heads/#{feature_branch_folder_path}#{feature_branch_name}"

          git.fetch_from_server
          commit_ids = git.feature_branch_commit_ids(feature_branch_name, "master").sort!
          assert_equal commits_to_test, commit_ids.count, "Wrong number of commits on the feature branch"
          expected_commit_ids.sort.each_with_index do |expected_id, index|
            assert commit_ids[index].start_with? expected_id,
              "Wrong commit id. Expected start '#{expected_id}', actual id: '#{commit_ids[index]}'"
          end
        end
      end
    end
  end

  test "Generate filenames from private key" do
    project_configuration = FebeeProjectConfiguration.first(:conditions => 'private_key is not null')
    return unless project_configuration
    setup_test project_configuration
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

  def for_all_project_configurations
    FebeeProjectConfiguration.all.each do |project_configuration|
      yield project_configuration
    end
  end
end

