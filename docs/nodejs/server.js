const commandLineArgs = require('command-line-args')
const express = require('express')
const fs = require('fs')
const https = require('https')
const tls = require('tls')

const PORT = 8443
const OPTION_DEFINITIONS = [
    { name: 'cert' },
    { name: 'key' },
]

function monkeyPatchTLSSocket() {
    const originalInit = tls.TLSSocket.prototype._init
    tls.TLSSocket.prototype._init = function _init(socket, wrap) {
        this.disableRenegotiation()
        return originalInit.apply(this, [socket, wrap])
    }
}

function getOptions() {
    const cliOptions = commandLineArgs(OPTION_DEFINITIONS)
    const cert = cliOptions.cert
    if (!cert) {
        console.error(`The '--cert' flag is required`)
        process.exit(1)
    }
    const key = cliOptions.key
    if (!key) {
        console.error(`The '--key' flag is required`)
        process.exit(1)
    }

    return { cert: cliOptions.cert, key: cliOptions.key }
}

function main() {
    monkeyPatchTLSSocket()
    const cliOptions = getOptions()

    const app = express()
    const options = {
        key: fs.readFileSync(cliOptions.key),
        cert: fs.readFileSync(cliOptions.cert),
    }

    app.get('*', (_req, res) => {
        // NOTE: `res.json()` doesn't add a newline so we do it manually.
        res.set('Content-Type', 'application/json')
        res.send('{"success": true}\n')
    })

    const server = https.createServer(options, app)
    server.listen(PORT, () => {
        console.log(`Example TLS app listening at https://localhost:${PORT}`)
    })
}

if (require.main === module) {
    main()
}
