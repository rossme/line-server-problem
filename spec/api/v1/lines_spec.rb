describe V1::Lines do
  describe "GET /api/v1/lines/:index" do
    context "when the index is valid" do
      let(:response_double) {
        instance_double("Response", success?: true, object: { line: "Line 12345678" }, error: nil)
      }
      let(:line_index) { 12345678 }

      before do
        allow(LineRetriever).to receive(:call).with(line_index).and_return(response_double)
      end

      it "returns the line text" do
        get "/lines/#{line_index}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Line 12345678")
      end
    end

    context "when the index is out of range" do
      let(:index_error) { IndexError.new("Line index out of range") }
      let(:response_double) { instance_double("Response", success?: false, object: nil, error: index_error) }
      let(:line_index) { 1000000000 }

      before do
        allow(LineRetriever).to receive(:call).with(line_index).and_return(response_double)
      end

      it "returns a 422 status and error message" do
        get "/lines/#{line_index}"

        expect(response).to have_http_status(:content_too_large)
        expect(response.body).to include("Line index out of range")
      end
    end

    context "when an unexpected error occurs" do
      let(:unexpected_error) { StandardError.new("Unexpected error") }
      let(:response_double) { instance_double("Response", success?: false, object: nil, error: unexpected_error) }
      let(:line_index) { 12345678 }

      before do
        allow(LineRetriever).to receive(:call).with(line_index).and_return(response_double)
      end

      it "returns a 500 status and error message" do
        get "/lines/#{line_index}"

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to include("Unexpected error")
      end
    end
  end
end
