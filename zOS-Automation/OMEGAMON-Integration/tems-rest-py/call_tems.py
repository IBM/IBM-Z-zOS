#!/usr/bin/env python3

# Copyright 2024 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# -----------------------------------------------------------------
#
# Disclaimer of Warranties:
#
#   The following enclosed code is sample code created by IBM
#   Corporation.  This sample code is not part of any standard
#   IBM product and is provided to you solely for the purpose
#   of assisting you in the development of your applications.
#   The code is provided "AS IS", without warranty of any kind.
#   IBM shall not be liable for any damages arising out of your
#   use of the sample code, even if they have been advised of
#   the possibility of such damages.

"""
TEMS REST API Client

A Python script to call Tivoli Enterprise Monitoring Server (TEMS) REST API.
Handles authentication, token caching, and automatic token refresh.
"""

import argparse
from email.policy import HTTP
import json
import os
import sys
import warnings
from base64 import b64encode
from typing import Optional, Tuple

import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.ssl_ import create_urllib3_context
import urllib3

CIPHERS = (
    ':HIGH:!DH:!aNULL'
)

class MySSL_HTTPAdapter(HTTPAdapter):
    def init_poolmanager(self, *args, **kwargs):
        ssl_context = create_urllib3_context(ciphers=CIPHERS)
        ssl_context.check_hostname = False
        kwargs['ssl_context'] = ssl_context
        return super(MySSL_HTTPAdapter, self).init_poolmanager(*args, **kwargs)


class TEMSClient:
    """Client for interacting with TEMS REST API."""

    def __init__(self, protocol: str, hostname: str, port: int, userid: str, password: str, verify_ssl: bool = True):
        """
        Initialize TEMS client.

        Args:
            protocol: http or https
            hostname: TEMS server hostname
            port: TEMS server port
            userid: TEMS userid for authentication
            password: TEMS password for authentication
            verify_ssl: Whether to verify SSL certificates (default: True)
        """
        self.protocol = protocol
        self.hostname = hostname
        self.port = port
        self.userid = userid
        self.password = password
        self.verify_ssl = verify_ssl
        self.base_url = f"{protocol}://{hostname}:{port}"

        # Extract first part of hostname for env var name
        self.hostname_short = hostname.split('.')[0]
        self.token_env_var = f"TEMS_{self.hostname_short}_AUTHORIZATION_TOKEN"

        # Suppress SSL warnings if verification is disabled
        adapter = HTTPAdapter()
        if not verify_ssl:
            warnings.simplefilter('ignore', urllib3.exceptions.InsecureRequestWarning)
            adapter = MySSL_HTTPAdapter()

        # Lower the bar for the Cipher Suite being used
        self.session = requests.Session()
        self.session.mount('https://', adapter)

    def get_cached_token(self) -> Optional[str]:
        """
        Retrieve cached authorization token from environment variable.

        Returns:
            Cached token if exists, None otherwise
        """
        return os.environ.get(self.token_env_var)

    def cache_token(self, token: str) -> None:
        """
        Store authorization token in environment variable.

        Args:
            token: Bearer token to cache
        """
        os.environ[self.token_env_var] = token

    def authenticate(self) -> str:
        """
        Authenticate with TEMS and obtain bearer token.

        Returns:
            Bearer authorization token

        Raises:
            requests.exceptions.RequestException: On network or HTTP errors
            ValueError: On authentication failure
        """
        token_url = f"{self.base_url}/api/v1/token"

        # Create Basic Auth header
        credentials = f"{self.userid}:{self.password}"
        encoded_credentials = b64encode(credentials.encode()).decode()
        headers = {
            "Authorization": f"Basic {encoded_credentials}"
        }

        try:
            response = self.session.get(token_url, headers=headers, timeout=30, verify=self.verify_ssl)
            response.raise_for_status()

            # Parse JSON response and extract access_token
            try:
                response_data = response.json()
                token = response_data.get('access_token')
                if not token:
                    raise ValueError("No 'access_token' field in authentication response")
            except json.JSONDecodeError as e:
                raise ValueError(f"Invalid JSON response from authentication endpoint: {e}") from e

            # Cache the token
            self.cache_token(token)

            return token

        except requests.exceptions.HTTPError as e:
            if e.response.status_code in (401, 403):
                raise ValueError(f"Authentication failed: Invalid credentials") from e
            raise ValueError(f"Authentication failed: {e}") from e
        except requests.exceptions.RequestException as e:
            raise ValueError(f"Failed to connect to TEMS server: {e}") from e

    def make_request(self, path: str, token: Optional[str] = None) -> Tuple[str, bool]:
        """
        Make GET request to TEMS REST API.

        Args:
            path: API endpoint path (e.g., /api/v1/systems)
            token: Bearer token (if None, will authenticate)

        Returns:
            Tuple of (response_text, is_json)

        Raises:
            ValueError: On request failure
        """
        url = f"{self.base_url}{path}"

        # Get token if not provided
        if token is None:
            token = self.get_cached_token()
            if token is None:
                token = self.authenticate()

        headers = {
            "Authorization": f"Bearer {token}"
        }

        try:
            response = self.session.get(url, headers=headers, timeout=30, verify=self.verify_ssl)

            # Check for token expiration
            if response.status_code in (401, 403):
                # Token expired, get new one and retry
                token = self.authenticate()
                headers["Authorization"] = f"Bearer {token}"
                response = requests.get(url, headers=headers, timeout=30, verify=self.verify_ssl)

            response.raise_for_status()

            # Check if response is JSON
            content_type = response.headers.get('Content-Type', '')
            is_json = 'application/json' in content_type

            # Try to parse as JSON even if content-type doesn't indicate it
            if not is_json:
                try:
                    json.loads(response.text)
                    is_json = True
                except json.JSONDecodeError:
                    pass

            return response.text, is_json

        except requests.exceptions.HTTPError as e:
            raise ValueError(f"API request failed: {e.response.status_code} {e.response.reason}") from e
        except requests.exceptions.RequestException as e:
            raise ValueError(f"Request failed: {e}") from e


