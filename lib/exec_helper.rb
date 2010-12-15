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
puts "ExecError: #{message}" # TODO use logger
    end
    
    def message
      message = "#{to_s}\nTask: #{description}\nCmd: #{cmd}"
      message <<= "\nStandard output: '#{std_out}'" unless std_out.blank?
      message <<= "\nStandard error: '#{std_err}'" unless std_err.blank?
    end
  end
  
  def run_cmd(cmd, description)
    output = nil
    error = nil
puts "#{description} => Running: '#{cmd}'" # TODO use logger
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
    exit_code = status.exitstatus
    if exit_code == 0
puts "Success\nStdOut: '#{output}'\nStdErr: '#{error}'"# TODO use logger
      output
    else
      raise ExecError.new(cmd, description, exit_code, output, error), l(:exec_error_cant_start_program)
    end
  end
end
