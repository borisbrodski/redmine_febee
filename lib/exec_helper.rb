require 'rubygems'
require 'open4'

module ExecHelper
  include Redmine::I18n
  
  class ExecError < StandardError
    attr :cmd
    attr :description
    attr :exit_code
    attr :std_out
    attr :std_err
    def initialize(cmd, description, exit_code = nil, std_out = nil, std_err = nil)
      @cmd = cmd
      @description = description
      @exit_code = exit_code
      @std_out = std_out
      @std_err = std_err
    end
    
    def message
# TODO Format message 
      "Task: '#{description}'\nCmd: #{cmd}\n#{to_s}.\nStdout: '#{output}'\nstderr: '#{error}'" 
    end
  end
  
  def run_cmd1(cmd, description)
    output = nil
    error = nil
puts "#{description} => Running: '#{cmd}'"
    begin
      status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
        output = stdout.read
        error = stderr.read
      end
    rescue Exception => e
      # TODO add caused by
      raise ExecError.new(cmd, description), l(:exec_error_cant_start_program) + ": #{e}"
    end
    raise ExecError.new(cmd, description), l(:exec_error_cant_start_program)  if status == nil
    status = status.exitstatus
    if status == 0
      output
    else
      raise ExecError.new(cmd, description, status, output, error), l(:exec_error_cant_start_program)
    end
  end
end
