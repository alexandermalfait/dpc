# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_DPC_session',
  :secret      => 'f976495dea6ae0fe879a8fbf421b10c21e7780bb8923b8c44a374cd6612c971fa6d99038886d88845edb5e52211be2e122dfd835a6c647f61dbc05d7db9000f2'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
