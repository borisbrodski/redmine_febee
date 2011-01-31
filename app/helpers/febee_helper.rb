module FebeeHelper
 
  def with_git
    return false unless @project
    pc = @project.febee_project_configuration
    pc.access_git do |git|
      begin
        yield git
        true
      rescue FebeeUtils::FebeeError => e
        flash[:error] = e.message
        false
      end
    end if pc
  end
 
end
