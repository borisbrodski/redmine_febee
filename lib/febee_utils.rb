module FebeeUtils
  class FebeeError < StandardError
    def message
      "#{to_s}"
    end
  end

  # Remove
  def remove_non_root_directory path
    check_path_for_danger_to_remove path
  
    logger.debug "Removing '#{path}'"
    FileUtils.rm_rf path
  end
  
  # Remove all files and subdirectories within 'path'
  def empty_non_root_directory path
    check_path_for_danger_to_remove path

    logger.debug "Removing content of '#{File.join path, '*'}'"
    FileUtils.rm_rf Dir.glob(File.join(path, '*'))
    FileUtils.rm_rf Dir.glob(File.join(path, '.*')).select {|f| f !~ /\/..?$/}
  end

  # Try to prevent 'rm -rf /'
  def check_path_for_danger_to_remove path
    absolute_path = File.expand_path(path).strip 
    if absolute_path.blank? || absolute_path == '/'
      raise "Removing '#{absolute_path}' is too dangerous."
    end
  end
  def with_file_lock(filename, *args)
    File.open(filename, File::RDWR | File::CREAT) do |f|
      f.flock(File::LOCK_EX)
      yield *args
    end
  end
  # TODO remove this
  def logger
    RAILS_DEFAULT_LOGGER
  end
end
