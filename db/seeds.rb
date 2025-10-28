ApplicationRecord.transaction do
  puts "Seeding database..."

  puts "Destroying existing Lobbies and Lobby Members..."
  LobbyMember.destroy_all
  Lobby.destroy_all

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

  main_user = User.find_or_create_by!(email: 'shreya.sahni@tamu.edu') do |user|
    user.first_name = 'Shreya'
    user.last_name = 'Sahni'
    user.netid = 'shreya_x'
  end

  puts "Creating 2 lobbies where '#{main_user.full_name}' is the host..."
  2.times do
    lobby = Lobby.create!(
      name: "#{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.noun.capitalize}",
      description: "A private study session hosted by #{main_user.first_name}.",
      owner: main_user
    )
    # Add the owner as a member
    LobbyMember.create!(lobby: lobby, user: main_user)
    # Add a few other random members
    other_members = users.where.not(id: main_user.id).sample(rand(1..3))
    other_members.each { |member| LobbyMember.create!(lobby: lobby, user: member) }

    puts "  -> Created Hosted Lobby: '#{lobby.name}' with #{lobby.lobby_members.count} members."
  end

  puts "Creating 2 lobbies where '#{main_user.full_name}' is a participant..."
  hosts = User.where.not(id: main_user.id).sample(2)
  if hosts.length < 2
    puts "  -> Not enough other users to act as hosts."
  else
    hosts.each_with_index do |host, index|
      lobby = Lobby.create!(
        name: "Project #{index + 1}: #{Faker::Company.bs.capitalize}",
        description: "A collaborative session for advanced algorithms.",
        owner: host
      )
      LobbyMember.create!(lobby: lobby, user: host)
      LobbyMember.create!(lobby: lobby, user: main_user) # Add main user as participant

      puts "  -> Created Participant Lobby: '#{lobby.name}'. Host: #{host.full_name}."
    end
  end

  puts "Seeding finished!"
end
