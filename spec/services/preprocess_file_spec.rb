# frozen_string_literal: true

describe PreprocessFile do
  let(:batch_size) { 100_000 }
  let(:filename) { "test_ascii_10MB.txt" }
  let(:file_path) { "spec/fixtures/files/#{filename}" }
  let(:subject) { described_class.new(file_path) }
  let(:stubbed_directory) { "spec/fixtures/files/preprocessed_stubbed_directory" }
  let(:idx_file_path) { "#{stubbed_directory}/file_in_bytesize_01.idx" }

  before do
    stub_const("PreprocessFile::PREPROCESSED_FILENAME", "file_in_bytesize")
    stub_const("PreprocessFile::PREPROCESSED_BATCH_SIZE", batch_size)
    stub_const("PreprocessFile::PREPROCESSED_DIRECTORY", stubbed_directory)
  end

  after do
    FileUtils.rm_rf(stubbed_directory) if Dir.exist?(stubbed_directory)
    Rails.cache.clear
  end

  describe "#call" do
    context "when the file_path is valid" do
      it "creates the preprocessed directory" do
        expect(Dir).not_to exist(stubbed_directory)

        subject.call

        expect(Dir).to exist(stubbed_directory)
      end

      it "creates the first preprocessed file and logs the info" do
        expect(File).not_to exist(idx_file_path)

        subject.call

        expect(File).to exist(idx_file_path)
      end

      it "creates the first preprocessed file with the correct metadata" do
        subject.call

        file = File.open(idx_file_path, "rb")
        data = Marshal.load(file)
        file.close

        expect(data[:metadata][:original_file_path]).to eq(file_path)
        expect(data[:metadata][:original_mtime]).to be_a(Time)
      end

      it "creates the preprocessed file with the correct offsets" do
        subject.call

        file = File.open(idx_file_path, "rb")
        data = Marshal.load(file)
        file.close

        expect(data[:offsets]).to be_an(Array)

        # Representing the number of lines in the test file
        expect(data[:offsets].size).to eq(batch_size)
      end

      it "adds bytesize of line 30043 to file_in_bytesize_02.idx" do
        index = 30043
        line_text = "30043: This is a sample ASCII line for testing purposes."

        subject.call

        file = File.open(idx_file_path, "rb")
        data = Marshal.load(file)
        file.close

        find_line_with_offest = File.open(file_path, "r") do |f|
          relative_line_index = index % batch_size
          f.seek(data[:offsets][relative_line_index], IO::SEEK_SET)
          f.readline(chomp: true)
        end

        expect(find_line_with_offest).to eq(line_text)
        expect(data[:offsets].size).to eq(batch_size)
      end

      it "handles EOFError gracefully" do
        allow(Rails.logger).to receive(:warn)

        subject.call

        expect(Rails.logger).to have_received(:warn).with(
          "File #{file_path} end of file reached"
        )
      end

      it "logs the success message" do
        allow(Rails.logger).to receive(:info)

        subject.call

        expect(Rails.logger).to have_received(:info).with(
          "File processed: #{file_path} with metadata"
        )
      end
    end
  end
end
