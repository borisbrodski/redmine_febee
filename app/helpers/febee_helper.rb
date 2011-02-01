module FebeeHelper
 
  def with_git
    return false unless @project
    pc = @project.febee_project_configuration
    begin
      pc.access_git do |git|
        yield git
        true
      end
    rescue FebeeUtils::FebeeError => e
      flash[:error] = e.message
      false
    end if pc
  end
 
end
