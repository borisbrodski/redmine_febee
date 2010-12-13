require 'redmine'
require 'dispatcher'

# TODO solve this
def PGconn.quote_ident(name)
%("#{name}")
end 


require_dependency 'redmine_fbee/hooks'
require_dependency 'redmine_fbee/project_patch'
require_dependency 'redmine_fbee/projects_helper_patch'
require_dependency 'redmine_fbee/projects_controller_patch'

Redmine::Plugin.register :redmine_fbee do
  name 'Redmine feature branch enabled environment (FBEE) plugin'
  author 'Boris Brodski'
  description 'This is a feature branch enabled environment (FBEE) plugin for redmine.'
  version '0.0.1'
#  url 'http://example.com/path/to/plugin'
#  author_url 'http://example.com/about'

  project_module :fbee do
    permission :view_feature_branches, :feature_branches => :view
    permission :create_feature_branch, :feature_branches => :create
    permission :try_to_merge, :feature_branches => :try_to_merge
    permission :move_to_gerrit, :feature_branches => :move_to_gerrit
    permission :manage_fbee_project_configuration, :fbee_project_configurations => :update
  end

  settings :default => {
    'cmd_git' => 'git',
    'cmd_ssh' => 'ssh',
    'cmd_bash' => '/bin/bash'
  }, :partial => 'settings/redmine_fbee_configuration'

end

Dispatcher.to_prepare do
  ProjectsHelper.send :include, RedmineFbee::ProjectsHelperPatch
  ProjectsController.send :include, RedmineFbee::ProjectsControllerPatch
  Project.send :include, RedmineFbee::ProjectPatch
end

