# frozen_string_literal: true

# Helper module to manage line offsets in a file.
# This module provides methods to validate the index of a line in a file,
# check if the original file has been modified, and handle offsets and metadata.
#
# @see LineRetriever

module LineOffsetHelper
  PREPROCESSED_FILENAME = PreprocessFile::PREPROCESSED_FILENAME
  PREPROCESSED_BATCH_SIZE = PreprocessFile::PREPROCESSED_BATCH_SIZE
  PREPROCESSED_DIRECTORY = PreprocessFile::PREPROCESSED_DIRECTORY
  FILE_CACHE_EXPIRY = 10.minutes

  def validate_index!
    raise IOError, I18n.t("services.file_line_finder.file_modified") if original_file_modified?
    raise IndexError, I18n.t("services.file_line_finder.outside_of_bounds") if line_outside_of_bounds?
  end

  private

  def offsets
    @_offsets ||= file_in_bytesize[:offsets]
  end

  def metadata
    @_metadata ||= file_in_bytesize[:metadata]
  end

  def original_line_count
    @_original_line_count ||= metadata[:original_line_count]
  end

  def original_file_path
    @_original_file_path ||= metadata[:original_file_path]
  end

  def original_mtime
    @_original_mtime ||= metadata[:original_mtime]
  end

  def current_mtime
    @_current_mtime ||= File.mtime(original_file_path)
  end

  def original_file_modified?
    original_mtime != current_mtime
  end

  def line_outside_of_bounds?
    index < 0 || index >= original_line_count
  end
end
