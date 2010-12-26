# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')
require "rbconfig"


# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

def ruby_executable
  @ruby_executable ||= File.join(Config::CONFIG["bindir"], Config::CONFIG["ruby_install_name"])
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