# FAIRNode

This repository contains the Docker setup for running a FairCoin node. FairCoin is a cryptocurrency that focuses on fairness and sustainability.

## Prerequisites

- Docker
- Docker Compose (optional, for managing multi-container Docker applications)

## Getting Started

### Clone the Repository

```sh
git clone https://github.com/FairCoinOfficial/FAIRNode.git
cd FAIRNode
```

### Build the Docker Image

```sh
docker build -t faircoin-node .
```

### Create Configuration File

Create a configuration file for the FairCoin node with the necessary RPC credentials and settings:

```sh
mkdir -p ~/.faircoin
echo "rpcuser=faircoinrpc" > ~/.faircoin/faircoin.conf
echo "rpcpassword=your_secure_password" >> ~/.faircoin/faircoin.conf
echo "server=1" >> ~/.faircoin/faircoin.conf
```

Replace `your_secure_password` with a strong, unique password.

### Run the Docker Container

```sh
docker run -d -p 53472:53472 -v ~/.faircoin:/root/.faircoin --name faircoin-node faircoin-node
```

This command will run the FairCoin node in a Docker container with the necessary ports exposed and configuration mounted.

### Verify Node is Running

You can verify that the node is running by checking the container logs:

```sh
docker logs -f faircoin-node
```

## Configuration

The configuration file `faircoin.conf` should be located in the `~/.faircoin` directory. You can customize this file with additional settings as needed. The default configuration includes:

```ini
rpcuser=faircoinrpc
rpcpassword=your_secure_password
server=1
```

## Troubleshooting

If you encounter any issues, please check the logs of the Docker container:

```sh
docker logs faircoin-node
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request with any improvements or fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- [FairCoin Official Repository](https://github.com/FairCoinOfficial/FairCoin)
- Docker
