require 'rubygems'
require 'open4'

module ExecHelper
  include Redmine::I18n
  
  class ExecError < StandardError
    attr :cmds
    attr :description
    attr :exit_code
    attr :std_out
    attr :std_err
    def initialize(cmds, description, exit_code = nil, std_out = nil, std_err = nil)
      @cmds = cmds
      @description = description
      @exit_code = exit_code
      @std_out = std_out
      @std_err = std_err
      logger.warn "ExecError: #{message}"
    end
    
    def message
      message = "#{to_s}\nTask: #{description}\nCmd: \"#{cmds.join '" "'}\""
      message <<= "\nStandard output: '#{std_out}'" unless std_out.blank?
      message <<= "\nStandard error: '#{std_err}'" unless std_err.blank?
    end
  end
  
  def run_cmd(description, *cmds)
    output = nil
    error = nil
    logger.info "#{description} => Running: '#{cmds.join " "}'"
    begin
      status = Open4::popen4(*cmds) do |pid, stdin, stdout, stderr|
        output = stdout.read
        error = stderr.read
      end
    rescue Exception => e
      logger.warn e
      raise ExecError.new(cmds, description), l(:exec_error_cant_start_program) + ": #{e}"
    end
    raise ExecError.new(cmds, description), l(:exec_error_cant_start_program)  if status == nil
    exit_code = status.exitstatus
    if exit_code == 0
      logger.info "Success\nStdOut: '#{output}'\nStdErr: '#{error}'"
      output
    else
      raise ExecError.new(cmds, description, exit_code, output, error), l(:exec_error_cant_start_program)
    end
  end

  def single_qoute cmd
    "'#{cmd.gsub("'", "'\\\\''")}'" if cmd
  end
end
