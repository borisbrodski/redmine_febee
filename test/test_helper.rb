# Load the normal Rails helper

FEBEE_PLUGIN_PATH="#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{FEBEE_PLUGIN_PATH}/../../../test/test_helper"
require "rbconfig"

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

FEBEE_TEST_CONFIG = YAML.load_file("#{FEBEE_PLUGIN_PATH}/config/test_configuration.yml")["test_configuration"]
# TODO Raise exception, if no test configuration file was loaded

Setting.plugin_redmine_febee['cmd_git'] = FEBEE_TEST_CONFIG['cmd_git']
Setting.plugin_redmine_febee['cmd_ssh'] = FEBEE_TEST_CONFIG['cmd_ssh']
Setting.plugin_redmine_febee['cmd_bash'] = FEBEE_TEST_CONFIG['cmd_bash']


def ruby_executable
  @ruby_executable ||= File.join(Config::CONFIG["bindir"], Config::CONFIG["ruby_install_name"])
end

def redmine_tmp_path
  "#{RAILS_ROOT}/tmp"
end

def git_bare_repository_path
  "#{redmine_tmp_path}/git_bare_repository"
end

def workspace_one_path
  "#{redmine_tmp_path}/workspace_one"
end

def ensure_empty_directory path
    FileUtils.mkdir_p path unless File.exists?(path)
    empty_non_root_directory(path)
end

module SaveTestDescription
  def test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name) do
        @description = name
        send "#{test_name}_do"
      end
      define_method("#{test_name}_do", &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end