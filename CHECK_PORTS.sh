#!/usr/bin/env bash
# READ-ONLY inventory for the exact Docker VM/LXC (no deployments or mutations).
set -u
echo "=== Hostname / IP ==="
hostname
ip -br address || true
echo "=== All Docker containers (including stopped) ==="
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
echo "=== Existing compose projects ==="
docker compose ls -a || true
echo "=== Host listeners TCP + UDP (may require sudo for process names) ==="
ss -lntup || true
echo "=== OSINT candidate TCP ports ==="
for port in 29001 29002 29003 29004 29005 29006 29100; do
  echo "--- Port ${port}/TCP ---"
  ss -H -ltn "( sport = :${port} )" || true
done
echo "=== Docker port bindings including stopped containers ==="
docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}}'
echo "Done (read-only). Empty listener result is not a reservation."
