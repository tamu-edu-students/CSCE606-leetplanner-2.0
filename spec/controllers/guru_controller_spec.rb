require 'rails_helper'

RSpec.describe GuruController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe 'authentication' do
    context 'when user is not signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'initializes chat session with welcome message' do
      get :index
      expect(session[:guru_chat_messages]).to be_present
      expect(session[:guru_chat_messages].first[:text]).to include('Hello! I\'m Guru')
      expect(session[:guru_chat_messages].first[:sender]).to eq('bot')
    end

    it 'cleans up empty messages' do
      session[:guru_chat_messages] = [
        { text: 'Hello', sender: 'user', timestamp: '10:00' },
        { text: '', sender: 'bot', timestamp: '10:01' },
        { text: 'Test', sender: 'user', timestamp: '10:02' }
      ]
      get :index
      expect(assigns(:chat_messages).length).to eq(2)
      expect(assigns(:chat_messages).any? { |msg| msg[:text].blank? }).to be_falsey
    end

    it 'does not add duplicate welcome messages' do
      session[:guru_chat_messages] = [
        { text: 'Existing message', sender: 'user', timestamp: '10:00' }
      ]
      get :index
      expect(session[:guru_chat_messages].length).to eq(1)
    end
  end

  describe 'POST #create_message' do
    context 'with valid message' do
      it 'adds user message to session' do
        post :create_message, params: { message: 'Hello Guru' }
        messages = session[:guru_chat_messages]
        user_message = messages.find { |msg| msg[:sender] == 'user' && msg[:text] == 'Hello Guru' }
        expect(user_message).to be_present
      end

      it 'generates bot response' do
        post :create_message, params: { message: 'Hello' }
        messages = session[:guru_chat_messages]
        bot_messages = messages.select { |msg| msg[:sender] == 'bot' }
        expect(bot_messages.length).to be >= 2 # welcome + response
      end

      it 'redirects to guru path' do
        post :create_message, params: { message: 'Hello' }
        expect(response).to redirect_to(guru_path)
      end

      it 'handles leetcode related questions' do
        post :create_message, params: { message: 'Help with leetcode' }
        messages = session[:guru_chat_messages]
        bot_response = messages.last
        expect(bot_response[:text]).to be_present
      end

      it 'handles calendar related questions' do
        post :create_message, params: { message: 'Help with calendar' }
        messages = session[:guru_chat_messages]
        bot_response = messages.last
        expect(bot_response[:text]).to be_present
      end

      it 'handles help requests' do
        post :create_message, params: { message: 'I need help' }
        messages = session[:guru_chat_messages]
        bot_response = messages.last
        expect(bot_response[:text]).to include('help you')
      end

      it 'provides default response for unknown messages' do
        post :create_message, params: { message: 'Random question' }
        messages = session[:guru_chat_messages]
        bot_response = messages.last
        expect(bot_response[:text]).to include('interesting question')
      end
    end

    context 'with invalid message' do
      it 'redirects with error for empty message' do
        post :create_message, params: { message: '' }
        expect(flash[:error]).to eq('Message cannot be empty')
        expect(response).to redirect_to(guru_path)
      end

      it 'redirects with error for blank message' do
        post :create_message, params: { message: '   ' }
        expect(flash[:error]).to eq('Message cannot be empty')
        expect(response).to redirect_to(guru_path)
      end

      it 'redirects with error for nil message' do
        post :create_message
        expect(flash[:error]).to eq('Message cannot be empty')
        expect(response).to redirect_to(guru_path)
      end
    end

    it 'limits session to 50 messages' do
      # Fill session with 49 messages
      session[:guru_chat_messages] = (1..49).map do |i|
        { text: "Message #{i}", sender: 'user', timestamp: '10:00' }
      end

      post :create_message, params: { message: 'New message' }
      expect(session[:guru_chat_messages].length).to eq(50)
    end
  end

  describe 'DELETE #clear_chat' do
    it 'clears chat messages' do
      session[:guru_chat_messages] = [
        { text: 'Test message', sender: 'user', timestamp: '10:00' }
      ]
      delete :clear_chat
      expect(session[:guru_chat_messages]).to be_empty
    end

    it 'sets success flash message' do
      delete :clear_chat
      expect(flash[:notice]).to eq('Chat history cleared')
    end

    it 'redirects to guru path' do
      delete :clear_chat
      expect(response).to redirect_to(guru_path)
    end
  end

  describe 'private methods' do
    describe '#add_message_to_session' do
      it 'does not add empty messages' do
        controller.send(:add_message_to_session, '', 'user')
        expect(session[:guru_chat_messages] || []).to be_empty
      end

      it 'strips whitespace from messages' do
        controller.send(:add_message_to_session, '  Hello  ', 'user')
        message = session[:guru_chat_messages].first
        expect(message[:text]).to eq('Hello')
      end

      it 'adds timestamp to messages' do
        controller.send(:add_message_to_session, 'Hello', 'user')
        message = session[:guru_chat_messages].first
        expect(message[:timestamp]).to match(/\d{2}:\d{2}/)
      end
    end

    describe '#generate_response' do
      it 'responds to greetings' do
        response = controller.send(:generate_response, 'Hello')
        expect(response).to include('Hello!')
      end

      it 'is case insensitive' do
        response = controller.send(:generate_response, 'HELLO')
        expect(response).to include('Hello!')
      end
    end
  end
end
