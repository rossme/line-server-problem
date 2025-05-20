# frozen_string_literal: true

# Service to preprocess a file by creating an index of byte offsets for each line.
# It generates a series of files containing the offsets and metadata about the original file.
# The files are stored in a directory named "files_in_bytesize" and are named with a specific format.
#
# @param [file_path] the path to the file to be preprocessed.
# @return [void]
#
# @example PreprocessFile.call("path/to/file.txt")

class PreprocessFile
  include Callable

  class PreprocessFileError < StandardError; end

  PREPROCESSED_FILENAME = "file_in_bytesize".freeze
  PREPROCESSED_DIRECTORY = "files_in_bytesize".freeze
  PREPROCESSED_BATCH_SIZE = 100_000

  def initialize(file_path)
    @file_path = file_path
    @offsets = []
  end

  def call
    delete_preprocessed_directory_if_exists
    preprocess_file
  rescue PreprocessFileError => error
    handle_error(error)
  end

  private

  attr_reader :file_path, :offsets

  def delete_preprocessed_directory_if_exists
    if Dir.exist?(PREPROCESSED_DIRECTORY)
      FileUtils.rm_rf(PREPROCESSED_DIRECTORY)
      Rails.logger.info I18n.t("services.preprocess_file.delete_success", directory_path: PREPROCESSED_DIRECTORY)
    end
  end

  def preprocess_file
    generate_bytesize_index_for_each_line
    generate_bytesize_files_with_metadata
  end

  def generate_bytesize_index_for_each_line
    File.open(file_path, "r") do |f|
      while (line = f.readline)
        offsets << f.tell - line.bytesize
      end
    rescue EOFError
      Rails.logger.warn I18n.t("services.preprocess_file.warn_eof", file_path: file_path)
    end
  end

  def generate_bytesize_files_with_metadata
    Dir.mkdir(PREPROCESSED_DIRECTORY) unless Dir.exist?(PREPROCESSED_DIRECTORY)

    offsets.each_slice(PREPROCESSED_BATCH_SIZE).with_index do |offset_slice, index|
      data_to_dump = {
        metadata: metadata,
        offsets: offset_slice
      }

      # Example file name for lines 100_000 to 110_000 => file_in_bytesize_11.idx
      generate_filename = "#{PREPROCESSED_DIRECTORY}/#{PREPROCESSED_FILENAME}_#{format('%02d', index + 1)}.idx"

      File.open(generate_filename, "wb") do |idx_file|
        # Serialization of data
        Marshal.dump(data_to_dump, idx_file)
      end
    end

    Rails.logger.info I18n.t("services.preprocess_file.success", file_path: file_path)
  end

  def metadata
    {
      original_file_path: file_path,
      original_mtime: File.mtime(file_path),
      original_line_count: offsets.size
    }
  end

  def handle_error(error)
    delete_preprocessed_directory_if_exists

    Rails.logger.info I18n.t("services.preprocess_file.error", error: error.message)
  end
end