def format_output(response_text: str, is_json: bool, raw_output: bool = False) -> str:
    """
    Format response for output.

    Args:
        response_text: Raw response text
        is_json: Whether response is JSON
        raw_output: If True, convert JSON to line-delimited key-value pairs without braces/brackets

    Returns:
        Formatted output string
    """
    # If raw output requested for JSON, convert to line-delimited format
    if raw_output and is_json:
        try:
            data = json.loads(response_text)
            return convert_to_line_format(data)
        except json.JSONDecodeError:
            # Fall back to raw text if JSON parsing fails
            return response_text
    elif raw_output:
        # For non-JSON, return as-is
        return response_text

    # Otherwise, pretty-print JSON if applicable
    if is_json:
        try:
            data = json.loads(response_text)
            return json.dumps(data, indent=2)
        except json.JSONDecodeError:
            # Fall back to raw text if JSON parsing fails
            return response_text
    return response_text


def convert_to_line_format(data) -> str:
    """
    Convert JSON data to line-delimited format using attribute=value pairs.
    Pairs are separated by 0xFFFF character. No quotes, colons, or commas.

    Args:
        data: Parsed JSON data (dict, list, or primitive)

    Returns:
        String with one line per object, attribute=value pairs separated by "0xFFFF"
    """
    lines = []
    separator = "0xFFFF"

    if isinstance(data, list):
        # Handle JSON array - each object becomes one line
        for item in data:
            if isinstance(item, dict):
                # Convert object to attribute=value pairs on one line
                pairs = []
                for key, value in item.items():
                    # Format value based on type (no quotes)
                    if isinstance(value, str):
                        formatted_value = value
                    elif isinstance(value, (int, float, bool)):
                        formatted_value = str(value).lower() if isinstance(value, bool) else str(value)
                    elif value is None:
                        formatted_value = "null"
                    else:
                        # For nested objects/arrays, convert to compact JSON
                        formatted_value = json.dumps(value, separators=(',', ':'))

                    pairs.append(f'{key}={formatted_value}')

                lines.append(separator.join(pairs))
            else:
                # Non-object items in array
                lines.append(str(item))

    elif isinstance(data, dict):
        # Handle single JSON object - convert to one line
        pairs = []
        for key, value in data.items():
            # Format value based on type (no quotes)
            if isinstance(value, str):
                formatted_value = value
            elif isinstance(value, (int, float, bool)):
                formatted_value = str(value).lower() if isinstance(value, bool) else str(value)
            elif value is None:
                formatted_value = "null"
            else:
                # For nested objects/arrays, convert to compact JSON
                formatted_value = json.dumps(value, separators=(',', ':'))

            pairs.append(f'{key}={formatted_value}')

        lines.append(separator.join(pairs))

    else:
        # Handle primitive values
        lines.append(str(data))

    return "\n".join(lines)


def load_env_file(env_file: str = '.env') -> dict:
    """
    Load environment variables from a .env file.

    Args:
        env_file: Path to the .env file (default: '.env')

    Returns:
        Dictionary of environment variables from the file
    """
    env_vars = {}

    if not os.path.exists(env_file):
        return env_vars

    try:
        with open(env_file, 'r') as f:
            for line in f:
                # Skip comments and empty lines
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                # Parse KEY=VALUE format
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()

                    # Remove quotes if present
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]

                    env_vars[key] = value
    except Exception as e:
        print(f"Warning: Could not read .env file: {e}", file=sys.stderr)

    return env_vars


