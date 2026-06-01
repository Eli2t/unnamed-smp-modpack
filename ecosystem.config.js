// pm2 config for the Magma dev server.
// Usage on the server:
//   cp ecosystem.config.js ~/unnamed-smp/   (or run from the repo with --cwd)
//   pm2 start ecosystem.config.js
//
// The restart limits matter: if the server fails fast (bad EULA, crash on
// boot, etc.) pm2 stops after a few tries instead of looping forever and
// rate-limiting GitHub (the 403 you saw).
module.exports = {
  apps: [{
    name: "smp-dev",
    script: "./start.sh",
    interpreter: "bash",
    cwd: process.env.HOME + "/unnamed-smp",
    autorestart: true,
    restart_delay: 10000,   // wait 10s between restarts (don't hammer)
    min_uptime: 30000,      // must run 30s to count as a successful start
    max_restarts: 5,        // give up after 5 fast failures
    kill_timeout: 30000,    // let Minecraft save & shut down cleanly on stop
  }]
}
