
ApplicationRecord.transaction do
  puts "Seeding database..."
  puts "Destroying existing Lobbies and Lobby Members..."
  LobbyMember.destroy_all
  Lobby.destroy_all

  if User.count < 10
    puts "Creating sample users..."
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

  puts "Creating 5 random lobbies..."
  5.times do
    owner = users.sample
    lobby = Lobby.create!(
      name: "#{Faker::Hacker.adjective.capitalize} #{Faker::Hacker.noun.capitalize} Room",
      description: Faker::Hacker.say_something_smart,
      owner: owner
    )
    LobbyMember.create!(lobby: lobby, user: owner)
    other_members = users.where.not(id: owner.id).sample(rand(2..4))

    other_members.each do |member|
      LobbyMember.create!(lobby: lobby, user: member)
    end

    puts "  -> Created Lobby: '#{lobby.name}' with #{lobby.lobby_members.count} members. Owner: #{owner.full_name}."
  end

  puts "Seeding finished!"
end