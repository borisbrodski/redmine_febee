module RedmineFbee
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom,
              :partial => 'hooks/redmine_fbee/view_issues_form_details_bottom'

    render_on :view_issues_show_description_bottom,
              :partial => 'hooks/redmine_fbee/view_issues_show_description_bottom'
  end
end