# Bitcoin Wallet (Signet)

## Usage

### Run both CLI and new transaction info logs via tmux (MacOS only)
```bash
sudo chmod +x ./scripts/start.sh
sh ./scripts/start.sh
```
### Or use them separately

```[terminal 1]``` cli 
```bash
docker compose run --rm client
```

```[terminal 2]``` fulfilments logs
```bash
docker compose logs cron -f
```
