describe PreprocessFileJob, type: :job do
  let(:filename) { "test_ascii_10MB.txt" }
  let(:file_path) { "spec/fixtures/files/#{filename}" }

  before do
    allow(PreprocessFile).to receive(:call).and_return(true)
  end

  it "calls the PreprocessFile service and logs the success message" do
    allow(Rails.logger).to receive(:info)
    expect(PreprocessFile).to receive(:call).with(file_path)

    described_class.new.perform(file_path)

    expect(Rails.logger).to have_received(:info).with(
      I18n.t("services.preprocess_file.job_success", file_path: file_path)
    )
  end
end
