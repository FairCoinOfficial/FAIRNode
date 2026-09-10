# FAIRNode

Docker image for running a FairCoin v3.0.0 node.

Builds `faircoind` from source and runs it in a minimal Debian 12 container.
On first run it welcomes you and lets you pick a **role** — the same idea as the
desktop app, but headless and driven by an environment variable (or an
interactive prompt).

## Requirements

- Docker

## Choose your role

Every role runs the **same** `faircoind` daemon; only the configuration differs.
Pick the one that matches how you want to participate in the FairCoin network:

| Role | What it does | Extra requirements |
|------|--------------|--------------------|
| **node** *(default)* | Relays and validates blocks/transactions to support the network. | None. |
| **staker** | A node with the wallet enabled and **staking on**, so it can produce Proof-of-Stake blocks and earn staking rewards. | Wallet must hold coins; if encrypted it must be unlocked for staking. |
| **masternode** | A node that provides masternode services and earns masternode rewards, backed by **5,000 FAIR** collateral (refundable — you keep the coins). | A masternode private key, a public IP, and the 5,000 FAIR collateral set up from a controlling wallet. |

Select the role with the `FAIRNODE_ROLE` environment variable:

    FAIRNODE_ROLE=node        # default
    FAIRNODE_ROLE=staker
    FAIRNODE_ROLE=masternode

If you start the container **interactively** (a TTY attached) and do **not** set
`FAIRNODE_ROLE`, the entrypoint prints a short welcome and asks you to choose
`1` (node), `2` (staker) or `3` (masternode). If there is no TTY and no role is
set, it defaults to `node` and logs the choice.

## Quick Start

### Build the image

    git clone https://github.com/FairCoinOfficial/FAIRNode.git
    cd FAIRNode
    docker build -t faircoin-node .

### Run a node (default role)

    docker run -d \
      --name faircoin-node \
      --restart unless-stopped \
      -e FAIRNODE_ROLE=node \
      -p 46372:46372 \
      -v faircoin-data:/home/faircoin/.faircoin \
      faircoin-node

On first run the entrypoint generates a role-specific `faircoin.conf` with a
random RPC user and password (file permissions `600`). The credentials are kept
inside the config file and are **not** printed to the logs. View the startup
logs with:

    docker logs faircoin-node

To choose a role interactively instead, run with `-it` and omit `FAIRNODE_ROLE`:

    docker run -it --rm \
      -p 46372:46372 \
      -v faircoin-data:/home/faircoin/.faircoin \
      faircoin-node

### Verify the node is running

`faircoin-cli` reads the generated config from the data directory, so point it
at the same datadir:

    docker exec -it faircoin-node faircoin-cli -datadir=/home/faircoin/.faircoin getinfo
    docker exec -it faircoin-node faircoin-cli -datadir=/home/faircoin/.faircoin getblockcount

## Roles in detail

### Staker

Run with `FAIRNODE_ROLE=staker`. The generated config keeps the wallet enabled
and adds `staking=1`.

    docker run -d \
      --name faircoin-staker \
      --restart unless-stopped \
      -e FAIRNODE_ROLE=staker \
      -p 46372:46372 \
      -v faircoin-staker-data:/home/faircoin/.faircoin \
      faircoin-node

For the node to actually stake:

1. Make sure the wallet holds spendable, mature FAIR.
2. If the wallet is **encrypted**, unlock it for staking only (the `true`
   argument means "unlock for staking, not spending"):

       docker exec -it faircoin-staker \
         faircoin-cli -datadir=/home/faircoin/.faircoin walletpassphrase <your-passphrase> 0 true

   `0` means the wallet stays unlocked until the daemon stops. You must repeat
   this after every restart.

3. Check staking status:

       docker exec -it faircoin-staker \
         faircoin-cli -datadir=/home/faircoin/.faircoin getstakingstatus

### Masternode

Run with `FAIRNODE_ROLE=masternode`. This role **requires** two environment
variables; the container refuses to start without them:

| Variable | Meaning |
|----------|---------|
| `MN_PRIVKEY` | The masternode private key produced by `masternode genkey`. |
| `EXTERNAL_IP` | The public IP address other nodes use to reach this masternode. |

The generated config adds `masternode=1`, `masternodeprivkey=${MN_PRIVKEY}`,
`externalip=${EXTERNAL_IP}` and `masternodeaddr=${EXTERNAL_IP}:46372`.

    docker run -d \
      --name faircoin-masternode \
      --restart unless-stopped \
      -e FAIRNODE_ROLE=masternode \
      -e MN_PRIVKEY=<your-masternode-privkey> \
      -e EXTERNAL_IP=<your-public-ip> \
      -p 46372:46372 \
      -v faircoin-mn-data:/home/faircoin/.faircoin \
      faircoin-node

#### Full masternode setup (controlling wallet)

A masternode has two halves: the **remote node** (this container) and a
**controlling wallet** that holds the 5,000 FAIR collateral. The collateral
stays in your wallet — it is locked as proof, not spent.

Do these steps in the controlling wallet (a separate, funded FairCoin wallet —
e.g. the desktop wallet or another `faircoind` you control):

1. **Generate the masternode key** (this is the value you pass as `MN_PRIVKEY`):

       faircoin-cli masternode genkey

