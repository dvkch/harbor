<img src="Resources/README-AppIcon.png" width=64 />

# Harbor

Just another CLI tool to easily access Docker Composer containers, Docker Swarm services and K3s pods via SSH.

The idea is to replicate some abilities of the `Heroku CLI` tool but for self hosted stacks.

### Config

The configuration file should reside in `~/.config/harbor.json`, and formatted as is : 

```json5
{
  "environments": [
    {
      "name": "My VPS",          // name used when displaying a list of available envs
      "alias": "vps",            // alias to be used when passing the env as an argument
      "host": "vps.example.com", // the actual host
      "port": 2200,              // port, defaults to 22 if missing
      "user": "ubuntu",          // user, defaults to root if missing 
      "provider": "swarm",       // stack used, possible values are `compose`, `swarm` or `k3s` for now
      "nodes": {                 // list the correspondances of node name -> host (used for swarm)
        "node1": "vps.example.com",
        "node2": "vps-secondary.example.com",
      }
    },
    ...
  ]
}
```

### Usage

```bash
OVERVIEW: Harbor

USAGE: harbor <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  stats                   Obtain container stats for an environment
  exec                    Run a command on a given docker service
  logs                    Show log stream for a docker service
  reload                  Restart a service
  db-backup               Download a backup of the DB
  docker-init             Create default files for Docker deployment
  completion              Update harbor completion scripts

  See 'harbor help <subcommand>' for detailed help.
```

### Building

The simplest way to build this is to run `swift build`.

To generate packages for macOS and Linux containing the main executable and resources, you can run `./build.sh release`.

