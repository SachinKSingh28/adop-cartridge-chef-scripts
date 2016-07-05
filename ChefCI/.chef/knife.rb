current_dir = File.dirname(__FILE__)

log_level               :info
log_location            STDOUT
chef_server_url         ENV["CHEF_SERVER_URL"]

client_key              "#{current_dir}/" + ENV["USERNAME"]+ ".pem"
node_name               ENV["USERNAME"]
validation_client_name  ENV["VALIDATOR"]
validation_key          "#{current_dir}/" + ENV["VALIDATOR"] + ".pem"

cookbook_path           ["#{current_dir}/../cookbooks"]
ssl_verify_mode         :verify_none