2. **Send exactly 5,000 FAIR** to a new address in the controlling wallet, in a
   single transaction. Wait for **15 confirmations**.

3. **Find the collateral output** (its txid and output index):

       faircoin-cli masternode outputs

4. **Add a masternode.conf line** in the controlling wallet's data directory
   (`masternode.conf`, one masternode per line):

       <alias> <EXTERNAL_IP>:46372 <MN_PRIVKEY> <collateral-txid> <output-index>

   Example:

       mn1 203.0.113.7:46372 93Hk...your-mn-privkey... f00d...txid... 0

5. **Start this container** with `FAIRNODE_ROLE=masternode`, `MN_PRIVKEY` and
   `EXTERNAL_IP` set (see the `docker run` above). Let it fully sync.

6. **Activate the masternode** from the controlling wallet:

       faircoin-cli masternode start-alias <alias>

7. **Check status** on the remote node (this container):

       docker exec -it faircoin-masternode \
         faircoin-cli -datadir=/home/faircoin/.faircoin masternode status

   A healthy masternode reports a status such as
   `Masternode successfully started`.

## docker-compose

A ready-to-edit [`docker-compose.yml`](docker-compose.yml) is included with one
service per role. Copy [`.env.example`](.env.example) to `.env` and fill in the
masternode values before starting that profile.

    cp .env.example .env

Run a single role using compose profiles:

    # Plain node
    docker compose --profile node up -d

    # Staker
    docker compose --profile staker up -d

    # Masternode (requires MN_PRIVKEY and EXTERNAL_IP in .env)
    docker compose --profile masternode up -d

Minimal node service:

```yaml
services:
  faircoin-node:
    build: .
    image: faircoin-node
    restart: unless-stopped
    environment:
      FAIRNODE_ROLE: node
    ports:
      - "46372:46372"
    volumes:
      - faircoin-data:/home/faircoin/.faircoin

volumes:
  faircoin-data:
```

Masternode service:

```yaml
services:
  faircoin-masternode:
    build: .
    image: faircoin-node
    restart: unless-stopped
    environment:
      FAIRNODE_ROLE: masternode
      MN_PRIVKEY: ${MN_PRIVKEY}
      EXTERNAL_IP: ${EXTERNAL_IP}
    ports:
      - "46372:46372"
    volumes:
      - faircoin-mn-data:/home/faircoin/.faircoin

volumes:
  faircoin-mn-data:
```

## Configuration

### Use your own faircoin.conf

If you mount your own `faircoin.conf`, the entrypoint detects it and leaves it
untouched (it will not overwrite your settings or your role). Role-based
generation only happens when no config file exists yet.

    docker run -d \
      --name faircoin-node \
      -p 46372:46372 \
      -v /path/to/your/faircoin.conf:/home/faircoin/.faircoin/faircoin.conf \
      -v faircoin-data:/home/faircoin/.faircoin \
      faircoin-node

To regenerate the config for a different role, delete the existing
`faircoin.conf` (or the data volume) and restart.

### Generated base configuration

Every role starts from this base (all FairCoin v3.0.0 mainnet defaults):

    server=1
    listen=1
    port=46372
    maxconnections=64
    rpcbind=127.0.0.1
    rpcallowip=127.0.0.1
    rpcuser=<random>
    rpcpassword=<random>
    maxtipage=315360000

`maxtipage=315360000` is included deliberately: without a large max tip age a
FairCoin v3 node can get stuck in initial-block-download on an old tip. DNS
seeds (`seed1.fairco.in`, `seed2.fairco.in`) are built into the daemon, so no
`addnode` entries are required.

### RPC access

RPC is bound to `127.0.0.1` inside the container only. Use `faircoin-cli` via
`docker exec` (shown above) rather than exposing the RPC port. If you have a
specific need to reach RPC from the host, prefer an SSH tunnel or a localhost
port bind; do not expose RPC to the public internet.

## Network Parameters

| | |
|---|---|
| Mainnet P2P port | 46372 |
| Mainnet RPC port | 46373 |
| Testnet P2P port | 46374 |
| Testnet RPC port | 46375 |

## Commands

    # View logs
    docker logs -f faircoin-node

    # Run CLI commands (point at the data dir)
    docker exec -it faircoin-node faircoin-cli -datadir=/home/faircoin/.faircoin getinfo
    docker exec -it faircoin-node faircoin-cli -datadir=/home/faircoin/.faircoin getblockcount

    # Stop / start
    docker stop faircoin-node
    docker start faircoin-node

    # Remove (keeps data volume)
    docker rm -f faircoin-node

## Data Persistence

Blockchain data, the wallet, and the generated `faircoin.conf` live in the data
volume mounted at `/home/faircoin/.faircoin`. To back it up:

    docker run --rm \
      -v faircoin-data:/data \
      -v "$(pwd)":/backup \
      alpine tar czf /backup/faircoin-backup.tar.gz -C /data .

Note: the backup includes `faircoin.conf` and, for stakers/masternodes, wallet
keys. Store it securely.

## Links

- [FairCoin main repository](https://github.com/FairCoinOfficial/FairCoin)
- [FairCoin Explorer](https://github.com/FairCoinOfficial/Explorer)
- [Website](https://fairco.in)

## License

MIT
