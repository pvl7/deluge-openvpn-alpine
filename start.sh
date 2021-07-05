#!/usr/bin/env bash

set -euo pipefail

bash /01-startopenvpn.sh
bash /02-startdeluge.sh

sleep infinity
