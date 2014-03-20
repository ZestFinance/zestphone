require 'spec_helper'

module Telephony
  describe Inbound::ConversationQueuesController do
    before { @routes = Engine.routes }

    describe '#front' do
      context 'when queue is empty' do
        let(:agent) { create :available_agent }

        it 'is not found' do
          delete :front, csr_id: agent.csr_id
          expect(response.response_code).to eq 404 # not found
          expect(response.body).to eq({ 'errors' => ['Queue is empty'] }.to_json)
        end

        it 'logs error' do
          Rails.logger.should_receive(:error).with(
            "Dequeue attempt by CSR (#{agent.csr_id}) failed because queue is empty"
          )
          delete :front, csr_id: agent.csr_id
        end
      end

      context 'when agent is on a call' do
        let(:agent) { create :on_a_call_agent }

        it 'is unprocessable' do
          delete :front, csr_id: agent.csr_id
          expect(response.response_code).to eq 422 # unprocessable entity
          expect(response.body).to eq({ 'errors' => ['You are already on a call'] }.to_json)
        end

        it 'logs error' do
          Rails.logger.should_receive(:error).with(
            "Dequeue attempt by CSR (#{agent.csr_id}) failed because agent is on a call"
          )
          delete :front, csr_id: agent.csr_id
        end
      end

      context 'when any other error occurs' do
        it 'is unprocessable' do
          delete :front, csr_id: 5
          expect(response.response_code).to eq 500 # unprocessable entity
          expect(response.body).to match /\{"errors"\:\["Error dequeueing call\:.+\]\}/
        end

        it 'logs error' do
          Rails.logger.should_receive(:error) do |msg|
            expect(msg).to match /Error dequeueing call\:.+/
          end
          delete :front, csr_id: 5
        end
      end
    end
  end
end
