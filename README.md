# Cluster Headache Tracker


## Development setup
### MacOS

    mise use -g ruby
    brew install postgresql 1password-cli
    brew services start postgresql@14
    op vault create cluster_headache_tracker
    op item create --vault=cluster_headache_tracker --category=login --title="local pg" --generate-password username=cluster_headache_tracker
    echo "export CLUSTER_HEADACHE_TRACKER_DATABASE_PASSWORD=\"$(op item get "local pg" --vault "cluster_headache_tracker" --fields label=password)\"" >> .envrc
    direnv allow
    createuser -P -d cluster_headache_tracker
    rails db:create
    rails db:migrate

