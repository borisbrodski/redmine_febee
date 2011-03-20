class FebeeMerge
  attr_accessor :commit_msg

  def self.create(params)
    febee_merge = FebeeMerge.new
    febee_merge.commit_msg = params[:commit_msg]
    febee_merge
  end

  def valid?
    validate
    errors.blank?
  end

  def errors
    @errors ||= {}
  end

  def validate
    # Validate commit_msg. For example: {:commit_msg => "ERROR"}
    errors.clear
    if commit_msg_without_comments.blank?
      errors[:commit_msg] = "Message can't be blank"  # TODO Make translatable
    end
  end

  def commit_msg_without_comments
    @msg ||= commit_msg.split("\n").reject do |line|
      line =~ /^\s*#/
    end.join("\n").strip if commit_msg
  end
end
