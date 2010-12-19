module FbeeHelper
  
  def schedule_git_task(&block)
    @fbee_git_tasks ||= []
    @fbee_git_tasks << block
  end
  
  def execute_git_tasks
    return unless @fbee_git_tasks and @fbee_git_tasks.size > 0
    @project.fbee_project_configuration.access_git do |git|
      begin
        @fbee_git_tasks.each do |block|
          block.call git
        end
      rescue ExecHelper::ExecError => e
        flash[:error] = e.message
      end
    end
    @fbee_git_tasks.clear
  end
  
end