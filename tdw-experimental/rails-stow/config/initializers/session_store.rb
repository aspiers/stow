# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails-stow_session',
  :secret      => '15a044fe6a00f200cbedc8c83ca2f68f93b1efa5e61e5262aecb7b405cce783b97e342942af24cfa9b6f741ba6424179d9609ed888bf54073e6141fd055bfe4e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
