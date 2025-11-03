Rails.application.routes.draw do
  # Root page
  root "login#index"

  # -------------------------------
  # Authentication / Sessions
  # -------------------------------
  get "/login/google",          to: redirect("/auth/google_oauth2")
  post "/login/dev_bypass",     to: "login#dev_bypass"  # Development login
  get "/auth/:provider/callback", to: "sessions#create"
  get "sessions/create", to: "sessions#create", as: "sessions_create"
  get "/auth/failure",          to: "sessions#failure", as: "sessions_failure"
  delete "/logout",             to: "sessions#destroy"
  get "/debug/session",         to: "sessions#debug"

  # -------------------------------
  # Dashboard, Calendar, Timer
  # -------------------------------
  get "dashboard", to: "dashboard#show", as: "dashboard"
  get "/calendar",              to: "calendar#show"
  post "/calendar/sync",        to: "calendar#sync", as: "sync_calendar"
  get "/calendar/add",          to: "calendar#new", as: "add_calendar_event"
  get "/calendar/:id/edit",     to: "calendar#edit", as: "edit_calendar_event"

  get "/timer",                 to: "timer#show"
  post "/create_timer",         to: "dashboard#create_timer"

  # -------------------------------
  # Profile / User
  # -------------------------------
  get "/profile",               to: "users#profile", as: :profile
  patch "/profile",             to: "users#profile"
  resources :users, only: [ :show, :update ]

  # -------------------------------
  # LeetCode Features
  # -------------------------------
  get "/leetcode",              to: "leet_code_problems#index"

  resources :leet_code_problems, except: [ :new, :edit ]
  resources :leet_code_sessions, except: [ :new, :edit ] do
    post :add_problem, on: :collection
  end
  resources :leet_code_session_problems, except: [ :new, :edit ]

  resource  :statistics, only: [ :show ], controller: "statistics"

  # -------------------------------
  # Lobby Features with Whiteboard
  # -------------------------------
  resources :lobbies do
    resources :whiteboards, only: [] do
      collection do
        post :add_drawing
        post :clear
        post :update_svg
        patch :update_notes
        get :show
      end
    end
  end
  post "join_lobby", to: "lobby_members#create_by_code", as: :join_lobby
  delete "leave_lobby/:id", to: "lobby_members#destroy", as: :leave_lobby
  resources :lobby_members, only: [] do
    patch "permissions", on: :member, to: "lobby_permissions#update", as: :update_permissions
  end
  patch "lobbies/:id/update_all_permissions", to: "lobby_permissions#update_all", as: :update_all_lobby_permissions

  resources :lobbies do
    resource :note, only: [ :show, :edit, :update ]
    resources :messages, only: [ :index, :create ]
  end

  # -------------------------------
  # API Namespace
  # -------------------------------
  namespace :api do
    get "current_user", to: "users#profile"

    # Calendar Events CRUD
    get    "calendar_events",     to: "calendar#events",   as: "calendar_events"
    post   "calendar_events",     to: "calendar#create"
    patch  "calendar_events/:id", to: "calendar#update",   as: "calendar_event"
    delete "calendar_events/:id", to: "calendar#destroy"
  end

  # -------------------------------
  # Health Check & Favicon
  # -------------------------------
  get "up", to: "rails/health#show", as: :rails_health_check
  get "favicon.ico", to: proc { [ 204, {}, [] ] }

  # Test-only helpers
  if Rails.env.test?
    get "/test/clear_session", to: "test_helpers#clear_session"
    get "/test/clear_session_with_alert", to: "test_helpers#clear_session_with_alert"
    get "/test/clear_timer", to: "test_helpers#clear_timer"
    get "/test/set_timer", to: "test_helpers#set_timer"
    get "/test/login_as", to: "test_helpers#login_as"
  end
end
