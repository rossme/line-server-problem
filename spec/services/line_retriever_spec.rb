describe LineRetriever do
  let(:file_path) { "spec/fixtures/files/test_ascii_10MB.txt" }
  let(:stubbed_directory) { "spec/fixtures/files/stubbed_directory" }
  let(:idx_file_path) { "#{stubbed_directory}/file_in_bytesize_01.idx" }
  let(:batch_size) { 100_000 }
  let(:subject) { described_class.new(line_index) }
  let(:line_count) { 182704 } # line count of test_ascii_10MB.txt

  before do
    stub_const("LineOffsetHelper::PREPROCESSED_FILENAME", "file_in_bytesize")
    stub_const("LineOffsetHelper::PREPROCESSED_BATCH_SIZE", batch_size)
    stub_const("LineOffsetHelper::PREPROCESSED_DIRECTORY", stubbed_directory)
    stub_const("LineOffsetHelper::FILE_CACHE_EXPIRY", 10.minutes)
  end

  after do
    Rails.cache.clear
  end

  describe "#call" do
    context "when the original file is valid and index param is 0" do
      let(:line_index) { 0 }

      it "reads the line from the file" do
        response = subject.call

        expect(response.success?).to be true
        expect(response.error).to be_nil
        expect(response.object).to eq("0: This is a sample ASCII line for testing purposes.")
      end

      it "returns the correct line byte position" do
        allow(Rails.logger).to receive(:info)

        subject.call

        expect(Rails.logger).to have_received(:info).with(
          "Reading file line from byte 0"
        )
      end
    end

    context "when the original file is valid and index param is 3456" do
      let(:line_index) { 3456 }

      it "reads the line from the file" do
        response = subject.call

        expect(response.success?).to be true
        expect(response.error).to be_nil
        expect(response.object).to eq("3456: This is a sample ASCII line for testing purposes.")
      end

      it "returns the correct line byte position" do
        allow(Rails.logger).to receive(:info)

        subject.call

        expect(Rails.logger).to have_received(:info).with(
          "Reading file line from byte 192426"
        )
      end

      it "uses the Rails cache to store the file data" do
        expect(Rails.cache).to receive(:fetch).with(
          cache_key: "#{stubbed_directory}/file_in_bytesize_01.idx",
          expires_in: 10.minutes
        ).and_call_original

        subject.call
      end
    end

    context "when the index is the last line of the file" do
      let(:line_index) { line_count }

      it "reads the last line from the file" do
        response = subject.call

        expect(response.success?).to be true
        expect(response.error).to be_nil
        expect(response.object).to eq("182704: This is a sample ASCII line for testing purposes.")
      end
    end

    context "when the index param is out of range" do
      let(:line_index) { line_count + 1 }

      it "raises an IndexError if the index is out of range" do
        response = subject.call

        expect(response.success?).to be false
        expect(response.error).to be_a(IndexError)
        expect(response.error.message).to eq("Requested line index is outside file bounds")
      end
    end
  end
end
