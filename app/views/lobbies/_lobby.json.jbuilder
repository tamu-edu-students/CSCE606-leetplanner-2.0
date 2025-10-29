json.extract! lobby, :id, :owner_id, :description, :members, :lobby_code, :created_at, :updated_at
json.url lobby_url(lobby, format: :json)
