require File.dirname(__FILE__) + '/../test_helper'

class FebeeUtilsTest < ActiveSupport::TestCase
  include FebeeUtils

  def setup
    @test_dir = "#{redmine_tmp_path}/dir_to_remove"
    FileUtils.rm_rf @test_dir
    FileUtils.mkdir @test_dir
    FileUtils.mkdir "#{@test_dir}/subdir1"
    FileUtils.mkdir "#{@test_dir}/subdir2"
    FileUtils.mkdir "#{@test_dir}/.subdir3"
    FileUtils.touch "#{@test_dir}/subdir1/file1"
    FileUtils.touch "#{@test_dir}/subdir1/file2"
    FileUtils.touch "#{@test_dir}/subdir1/.file3"
    FileUtils.mkdir "#{@test_dir}/subdir1/subdir1"
    FileUtils.mkdir "#{@test_dir}/subdir1/subdir2"
    FileUtils.mkdir "#{@test_dir}/subdir1/.subdir3"
    FileUtils.touch "#{@test_dir}/subdir1/.subdir3/file1"
    FileUtils.touch "#{@test_dir}/subdir1/.subdir3/file2"
    FileUtils.touch "#{@test_dir}/subdir1/.subdir3/.file3"
    FileUtils.touch "#{@test_dir}/file1"
    FileUtils.touch "#{@test_dir}/file2"
    FileUtils.touch "#{@test_dir}/.file3"
    FileUtils.touch "#{@test_dir}/.subdir3/file1"
    FileUtils.touch "#{@test_dir}/.subdir3/file2"
    FileUtils.touch "#{@test_dir}/.subdir3/.file3"
    FileUtils.mkdir "#{@test_dir}/.subdir3/subdir1"
    FileUtils.touch "#{@test_dir}/.subdir3/subdir1/.file3"
  end

  def test_remove_non_root_directory
    remove_non_root_directory @test_dir
    assert !File.exist?(@test_dir), "Removed directory still exists"
  end

  def test_empty_non_root_directory
    empty_non_root_directory @test_dir
    assert File.exist?(@test_dir), "Directory was removed, when it shouldn't be."
    assert_equal 0, Dir.glob(File.join(@test_dir, '*')).size
    assert_equal 0, Dir.glob(File.join(@test_dir, '.*')).select {|f| f !~ /\/..?$/}.size
  end
end