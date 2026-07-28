# Codex Theme Switcher 0.2.9-beta.2

## More reliable Codex connections

- Automatically selects the next available loopback bridge port when the default port is occupied, instead of leaving Theme Switcher unable to communicate with Codex.
- Persists the selected bridge port for each Theme Switcher data root so subsequent commands reconnect consistently.
- Keeps explicitly configured ports strict: a conflict is reported instead of silently moving to another port.
- Adds bridge-port regression coverage and a new theme showcase image to all seven README languages.
