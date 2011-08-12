
class FebeeMergeController < ApplicationController
  unloadable

  helper FebeeMergeHelper
  include FebeeMergeHelper
  before_filter :init

  def new
    @febee_project_configuration.access_git do |git|
      @feature_branch.check_against_git_repository(git)
      @commits = git.commits(@feature_branch.commit_ids)
      unless @febee_merge
        commit_msgs = [@feature_branch.commit_msg, '']
        @commits.each do |commit|
          commit_msgs << "\n"
          commit_msgs << "## Commit id: #{commit.sha}"
          commit_msgs << "## Author: #{commit.author}"
          commit_msgs << "## Date: #{commit.date.strftime '%d.%m.%Y&nbsp;%H:%M:%S'}"
          (commit.message.split "\n").each do |line|
            commit_msgs << "# #{line}"
          end
        end
        @febee_merge = FebeeMerge.create(:commit_msg => commit_msgs.join("\n"))
      end
    end

    unless @feature_branch.status == FeatureBranch::STATUS_PENDING
      error :feature_branch_not_in_status_pending, :name =>@feature_branch.name
      return
    end

    if @feature_branch.commits_count < 1
      error :no_commits_to_merge, :name =>@feature_branch.name
      return
    end
  end

  def create
    @febee_merge = FebeeMerge.create(params[:febee_merge])
    @feature_branch.commit_msg = @febee_merge.commit_msg_without_comments
    unless @feature_branch.save
      flash[:error] = ll :error_saving_commit_message
      redirect_to_issue
    end

    moving_to_gerrit = params[:merge_method] == 'move_to_gerrit'

    message_file = "#{RAILS_ROOT}/tmp/message_file_#{rand(100000000)}"
    begin
      @febee_project_configuration.access_git do |git|
        @feature_branch.check_against_git_repository(git)
        @commits = git.commits(@feature_branch.commit_ids)
        authors = @commits.collect do |commit|
          "Co-Author: #{commit.author.name} <#{commit.author.email}>" 
        end.uniq

        feature_branch_full_name = "#{@febee_project_configuration.feature_branch_folder_path}#{@feature_branch.name}"
        base_on_branch_full_name = "#{@febee_project_configuration.main_branch_folder_path}#{@feature_branch.based_on_name}"
        user = User.current

        File.open(message_file, 'w') do |f|
          f.write(@feature_branch.commit_msg)
          f.write("\n\n")
          redmine_url = Setting.plugin_redmine_febee['redmine_url']
          if redmine_url.blank?
            flash[:error] = ll :setting_redmine_url_blank
            return redirect_to_issue
          end
          redmine_url.strip!
          redmine_url <<= '/' unless redmine_url[-1..-1] == '/'
          f.write("Issue ##{@issue.id}: #{redmine_url}issues/#{params[:issue_id]}\n")
          f.write("Feature branch: #{feature_branch_full_name}\n")
          f.write("For branch: #{base_on_branch_full_name}\n\n")
          f.write("#{authors.join('\n')}\n") unless authors.size < 2
          f.write("Change-Id: #{generate_change_id}\n")
          if moving_to_gerrit
            f.write("Moved to gerrit by: #{user.name}\n")
          else
            f.write("Merged by: #{user.name}\n")
          end
        end

        tmp_base_branch = "tmp_base_#{rand(100000000)}"
        tmp_feature_branch = "tmp_feature_#{rand(100000000)}"

        begin
          git.fetch_from_server
          git.reset_hard
          git.branch(tmp_base_branch, base_on_branch_full_name)
          git.checkout_b(tmp_feature_branch, feature_branch_full_name)
          debugger
          begin
            git.merge(tmp_base_branch)
          rescue Exception => msg
            puts msg.backtrace
            flash[:error] = "Conflicts was found. Merge your '#{@feature_branch.name}' branch with the current '#{@feature_branch.based_on_name}' branch"
            return
          end
          git.reset_soft(tmp_base_branch)
          git.commit_F(message_file)
          if moving_to_gerrit
            git.push("refs/for/#{base_on_branch_full_name}")
          else
            git.push(base_on_branch_full_name)
          end
        ensure
          git.checkout_remote_branch(base_on_branch_full_name)
          git.branch_delete(tmp_base_branch)
          git.branch_delete(tmp_feature_branch)
        end

        flash[:notice] = ll "merged_flash_#{params[:merge_method]}", :count => @commits.size, :name => @feature_branch.based_on_name
        redirect_to_issue
      end
    rescue Exception => msg
      if msg.class == ExecHelper::ExecError
        message = msg.message
      else
        message = msg.to_s
      end
      puts msg.backtrace
      flash[:error] = message
      redirect_to_issue
    ensure
      FileUtils.rm_rf message_file
    end

  end

private
  def init
    @move_to_gerrit = (params[:merge_method] == 'move_to_gerrit')

    @feature_branch = FeatureBranch.find(params[:feature_branch_id])
    @issue = @feature_branch.issue

    unless User.current.allowed_to?(params[:merge_method].to_sym, @issue.project)
      error "user_not_allowed_to_#{params[:merge_method]}"
      return
    end
    @febee_project_configuration = @issue.project.febee_project_configuration
  end

  def generate_change_id
    sha1 = Digest::SHA1.hexdigest "#{@feature_branch.id}_#{@feature_branch.name}_#{@feature_branch.based_on_name}"
    "I#{sha1}"
  end

  def error(message, options = {})
    flash[:error] = ll(message, options)
    redirect_to_issue
  end
  def redirect_to_issue
    redirect_to :controller => 'issues', :action => 'show', :id => @issue.id
  end
end
