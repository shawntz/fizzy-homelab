## Deploying Fizzy Homelab Edition with Docker

This is a modified version of Fizzy designed specifically for homelab deployments where you want to prevent unauthorized signups. Unlike the standard Fizzy deployment, **new account signups are completely disabled** in this version, making it ideal for personal or private deployments behind Cloudflare tunnels or similar setups.

### Key Differences from Standard Fizzy

- **Signups Disabled**: New users cannot request magic link signup emails, even if no accounts exist yet
- **Multi-Architecture Support**: Pre-built images available for both ARM64 (e.g., Raspberry Pi, Apple Silicon) and AMD64 architectures
- **Security-Focused**: Designed for deployments where you want complete control over who can access your instance

### Quick Start

We provide pre-built multi-architecture Docker images available from two registries:
- **DockerHub**: `shawnschwartz/fizzy-homelab:latest`
- **GitHub Container Registry**: `ghcr.io/shawntz/fizzy-homelab:latest`

To run it you'll need three things:
- A machine that runs Docker (supports both ARM64 and AMD64 architectures)
- A mounted volume (so that your database is stored somewhere that is kept around between restarts)
- Environment variables for configuration

### Mounting a storage volume

The standard Fizzy setup keeps all of its storage inside the path `/rails/storage`.
By default Docker containers don't persist storage between runs, so you'll want to mount a persistent volume into that location.

The simplest way to do this is with the `--volume` flag with `docker run`. For example:

```sh
docker run --volume fizzy-homelab:/rails/storage shawnschwartz/fizzy-homelab:latest
# or use GitHub Container Registry
docker run --volume fizzy-homelab:/rails/storage ghcr.io/shawntz/fizzy-homelab:latest
```

That will create a named volume (called `fizzy-homelab`) and mount it into the correct path.
Docker will manage where that volume is actually stored on your server.

You can also specify the data location yourself, mount a network drive, and more.
Check the Docker documentation to find out more about what's available.

### Creating Your First Account

Since signups are disabled, you'll need to create your first account manually using the Rails console:

1. Start your container:
```sh
docker run -it --rm \
  --volume fizzy-homelab:/rails/storage \
  --environment SECRET_KEY_BASE=your-secret-key-here \
  --environment DISABLE_SSL=true \
  shawnschwartz/fizzy-homelab:latest \
  bin/rails console
```

2. In the Rails console, create an account and user:
```ruby
# Create an identity (email-based global user)
identity = Identity.create!(email_address: "your-email@example.com")

# Create an account (organization/tenant)
account = Account.create!(name: "My Homelab")

# Create a user linking the identity to the account with owner role
user = account.users.create!(
  identity: identity,
  role: :owner,
  name: "Your Name"
)

# Generate a magic link for first login
puts "Login URL: #{Rails.application.routes.url_helpers.new_session_magic_link_url(
  token: MagicLink.create_session_token!(identity).token,
  host: 'your-domain.com'
)}"
```

3. Use the generated login URL to access your instance

### Configuring with environment variables

To configure your Fizzy installation, you can use environment variables.
Many of these are optional, but at a minimum you'll want to configure your secret key, your domain/SSL settings, and your SMTP email settings.

#### Secret Key Base

Various features inside Fizzy rely on cryptography to work (such as secure links).
To set this up, you need to provide a secret value that will be used as the basis of those secrets.
This value can be anything, but it should be unguessable, and specific to your instance.

You can generate one using Ruby:

```sh
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

Or use the Fizzy codebase:

```sh
docker run --rm shawnschwartz/fizzy-homelab:latest bin/rails secret
```

Once you have one, set it in the `SECRET_KEY_BASE` environment variable:

```sh
docker run --environment SECRET_KEY_BASE=abcdefabcdef ...
```

#### SSL

If you want the Fizzy container to handle its own SSL automatically, you just need to specify the domain name that you're running it on.
You can do that with the `TLS_DOMAIN` environment variable.
Note that if you're using SSL, you'll want to allow traffic on ports 80 and 443:

```sh
docker run --publish 80:80 --publish 443:443 --environment TLS_DOMAIN=fizzy.example.com ...
```

If you are terminating SSL in some other proxy in front of Fizzy (like Cloudflare Tunnel), then you don't need to set `TLS_DOMAIN`, and can just publish port 80:

```sh
docker run --publish 80:80 ...
```

If you aren't using SSL at all (for example, if you want to run it locally on your network), then you should specify `DISABLE_SSL=true` instead:

```sh
docker run --publish 80:80 --environment DISABLE_SSL=true ...
```

#### SMTP Email

Fizzy needs to be able to send email for its sign in flow (magic links) and for its regular summary emails.
The easiest way to set this up is to use a 3rd-party email provider (such as Postmark, Sendgrid, Gmail, etc.).
You can then plug all your SMTP settings from that provider into Fizzy via the following environment variables:

- `MAILER_FROM_ADDRESS` - the "from" address that Fizzy should use to send email
- `SMTP_ADDRESS` - the address of the SMTP server you'll send through
- `SMTP_PORT` - the port number (defaults to 465 when `SMTP_TLS` is set, 587 otherwise)
- `SMTP_USERNAME`/`SMTP_PASSWORD` - the credentials for logging in to the SMTP server

Less commonly, you might also need to set some of the following:

- `SMTP_TLS` - set to `true` only for servers requiring implicit TLS (SMTPS on port 465); STARTTLS is used automatically by default so most servers don't need this
- `SMTP_DOMAIN` - the domain name advertised to the server when connecting
- `SMTP_AUTHENTICATION` - if you need an authentication method other than the default `plain`
- `SMTP_SSL_VERIFY_MODE` - set to `none` to skip certificate verification (for self-signed certs)

You can find out more about all these settings in the [Rails Action Mailer documentation](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration).

#### Base URL

Fizzy needs to know the public URL of your instance so it can generate correct links in certain situations (like when sending emails).
Set `BASE_URL` to the full URL where your Fizzy instance is accessible:

```sh
docker run --environment BASE_URL=https://fizzy.example.com ...
```

#### VAPID keys

Fizzy can also send Web Push notifications.
To do this it needs a VAPID key pair.

You can create your own keys by starting a development console:

```sh
docker run --rm -it shawnschwartz/fizzy-homelab:latest bin/rails console
```

And then run the following to create the keypair:

```ruby
vapid_key = WebPush.generate_key

