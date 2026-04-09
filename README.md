# FAIRNode

Docker image for running a FairCoin v3.0.0 full node.

Builds faircoind from source and runs it in a minimal Debian 12 container.

## Requirements

- Docker

## Quick Start

### Build the image

    git clone https://github.com/FairCoinOfficial/FAIRNode.git
    cd FAIRNode
    docker build -t faircoin-node .

### Run the node

    docker run -d \
      --name faircoin-node \
      --restart unless-stopped \
      -p 46372:46372 \
      -v faircoin-data:/home/faircoin/.faircoin \
      faircoin-node

On first run, the entrypoint generates a faircoin.conf with a random RPC password
and prints it to the logs:

    docker logs faircoin-node | head

### Verify the node is running

    docker exec -it faircoin-node faircoin-cli getinfo

## Configuration

### Use your own faircoin.conf

Mount a custom config file:

    docker run -d \
      --name faircoin-node \
      -p 46372:46372 \
      -v /path/to/your/faircoin.conf:/home/faircoin/.faircoin/faircoin.conf \
      -v faircoin-data:/home/faircoin/.faircoin \
      faircoin-node

### Expose the RPC port

By default only the P2P port (46372) is exposed. To allow RPC access from outside
the container, add -p 127.0.0.1:46373:46373 (bind to localhost only for security).

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

    # Run CLI commands
    docker exec -it faircoin-node faircoin-cli getinfo
    docker exec -it faircoin-node faircoin-cli getblockcount

    # Stop / start
    docker stop faircoin-node
    docker start faircoin-node

    # Remove (keeps data volume)
    docker rm -f faircoin-node

## Data Persistence

Blockchain data is stored in the faircoin-data Docker volume. To back it up:

    docker run --rm \
      -v faircoin-data:/data \
      -v $(pwd):/backup \
      alpine tar czf /backup/faircoin-backup.tar.gz -C /data .

## Links

- [FairCoin main repository](https://github.com/FairCoinOfficial/FairCoin)
- [FairCoin Explorer](https://github.com/FairCoinOfficial/Explorer)
- [Website](https://fairco.in)

## License

MIT
