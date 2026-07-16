# Service Deployment
- Run commands via Make to ensure correct context
- Runtime depends on some of these files for now

### Deploy Steps
- `git clone https://github.com/pterryt/acore-deploy.git $HOME/azerothcore`
- replace placeholders in env.dist files and remove .dist ending 
- add data files to **data/dev/** and **data/live/**
- (optional) `make gen-ssh` then add pub-key on remote platform
- `make init`
- `make build`
- `make install quadlets`
- `make start`

### Debugging
- `make logs-auth`
- `make logs-world-live`
- `make db console`
- `podman ps -a`
- `make help` for a list of all commands


### TODO
- remove all runtime dependence on deploy files so they can be removed after
- logs aren't being sent to /logs