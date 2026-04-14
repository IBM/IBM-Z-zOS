# TEMS REST API Client

A Python command-line tool for calling Tivoli Enterprise Monitoring Server (TEMS) REST API with automatic authentication, token management, and EBCDIC-safe output formatting.

## Quick Start

```bash
# 1. Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run the script
python call_tems.py --userid admin --password secret \
  --hostname tems.example.com --port 3661 --path /api/v1/system/nodes
```

## Features

- ✅ **Automatic Authentication** - Obtains bearer tokens via Basic Auth
- ✅ **Token Caching** - Stores tokens in environment variables for reuse
- ✅ **Auto Token Refresh** - Detects expired tokens and refreshes automatically
- ✅ **Multiple Credential Sources** - Command-line, .env file, or environment variables
- ✅ **JSON Pretty-Printing** - Formats JSON output with indentation
- ✅ **EBCDIC-Safe Output** - Special format for z/OS environments (`--raw-output`)
- ✅ **SSL Options** - Disable certificate verification for development (`--insecure`)

## Usage

### Basic Usage

```bash
python call_tems.py --userid USER --password PASS \
  --hostname tems.example.com --path /api/v1/system/nodes
```

### Credential Precedence

Credentials are loaded in this order (highest to lowest precedence):

1. **Command-line parameters**
   ```bash
   python call_tems.py --userid admin --password secret --hostname tems.example.com --path /api/v1/system/nodes
   ```

2. **`.env` file in home directory** (`$HOME/.env`)
   ```bash
   # Create ~/.env file
   echo "TEMS_USERID=admin" >> ~/.env
   echo "TEMS_PASSWORD=secret" >> ~/.env
   chmod 600 ~/.env
   
   # Run without credentials
   python call_tems.py --hostname tems.example.com --path /api/v1/system/nodes
   ```

3. **Environment variables**
   ```bash
   export TEMS_USERID=admin
   export TEMS_PASSWORD=secret
   python call_tems.py --hostname tems.example.com --path /api/v1/system/nodes
   ```

### Common Options

```bash
# Custom protocol and port
python call_tems.py -u admin -p secret \
  --protocol http --hostname localhost --port 8080 \
  --path /api/v1/timenow

# Disable SSL verification (for self-signed certificates)
python call_tems.py -u admin -p secret --insecure \
  --hostname tems.example.com --path /api/v1/system/nodes

# Save output to file
python call_tems.py -u admin -p secret \
  --hostname tems.example.com --path /api/v1/system/nodes \
  --output systems.json

# EBCDIC-safe output for z/OS (attribute=value format)
python call_tems.py -u admin -p secret --raw-output \
  --hostname tems.example.com --path /api/v1/system/nodes
```

## Command-Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--userid` | `-u` | TEMS userid | From .env or environment |
| `--password` | `-p` | TEMS password | From .env or environment |
| `--hostname` | | TEMS server hostname | Required |
| `--path` | | REST API endpoint path | Required |
| `--protocol` | | http or https | `https` |
| `--port` | | TEMS server port | `3661` |
| `--output` | `-o` | Output file path | stdout |
| `--insecure` | `-k` | Disable SSL verification | `false` |
| `--raw-output` | `-r` | EBCDIC-safe output format | `false` |

## Output Formats

### Standard JSON (Default)

Pretty-printed JSON with 2-space indentation:

```json
{
  "systems": [
    {
      "name": "server1",
      "status": "active"
    }
  ]
}
```

### Raw Output (`--raw-output`)

EBCDIC-safe format using `attribute=value` pairs separated by `0xFFFF`:

```
name=server10xFFFFstatus=active
name=server20xFFFFstatus=inactive
```

This format avoids problematic characters (`{`, `}`, `[`, `]`, `:`, `,`, `"`) that can be corrupted during ASCII-to-EBCDIC conversion on z/OS.

## Token Management

Tokens are automatically cached in environment variables with the format:

```
TEMS_<hostname>_AUTHORIZATION_TOKEN
```

For example, connecting to `tems-prod.example.com` caches the token in:

```
TEMS_tems-prod_AUTHORIZATION_TOKEN
```

Tokens are automatically refreshed when they expire (401/403 responses).

## Requirements

- Python 3.12 or higher
- `requests` library (see `requirements.txt`)

## Documentation

- [Original Specification](docs/specification.md) - Initial project requirements
- [TEMS REST API Documentation](https://www.ibm.com/docs/en/om-shared?topic=interfaces-tivoli-enterprise-monitoring-server-rest-services) - IBM official documentation

## Security Notes

- **`.env` file**: Set permissions to `600` (read/write for owner only)
- **Command-line passwords**: Visible in process list - use .env file for production
- **`--insecure` flag**: Only use in development/testing environments
- **Token caching**: Tokens stored in environment variables are accessible to child processes

## License

See project license file.