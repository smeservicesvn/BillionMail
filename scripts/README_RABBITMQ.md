# 🐇 RabbitMQ + Management Installer

This package provides a ready-to-run script to **install, configure, and manage RabbitMQ with the management console** on a VPS running Ubuntu/Debian.

## ✨ Features
- Installs Erlang 26.0+ (required dependency for RabbitMQ 3.12+)
- Installs RabbitMQ and required dependencies
- Enables the Management Plugin (Web UI at port `15672`)
- Creates an admin user with full permissions
- Opens necessary firewall ports (`5672`, `15672`)
- Safe to re-run: idempotent setup (won't duplicate repo, user, or keys)

---

## 📦 Installation

1. Upload the script to your VPS:
```bash
scp install_rabbitmq.sh user@your-vps:/home/user/
```

2. Connect to your VPS:
```bash
ssh user@your-vps
```

3. Make the script executable and run it:
```bash
chmod +x install_rabbitmq.sh
sudo bash install_rabbitmq.sh
```

## 🔧 What the Script Does

The installation script performs the following steps:

1. **System Update**: Updates and upgrades the system packages
2. **Dependencies**: Installs required packages (curl, gnupg, apt-transport-https, lsb-release)
3. **Erlang Repository**: Adds the official Erlang Solutions repository for Erlang 26.0+
4. **RabbitMQ Repository**: Adds the official RabbitMQ repository
5. **Erlang Installation**: Installs `esl-erlang` (Erlang 26.0+)
6. **RabbitMQ Installation**: Installs RabbitMQ server
7. **Service Setup**: Enables and starts the RabbitMQ service
8. **Management Plugin**: Enables the web management interface
9. **User Creation**: Creates admin user `smessvn` with full permissions
10. **Firewall**: Opens ports 5672 (AMQP) and 15672 (Management UI)

## 🚀 Post-Installation

After successful installation, you can:

- **Access Management UI**: http://your-server-ip:15672
- **Login Credentials**: 
  - Username: `smessvn`
  - Password: `befzeV-5nifhu-rawcuf`

## 🔍 Troubleshooting

### Common Issues

**Erlang Version Error**: If you see an error like:
```
rabbitmq-server : Depends: erlang-base (>= 1:26.0) but 1:25.3.2.8+dfsg-1ubuntu4.4 is to be installed
```

**Solution**: The updated script now automatically handles this by installing Erlang 26.0+ from the official repository.

**Network/Download Error**: If you see an error like:
```
curl: (22) The requested URL returned error: 504
gpg: no valid OpenPGP data found.
```

**Solution**: The script now includes fallback methods:
1. Tries HTTPS first, then HTTP if HTTPS fails
2. Falls back to Ubuntu's default Erlang packages if the repository is unavailable
3. Provides clear error messages and continues with available options

**Erlang Version Conflict**: If you see an error like:
```
rabbitmq-server : Depends: erlang-base (>= 1:26.0) but 1:25.3.2.8+dfsg-1ubuntu4.4 is to be installed
```

**Solution**: The script now:
1. Checks current Erlang version before installation
2. Removes old Erlang packages if version < 26.0
3. Ensures esl-erlang (Erlang 26.0+) is installed before RabbitMQ
4. Provides clear error messages if Erlang 26.0+ cannot be installed

### Useful Commands

Check service status:
```bash
sudo systemctl status rabbitmq-server
```

View service logs:
```bash
sudo journalctl -u rabbitmq-server -f
```

List RabbitMQ users:
```bash
sudo rabbitmqctl list_users
```

Check RabbitMQ plugins:
```bash
sudo rabbitmq-plugins list
```

## 🛠️ Management

### Reset RabbitMQ
To reset RabbitMQ to factory defaults, use the included reset script:
```bash
sudo bash reset_rabbitmq.sh
```

### Manual User Management
Add a new user:
```bash
sudo rabbitmqctl add_user username password
sudo rabbitmqctl set_user_tags username administrator
sudo rabbitmqctl set_permissions -p / username ".*" ".*" ".*"
```

Delete a user:
```bash
sudo rabbitmqctl delete_user username
```

## 📝 Configuration

The script uses these default settings:
- **RabbitMQ User**: `smessvn`
- **RabbitMQ Password**: `befzeV-5nifhu-rawcuf`
- **Management Port**: `15672`
- **AMQP Port**: `5672`

To customize these settings, edit the variables at the top of `install_rabbitmq.sh`.