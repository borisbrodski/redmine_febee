class FebeeMerge
  attr_accessor :commit_msg

  def self.create(params)
    merge = FebeeMerge.new
    merge.commit_msg = params[:commit_msg]
    merge
  end

  def errors
    {} # Validate commit_msg. For example: {:commit_msg => "ERROR"}
  end
end
