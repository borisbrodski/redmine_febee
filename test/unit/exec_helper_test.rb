require File.dirname(__FILE__) + '/../test_helper'

require 'exec_helper'


class ExecHelperTest < ActiveSupport::TestCase
  include ExecHelper
  extend SaveTestDescription

  test "simple output with puts" do
    assert_equal "Test1\n", call_ruby("puts 'Test1'")
  end

  test "simple output with print" do
    assert_equal "Test2", call_ruby("print 'Test2'")
  end

  test "Testing ARGV = 0" do
    assert_equal "0", call_ruby('print "#{ARGV.count}"')
  end

  test "Testing ARGV = 1" do
    assert_equal "1", call_ruby('print "#{ARGV.count}"', 'a')
  end

  test "Testing ARGV = 5" do
    assert_equal "5", call_ruby('print "#{ARGV.count}"', *('a'..'e'))
  end

  test "Testing one argument" do
    assert_equal "abc", call_ruby('print "#{ARGV[0]}"', 'abc')
  end

  test "Testing joining two arguments" do
    assert_equal "abc:def", call_ruby('print "#{ARGV.join ":"}"', 'abc', 'def')
  end

  test "Testing joining five arguments" do
    assert_equal "1,2,3,4,5", call_ruby('print "#{ARGV.join ","}"', *('1'..'5'))
  end

  test "Return code 1" do
    assert_exec_error 'exit 1' do |e|
      assert_equal 1, e.exit_code
    end
  end

  test "Return code 10" do
    assert_exec_error 'exit 10' do |e|
      assert_equal 10, e.exit_code
    end
  end

  test "Return code -1" do
    assert_exec_error 'exit -1' do |e|
      assert 0 != e.exit_code
    end
  end

  test "Stdout output 1" do
    assert_exec_error 'print "abcd"; exit 1' do |e|
      assert_equal 'abcd', e.std_out
    end
  end

  test "Stdout output 2" do
    assert_exec_error 'puts "54321"; puts "12345"; exit 1' do |e|
      assert_equal "54321\n12345\n", e.std_out
    end
  end

  test "Stderr output 1" do
    assert_exec_error 'STDERR.print "abcd"; exit 1' do |e|
      assert_equal 'abcd', e.std_err
    end
  end

  test "Stderr output 2" do
    assert_exec_error 'STDERR.puts "54321"; STDERR.puts "12345"; exit 1' do |e|
      assert_equal "54321\n12345\n", e.std_err
    end
  end

  test "Stdout & Stderr output 1" do
    assert_exec_error 'STDERR.print "abcd"; print "321"; exit 1' do |e|
      assert_equal '321', e.std_out
      assert_equal 'abcd', e.std_err
    end
  end

  test "Stdout & Stderr output 2" do
    assert_exec_error 'STDERR.puts "54321"; STDERR.puts "12345";puts "def"; puts "fed"; exit 1' do |e|
      assert_equal "def\nfed\n", e.std_out
      assert_equal "54321\n12345\n", e.std_err
    end
  end

private
  def assert_exec_error(*cmds)
    call_ruby *cmds
    flunk build_message nil, "<?> doesn't raise an ExecError.", cmd.join(' ')
  rescue ExecError => e
    assert true # Lets count an assertion
    yield e
  end

  def call_ruby(*code_with_parameters)
    cmds = ["#{ruby_executable}", "-e", *code_with_parameters]
    run_cmd(@description, *cmds)
  rescue ExecError => e
    assert_equal cmds, e.cmds
    assert_equal @description, e.description
    raise e
  end
end
