# frozen_string_literal: true

# Service to retrieve a line from a preprocessed file based on the given index.
#
# @param [index] the line index.
# @return [String] the line read from the file at the specified index.
#
# @example LineRetriever.call(14030)

class LineRetriever
  include LineOffsetHelper
  include Callable

  def initialize(index)
    @index = index
  end

  def call
    validate_index!

    Response.new(true, read_line_from_file, nil)
  rescue StandardError => error
    Response.new(false, nil, error)
  end

  private

  Response = Struct.new(:success?, :object, :error)

  attr_reader :index

  def read_line_from_file
    File.open(original_file_path, "r") do |f|
      relative_line_index = index % PREPROCESSED_BATCH_SIZE
      f.seek(offsets[relative_line_index], IO::SEEK_SET)

      # Log the line byte position of the file
      Rails.logger.info I18n.t("services.file_line_finder.line_byte_from_file", byte: f.tell.to_s)

      # Read the line from the file and remove the character \n with chomp: true
      f.readline(chomp: true)
    rescue TypeError => e
      Rails.logger.info I18n.t("services.file_line_finder.read_line_error", error: e.message)
    end
  end

  def file_in_bytesize
    filename = "#{PREPROCESSED_DIRECTORY}/#{PREPROCESSED_FILENAME}_#{format('%02d', index / PREPROCESSED_BATCH_SIZE + 1)}.idx"

    @_file_in_bytesize ||= Rails.cache.fetch(cache_key: filename, expires_in: FILE_CACHE_EXPIRY) do
      if File.exist?(filename)
        deserialize_data_with_marshal(filename)
      else
        raise IndexError, I18n.t("services.file_line_finder.outside_of_bounds")
      end
    end
  end

  def deserialize_data_with_marshal(filename)
    File.open(filename, "rb") do |f|
      # Reconstruct the original serialized data
      Marshal.load(f)
    end
  end
end
