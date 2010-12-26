require 'redmine'
require 'dispatcher'

# TODO solve this
if defined?(PGconn)
  def PGconn.quote_ident(name)
  %("#{name}")
  end 
end

require_dependency 'redmine_febee/hooks'
require_dependency 'redmine_febee/project_patch'
require_dependency 'redmine_febee/projects_helper_patch'
require_dependency 'redmine_febee/projects_controller_patch'

Redmine::Plugin.register :redmine_febee do
  name 'Redmine feature branch enabled environment (FeBEE) plugin'
  author 'Boris Brodski'
  description 'This is a feature branch enabled environment (FeBEE) plugin for redmine.'
  version '0.0.1'
#  url 'http://example.com/path/to/plugin'
#  author_url 'http://example.com/about'

  project_module :febee do
    permission :view_feature_branches, :feature_branches => :view
    permission :create_feature_branch, :feature_branches => :create
    permission :try_to_merge, :feature_branches => :try_to_merge
    permission :move_to_gerrit, :feature_branches => :move_to_gerrit
    permission :manage_febee_project_configuration, :febee_project_configurations => :update
  end

  settings :default => {
    'cmd_git' => 'git',
    'cmd_ssh' => 'ssh',
    'cmd_bash' => '/bin/bash'
  }, :partial => 'settings/redmine_febee_configuration'

end

Dispatcher.to_prepare do
  unless ProjectsHelper.included_modules.include? RedmineFebee::ProjectsHelperPatch
    ProjectsHelper.send :include, RedmineFebee::ProjectsHelperPatch
  end
  unless ProjectsController.included_modules.include? RedmineFebee::ProjectsControllerPatch
    ProjectsController.send :include, RedmineFebee::ProjectsControllerPatch
  end
  unless Project.included_modules.include? RedmineFebee::ProjectPatch
    Project.send :include, RedmineFebee::ProjectPatch
  end
  unless IssuesController.included_modules.include? RedmineFebee::IssuesControllerPatch
    IssuesController.send :include, RedmineFebee::IssuesControllerPatch
  end
end

