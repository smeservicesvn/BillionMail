# 🐇 RabbitMQ + Management Installer

This package provides a ready-to-run script to **install, configure, and manage RabbitMQ with the management console** on a VPS running Ubuntu/Debian.

## ✨ Features
- Installs RabbitMQ and required dependencies
- Enables the Management Plugin (Web UI at port `15672`)
- Creates an admin user with full permissions
- Opens necessary firewall ports (`5672`, `15672`)
- Safe to re-run: idempotent setup (won’t duplicate repo, user, or keys)

---

## 📦 Installation

1. Upload the script to your VPS:
```bash
   scp install_rabbitmq.sh user@your-vps:/home/user/
```

2. Connect to your VPS:
   ssh user@your-vps

```bash
sudo systemctl status rabbitmq-server

sudo journalctl -u rabbitmq-server -f

sudo rabbitmqctl list_users

```