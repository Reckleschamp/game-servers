ARK: Survival Ascended Dedicated Server

A Docker container for running ARK: Survival Ascended dedicated servers with a focus on Unraid, persistent storage, non-root operation, RCON support, and multi-map clustering.

Table of Contents

- [Features](#Features)
- [QuickStart](#Quick Start)
- [Requirements](#Requirements)
- [Ports](#Ports)
- [INIConfiguration](#INI Configuration)
- [Maps](#Maps)
- [Mods](#Mods)
- [Extra Server Arguments](#Extra Server Arguments)
- [RCON](#RCON)
- [Clustering](#Clustering)
- [Updating](#Updating)
- [Backups](#Backups)
- [Troubleshooting](#Troubleshooting)

  

## Features

- ARK: Survival Ascended dedicated server running through Proton
- Automatic ASA installation through SteamCMD
- Optional server validation
- Persistent server files, saves, configuration, logs, and Proton prefix
- RCON support
- Graceful server shutdown
- Multi-map cluster support
- Mod support
- Custom server startup arguments

  

## Quick Start

Install the container using the Unraid Community Applications template and configure the required server options.

At minimum, configure:

- Server name
- Map
- Game port
- RCON port
- Admin password
- Server data path
- Cluster data path and Cluster ID if clustering servers

Start the container. On the first startup, SteamCMD downloads the ARK: Survival Ascended dedicated server files and Proton initializes the server environment.

The initial startup will take considerably longer than subsequent starts.

## Requirements

Memory Mapping Configuration

`vm.max_map_count`

The vm.max_map_count parameter MUST be increased to at least 262144!

You have two methods to apply this setting:

Temporary Setting (resets after system reboot):
```bash sudo sysctl -w vm.max_map_count=262144```

    Permanent Setting:

```bash echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf sudo sysctl -p```
Storage

Each server instance maintains its own ARK server installation, saves, configuration, logs, and Proton prefix.

At least 25GB of storage on a unmodded server is recommended to allow room for updates and world saves.

Memory

Memory requirements vary considerably by map, mods, player count, structures, and world activity. Have around 20GB per map available.

## Ports

Each server instance requires its own game port UDP.
RCON requires a separate port when enabled TCP.

When running multiple ASA containers on the same host, each instance must use unique ports.
Only expose or forward ports that are actually required for your configuration, you do not need to open the rcon port on your firewall to use an rcon client thats on the same network.

When deploying the template you need to add the additional UDP port mapping to match the game port the Host,Container and Game port must all match.

  
## INI Configuration

The ini files are located under

```server/ShooterGame/Saved/Config/WindowsServer/```

The primary configuration files are:

```GameUserSettings.ini```

```Game.ini```

Edit these files while the server is stopped!

## Maps

Set the desired map using the map setting in the container configuration.

Official map names
```TheIsland_WP```
```ScorchedEarth_WP```
```TheCenter_WP```
```Aberration_WP```
```Extinction_WP```
```Ragnarok_WP```
```Valguero_WP```
```Astraeos_WP```
```LostColony_WP```
```Genesis_WP```

Servers intended to participate in the same cluster must use the same Cluster ID and shared cluster directory.

## Mods

ARK: Survival Ascended supports CurseForge mods.

Configure the desired mod IDs using the server’s supported mod startup arguments.

Multiple mods should be specified using the format expected by ARK: Survival Ascended.

Always verify mod compatibility after ASA or mod updates.

## Extra Server Arguments

Additional ARK startup arguments can be supplied through the Extra Server Arguments setting.

This provides access to ARK options that are not individually exposed through the Unraid template.

Example:

-servergamelog
-ForceAllowCaveFlyers
-ForceRespawnDinos

Check the wiki for available Arguments.

## RCON

RCON can be enabled through the container configuration.

To run rcon commands through the console simply type ```asa raw <command>``` for example ```asa raw destroywilddinos``` some commands have shortcuts such as ```asa players``` to list connected players for a list of current shortcuts just type ```asa ``` in the console.

## Clustering

Multiple ASA containers can participate in the same ARK cluster.

Each map requires:

- Its own container
- Its own server data directory
- Its own game port
- Its own RCON port

All servers in the cluster must use:

- The same Cluster ID. Do use the default "cluster1" choose a unique ID.
- The same shared cluster directory

Example:

Island

/data    -> /mnt/user/appdata/asa-island

Astraeos

/data    -> /mnt/user/appdata/asa-astraeos

Both servers

/cluster -> /mnt/user/appdata/asa-cluster

The server installations and world saves remain separate. Only the ARK cluster-transfer data is shared.

## Updating

When automatic server updates are enabled, SteamCMD checks the ARK: Survival Ascended dedicated server installation during container startup.

Always maintain backups of important server data before major ARK updates.

## Backups

ARK generates save and backup data within its persistent server directories.

For full disaster recovery, back up the server’s persistent data and cluster directory.

## Troubleshooting

Server does not start

Check:

- Available memory
- Available disk space
- File permissions
- vm.max_map_count
- Map name
- Startup arguments
- Container logs
- ASA logs

Server is not discoverable

Verify:

- Game port configuration
- Docker port mapping
- Router/firewall configuration
- Server startup completed successfully

RCON does not connect

Verify:

- RCON is enabled
- RCON port is correct
- TCP port mapping is correct
- Admin password is configured
- ASA has completed startup

Permission problems

The server is designed to run its game processes without root privileges.

Avoid manually deleting bind-mounted host directories while an existing container is configured to use them. Docker may recreate a missing bind-mount source directory with root ownership.
  
