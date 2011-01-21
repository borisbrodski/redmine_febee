module FebeeHelper
 
  def with_git
    pc = @project.febee_project_configuration if @project
    pc.access_git do |git|
      begin
        yield git
        true
      rescue FebeeUtils::FebeeError => e
        flash[:error] = e.message
        false
      end
    end
  end
 
end
