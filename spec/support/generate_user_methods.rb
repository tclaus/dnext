# frozen_string_literal: true

# @return [User]
def alice
  @alice ||= User.find_by(username: "alice")
end

# @return [User]
def bob
  @bob ||= User.find_by(username: "bob")
end

# @return [User]
def eve
  @eve ||= User.find_by(username: "eve")
end

# @return [User]
def local_luke
  @local_luke ||= User.find_by(username: "luke")
end

# @return [User]
def local_leia
  @local_leia ||= User.find_by(username: "leia")
end

# @return [User]
def remote_raphael
  @remote_raphael ||= Person.find_by(diaspora_handle: "raphael@remote.net")
end

# @return [User]
def peter
  @peter ||= User.find_by(username: "peter")
end
