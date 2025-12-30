# Fizzy

This is the source code of [Fizzy](https://fizzy.do/), the Kanban tracking tool for issues and ideas by [37signals](https://37signals.com).


## Running your own Fizzy instance

If you want to run your own Fizzy instance, but don't need to change its code, you can use our pre-built Docker image.
You'll need access to a server on which you can run Docker, and you'll need to configure some options to customize your installation.

You can find the details of how to do a Docker-based deployment in our [Docker deployment guide](docs/docker-deployment.md).

If you want more flexibility to customize your Fizzy installation by changing its code, and deploy those changes to your server, then we recommend you deploy Fizzy with Kamal. You can find a complete walkthrough of doing that in our [Kamal deployment guide](docs/kamal-deployment.md).

### Homelab Edition (Signups Disabled)

For users who want to host Fizzy privately (e.g., behind a Cloudflare Tunnel) without allowing public signups, there's a **Homelab Edition** available at `shawnschwartz/fizzy-homelab` (DockerHub) or `ghcr.io/shawntz/fizzy-homelab` (GitHub Container Registry). This variant has new account signups completely disabled for enhanced security in private deployments.

- **Multi-Architecture**: Supports both ARM64 and AMD64 (perfect for Raspberry Pi or standard servers)
- **Security-Focused**: Prevents unauthorized users from requesting signup emails
- **Homelab-Ready**: Designed for private, personal, or small team deployments

See the [Homelab Deployment Guide](docs/docker-homelab-deployment.md) for setup instructions.


## Development

You are welcome -- and encouraged -- to modify Fizzy to your liking.
Please see our [Development guide](docs/development.md) for how to get Fizzy set up for local development.


## Contributing

We welcome contributions! Please read our [style guide](STYLE.md) before submitting code.


## License

Fizzy is released under the [O'Saasy License](LICENSE.md).
