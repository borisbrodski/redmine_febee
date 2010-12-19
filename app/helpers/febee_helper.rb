module FebeeHelper
  
  def schedule_git_task(&block)
    @febee_git_tasks ||= []
    @febee_git_tasks << block
  end
  
  def execute_git_tasks
    return unless @febee_git_tasks and @febee_git_tasks.size > 0
    @project.febee_project_configuration.access_git do |git|
      begin
        @febee_git_tasks.each do |block|
          block.call git
        end
      rescue ExecHelper::ExecError => e
        flash[:error] = e.message
      end
    end
    @febee_git_tasks.clear
  end
  
end