puts "VAPID_PRIVATE_KEY=#{vapid_key.private_key}"
puts "VAPID_PUBLIC_KEY=#{vapid_key.public_key}"
```

Set those in the `VAPID_PRIVATE_KEY` and `VAPID_PUBLIC_KEY` environment variables.

#### S3 storage (optional)

If you'd prefer that uploaded files were stored in an S3 bucket rather than in your mounted volume, you can set that up.

First set `ACTIVE_STORAGE_SERVICE` to `s3`.
Then set the following as appropriate for your S3 bucket:

- `S3_BUCKET`
- `S3_REGION`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`

If you're using a provider other than AWS, you will also need some of the following:

- `S3_ENDPOINT`
- `S3_FORCE_PATH_STYLE`
- `S3_REQUEST_CHECKSUM_CALCULATION`
- `S3_RESPONSE_CHECKSUM_VALIDATION`

## Example

Here's an example of a `docker-compose.yml` that you could use to run Fizzy Homelab Edition via `docker compose up`

```yaml
services:
  web:
    image: shawnschwartz/fizzy-homelab:latest
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      # Required
      - SECRET_KEY_BASE=your-long-random-secret-key-here
      - BASE_URL=https://fizzy.yourdomain.com

      # Email configuration
      - MAILER_FROM_ADDRESS=fizzy@yourdomain.com
      - SMTP_ADDRESS=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USERNAME=your-email@gmail.com
      - SMTP_PASSWORD=your-app-password

      # Web Push notifications
      - VAPID_PRIVATE_KEY=your-vapid-private-key
      - VAPID_PUBLIC_KEY=your-vapid-public-key

      # SSL - omit if using Cloudflare Tunnel or other proxy
      # - TLS_DOMAIN=fizzy.yourdomain.com

    volumes:
      - fizzy-data:/rails/storage

volumes:
  fizzy-data:
```

### Using with Cloudflare Tunnel

If you're exposing this through a Cloudflare Tunnel:

1. Do NOT set `TLS_DOMAIN` (Cloudflare handles SSL)
2. Only expose port 80
3. Set `BASE_URL` to your public Cloudflare URL
4. Configure your tunnel to point to `localhost:80` (or your container's IP)

Example minimal configuration:

```yaml
services:
  web:
    image: shawnschwartz/fizzy-homelab:latest
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - SECRET_KEY_BASE=your-secret-key
      - BASE_URL=https://fizzy.yourdomain.com
      - MAILER_FROM_ADDRESS=fizzy@yourdomain.com
      - SMTP_ADDRESS=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USERNAME=your-email@gmail.com
      - SMTP_PASSWORD=your-app-password
    volumes:
      - fizzy-data:/rails/storage

volumes:
  fizzy-data:
```

### Adding Additional Users

Since signups are disabled, you'll need to add new users manually. You can do this through the Rails console or by inviting users from within the application once you've logged in as the owner.

To add a user via Rails console:

```sh
docker exec -it your-container-name bin/rails console
```

Then:

```ruby
# Find your account
account = Account.first

# Create a new identity
identity = Identity.create!(email_address: "newuser@example.com")

# Add user to the account
user = account.users.create!(
  identity: identity,
  role: :member,  # or :admin
  name: "New User Name"
)
```

The user can then sign in using the magic link flow at your instance's login page.

### Support and Source Code

This is a community-maintained variant of [Fizzy](https://github.com/basecamp/fizzy) by 37signals. The only modification from the upstream version is that new account signups have been disabled for security purposes.

For issues with the Homelab edition specifically, please contact the maintainer.
For general Fizzy issues and features, see the [upstream repository](https://github.com/basecamp/fizzy).
