# openclaw Deployment Bundle (Formerly ClawdBot/MoltBot)

This repository packages everything you need to run **openclaw** locally with Docker. It includes a container image build, a Docker Compose definition.

## Contents

- `Dockerfile` — builds a lightweight image that installs the `openclaw` CLI and runs the gateway service.
- `docker-compose.yaml` — starts the service locally with persistent volumes and health checks.

## Docker

### Build the image

```bash
docker build -t openclaw:local .
```

### Run with Docker

```bash
docker run -it --rm \
  -p 18789:18789 \
  -p 18791:18791 \
  -e OPENCLAW_GATEWAY_TOKEN="<token>" \
  -v "$(pwd)/data/openclaw-config:/root/.openclaw" \
  openclaw:local
```

The image exposes ports `18789` (gateway UI/API) and `18791` (bridge) by default. The data directories are persisted under `./data/` in the example above.

## Docker Compose

Start the service using the published image:

```bash
docker compose up -d
```

The compose file maps the following defaults:

- Gateway: `18789` → `18789`
- Bridge: `18790` → `18790`

You can override the ports with `OPENCLAW_GATEWAY_PORT` and `OPENCLAW_BRIDGE_PORT`, and provide required secrets via environment variables:

- `OPENCLAW_GATEWAY_TOKEN`

Data persists in `./data/openclaw-config` and `./data/openclaw-workspace` by default.

## Helm (Kubernetes)

Install the chart and configure the gateway token (either via an existing Secret or via a value):

```bash
helm install openclaw ./openclaw-chart \
  --set gateway.tokenSecret.value="<token>"
```

To reuse an existing Secret instead of embedding the token in values:

```bash
helm install openclaw ./openclaw-chart \
  --set gateway.tokenSecret.existingSecret="openclaw-gateway-token" \
  --set gateway.tokenSecret.key="OPENCLAW_GATEWAY_TOKEN"
```

Once the pod is running, execute the one-time setup inside the container:

```bash
kubectl exec -it deploy/openclaw -- openclaw setup
```

To access the UI locally, port-forward the gateway service port:

```bash
kubectl port-forward svc/openclaw 8080:18789
```

## Notes

- If you use the Dockerfile build, the gateway binds to `lan` by default. The Docker Compose file binds to `loopback`.
- Ensure the gateway token is set before starting the service.

## Troubleshooting

### Control UI Requires HTTPS or localhost
> disconnected (1008): control ui requires HTTPS or localhost (secure context)
Fix:
```
Open the Control UI from either:
- http://localhost:<port>
- https://<your-domain>

Note: non-localhost HTTP URLs (ex: http://192.168.x.x) are not considered a secure context.
```

### Unauthorized: gateway token mismatch
> disconnected (1008): unauthorized: gateway token mismatch (open a tokenized dashboard URL or paste token in Control UI settings)

Fix:
```
This means the Control UI is using a different token than the running gateway.

Fix options:
- Open the tokenized dashboard URL (recommended):
  http://localhost:18789/?token=<your-token>
- Or paste the correct token in: Control UI → Config → Gateway → Gateway Token

Then restart the gateway with the same token:
  export OPENCLAW_GATEWAY_TOKEN="<your-token>"
```

### Pairing Required
> disconnected (1008): pairing required

Fix:
```
List pending device requests:
  openclaw devices list

Approve a pending request:
  openclaw devices approve <PENDING_REQUEST_ID>
```
