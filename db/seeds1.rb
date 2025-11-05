require 'faker'
require 'securerandom'

ApplicationRecord.transaction do
  puts "Seeding database..."

  puts "Destroying existing Lobbies, Lobby Members, and Notes..."
  Note.destroy_all
  LobbyMember.destroy_all
  Lobby.destroy_all

  # Clear Faker unique generators to avoid collision on rerun
  Faker::UniqueGenerator.clear

  # Ensure at least 10 users
  if User.count < 10
    puts "Creating 10 sample users..."
    10.times do
      User.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.unique.email,
        netid: Faker::Internet.unique.username(specifier: 5..8)
      )
    end
  end
  users = User.all

  # Main user
  main_user = User.find_or_create_by!(email: 'shmishra@tamu.edu') do |user|
    user.first_name = 'Shivam'
    user.last_name = 'Mishra'
    user.netid = 'shmishra_x'
  end

  # --- 1. Lobbies where main_user is host ---
  puts "Creating 2 lobbies where '#{main_user.full_name}' is the host..."
  2.times do
    lobby_name = "#{Faker::Hacker.unique.verb.capitalize} the #{Faker::Hacker.unique.noun.capitalize}-#{SecureRandom.hex(2)}"
    lobby = Lobby.create!(
      name: lobby_name,
      description: "A private study session hosted by #{main_user.first_name}.",
      owner: main_user
    )

    # Add main_user as member with full permissions
    LobbyMember.create!(
      lobby: lobby,
      user: main_user,
      can_draw: true,
      can_edit_notes: true,
      can_speak: true
    )

    # Add other random members with random permissions
    other_members = users.where.not(id: main_user.id).sample(rand(1..3))
    other_members.each do |member|
      LobbyMember.create!(
        lobby: lobby,
        user: member,
        can_draw: [ true, false ].sample,
        can_edit_notes: [ true, false ].sample,
        can_speak: [ true, false ].sample
      )
    end

    # --- FIX 1 ---
    # Create ONE note for the lobby, associated with the host (who can always edit)
    # This is now *outside* the member loop.
    Note.create!(
      lobby: lobby,
      user: main_user,
      content: Faker::Lorem.paragraph(sentence_count: 2)
    )

    puts "  -> Created Hosted Lobby: '#{lobby.name}' with #{lobby.lobby_members.count} members."
  end

  # --- 2. Lobbies where main_user is participant ---
  puts "Creating 2 lobbies where '#{main_user.full_name}' is a participant..."
  hosts = users.where.not(id: main_user.id).sample(2)
  if hosts.length < 2
    puts "  -> Not enough other users to act as hosts."
  else
    hosts.each_with_index do |host, index|
      lobby_name = "Project #{index + 1}: #{Faker::Company.unique.bs.capitalize}-#{SecureRandom.hex(2)}"
      lobby = Lobby.create!(
        name: lobby_name,
        description: "A collaborative session for advanced algorithms.",
        owner: host
      )

      LobbyMember.create!(
        lobby: lobby,
        user: host,
        can_draw: true,
        can_edit_notes: true,
        can_speak: true
      )

      LobbyMember.create!(
        lobby: lobby,
        user: main_user,
        can_draw: [ true, false ].sample,
        can_edit_notes: [ true, false ].sample,
        can_speak: [ true, false ]
      )

      # --- FIX 2 ---
      # Create ONE note for the lobby, associated with the host.
      # This logic is now separate from member creation.
      Note.create!(
        lobby: lobby,
        user: host, # Associate note with the host
        content: Faker::Lorem.paragraph(sentence_count: 2)
      )

      puts "  -> Created Participant Lobby: '#{lobby.name}'. Host: #{host.full_name}."
    end
  end

  # --- 3. Special lobby: Cristiano Ronaldo as host, main_user can_edit_notes: true ---
  puts "Creating special lobby with host Cristiano Ronaldo..."
  cr_user = User.find_or_create_by!(email: 'cronaldo@example.com') do |user|
    user.first_name = 'Cristiano'
    user.last_name = 'Ronaldo'
    user.netid = 'cronaldo'
  end

  special_lobby_name = "Soccer Strategies: Champions-#{SecureRandom.hex(2)}"
  special_lobby = Lobby.create!(
    name: special_lobby_name,
    description: "A special session hosted by Cristiano Ronaldo.",
    owner: cr_user
  )

  # Host with full permissions
  LobbyMember.create!(
    lobby: special_lobby,
    user: cr_user,
    can_draw: true,
    can_edit_notes: true,
    can_speak: true
  )

  # main_user as participant with can_edit_notes = true
  LobbyMember.create!(
    lobby: special_lobby,
    user: main_user,
    can_draw: true,
    can_edit_notes: true,
    can_speak: true
  )

  # Create note for main_user
  # This block was already correct, as it only creates one note.
  Note.create!(
    lobby: special_lobby,
    user: main_user,
    content: "This is a pre-filled note for Shivam in Cristiano's session."
  )

  puts "  -> Created special lobby '#{special_lobby.name}' with host Cristiano Ronaldo and main_user as editor."

  puts "Seeding finished!"
end
