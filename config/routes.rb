ActionController::Routing::Routes.draw do |map|
  map.connect 'issues/:issue_id/:merge_method/:feature_branch_id',
    :controller => 'febee_merge', :action => 'new', :conditions => { :method => :get },
    :requirements => { :merge_method => /move_to_gerrit|try_to_merge/ }

  map.connect 'issues/:issue_id/:merge_method/:feature_branch_id',
    :controller => 'febee_merge', :action => 'create', :conditions => { :method => :post },
    :requirements => { :merge_method => /move_to_gerrit|try_to_merge/ }

  map.connect 'mark_gerrit_review_as_merged/:change_id',
    :controller => 'febee_hook', :action => 'mark_as_merged'
    
  map.connect 'mark_gerrit_review_as_abandoned/:change_id',
    :controller => 'febee_hook', :action => 'mark_as_abandoned'
end