def get_credential(param_value: Optional[str], env_key: str, env_file_vars: dict) -> Optional[str]:
    """
    Get credential value following precedence: parameter > .env file > environment variable.

    Args:
        param_value: Value from command-line parameter
        env_key: Environment variable key name
        env_file_vars: Dictionary of variables loaded from .env file

    Returns:
        Credential value or None
    """
    # 1. Highest precedence: command-line parameter
    if param_value is not None:
        return param_value

    # 2. Second precedence: .env file
    if env_key in env_file_vars:
        return env_file_vars[env_key]

    # 3. Lowest precedence: environment variable
    return os.environ.get(env_key)


def parse_arguments() -> argparse.Namespace:
    """
    Parse command-line arguments.

    Returns:
        Parsed arguments
    """
    parser = argparse.ArgumentParser(
        description='Call Tivoli Enterprise Monitoring Server (TEMS) REST API',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using command-line arguments (highest precedence)
  %(prog)s --userid admin --password secret \\
    --hostname tems.example.com --path /api/v1/systems

  # Using .env file (second precedence)
  echo "TEMS_USERID=admin" > .env
  echo "TEMS_PASSWORD=secret" >> .env
  %(prog)s --hostname tems.example.com --path /api/v1/agents

  # Using environment variables (lowest precedence)
  export TEMS_USERID=admin
  export TEMS_PASSWORD=secret
  %(prog)s --hostname tems.example.com --path /api/v1/agents

  # With custom protocol and port
  %(prog)s -u admin -p secret \\
    --protocol http --hostname localhost --port 8080 \\
    --path /api/v1/status

  # Disable SSL certificate verification (insecure)
  %(prog)s -u admin -p secret --insecure \\
    --hostname tems.example.com --path /api/v1/systems

  # attribute=value format with 0xFFFF separator (for EBCDIC/z/OS)
  %(prog)s -u admin -p secret --raw-output \\
    --hostname tems.example.com --path /api/v1/systems

  # Save output to file
  %(prog)s -u admin -p secret \\
    --hostname tems.example.com --path /api/v1/systems \\
    --output systems.json
        """
    )

    parser.add_argument(
        '--userid', '-u',
        help='TEMS userid (precedence: parameter > .env file > environment variable)',
        default=None
    )
    parser.add_argument(
        '--password', '-p',
        help='TEMS password (precedence: parameter > .env file > environment variable)',
        default=None
    )
    parser.add_argument(
        '--protocol',
        choices=['http', 'https'],
        default='https',
        help='Protocol to use (default: https)'
    )
    parser.add_argument(
        '--hostname',
        required=True,
        help='TEMS server hostname'
    )
    parser.add_argument(
        '--port',
        type=int,
        default=3661,
        help='TEMS server port (default: 3661)'
    )
    parser.add_argument(
        '--path',
        required=True,
        help='REST API endpoint path (e.g., /api/v1/systems)'
    )
    parser.add_argument(
        '--output', '-o',
        help='Output file path (default: stdout)'
    )
    parser.add_argument(
        '--insecure', '-k',
        action='store_true',
        help='Disable SSL certificate verification (insecure, similar to curl -k)'
    )
    parser.add_argument(
        '--raw-output', '-r',
        action='store_true',
        help='Convert JSON to attribute=value format, separated by 0xFFFF (EBCDIC-safe)'
    )

    return parser.parse_args()


def main() -> int:
    """
    Main entry point.

    Returns:
        Exit code (0 for success, 1 for error)
    """
    args = parse_arguments()

    # Load environment variables from .env file if it exists
    env_file = ""
    home = os.environ.get('HOME')
    if home is not None:
        env_file = os.path.join(home, '.env')
    env_file_vars = load_env_file(env_file=env_file)

    # Get credentials following precedence: parameter > .env file > environment variable
    userid = get_credential(args.userid, 'TEMS_USERID', env_file_vars)
    password = get_credential(args.password, 'TEMS_PASSWORD', env_file_vars)

    # Validate credentials
    if not userid:
        print("Error: userid is required (use --userid, .env file, or set TEMS_USERID)", file=sys.stderr)
        return 1
    if not password:
        print("Error: password is required (use --password, .env file, or set TEMS_PASSWORD)", file=sys.stderr)
        return 1

    try:
        # Create client
        client = TEMSClient(
            protocol=args.protocol,
            hostname=args.hostname,
            port=args.port,
            userid=userid,
            password=password,
            verify_ssl=not args.insecure
        )

        # Make request
        response_text, is_json = client.make_request(args.path)

        # Format output
        output = format_output(response_text, is_json, raw_output=args.raw_output)

        # Write output
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
                f.write('\n')
            print(f"Output written to {args.output}", file=sys.stderr)
        else:
            print(output)

        return 0

    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())

# Made with Bob
