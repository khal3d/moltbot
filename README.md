# OpenClaw Deployment Bundle (Formerly ClawdBot/MoltBot)

This repository packages everything you need to run **OpenClaw** locally with Docker. It includes a container image build, a Docker Compose definition.

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

### First-time setup and CLI workflow

Once the containers are running, enter the `openclaw` container and run the CLI setup + approval flow:

```bash
docker compose exec openclaw bash
openclaw setup
openclaw dashboard # (Copy the dashboard URL with the token)
openclaw devices list
openclaw devices approve <REQUEST ID>
openclaw configure # Configure a channel & model
```

Notes:

- `openclaw setup` performs the one-time initialization and prepares the workspace under `/root/.openclaw`.
- `openclaw dashboard` prints a tokenized Control UI URL. Open it in your browser (usually `http://localhost:18789/?token=...`).
- `openclaw devices list` shows pending pairing requests from the Control UI.
- `openclaw devices approve <REQUEST ID>` authorizes a pending request so the Control UI can connect.
- `openclaw configure` sets the default channel and model that the gateway should use.


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

To complete the full CLI workflow (pairing, approving, configuring) inside Kubernetes, start a shell and run the same commands as Docker Compose:

```bash
kubectl exec -it deploy/openclaw -- bash
openclaw setup
openclaw dashboard # (Copy the dashboard URL with the token)
openclaw devices list
openclaw devices approve <REQUEST ID>
openclaw configure # Configure a channel & model
```

To access the UI locally, port-forward the gateway service port:

```bash
kubectl port-forward svc/openclaw 8080:18789
```

This maps the in-cluster gateway port (`18789`) to your local machine on `http://localhost:8080`. Open the Control UI using the tokenized URL from `openclaw dashboard`, swapping the host/port to `http://localhost:8080/?token=...`.

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
