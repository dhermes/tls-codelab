const commandLineArgs = require('command-line-args')
const express = require('express')
const fs = require('fs')
const https = require('https')

const PORT = 9443
const OPTION_DEFINITIONS = [
    { name: 'cert' },
    { name: 'key' },
    { name: 'root-ca' },
]

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
    const rootCA = cliOptions['root-ca']

    return { cert: cliOptions.cert, key: cliOptions.key, rootCA }
}

function makeSecureConnectionCallback() {
    const secureConnectionReasons = []
    const callback = function secureConnectionCallback(tlsSocket) {
        // NOTE: This will grow indefinitely throughout the lifetime of the
        //       server, so this is really a bad idea outside of demo code.
        secureConnectionReasons.push(tlsSocket.authorizationError)
    }
    return [callback, secureConnectionReasons]
}

function main() {
    const cliOptions = getOptions()

    const app = express()
    const options = {
        key: fs.readFileSync(cliOptions.key),
        cert: fs.readFileSync(cliOptions.cert),
        requestCert: true,
        rejectUnauthorized: false,
    }
    if (cliOptions.rootCA) {
        options.ca = [fs.readFileSync(cliOptions.rootCA)]
    }

    const [secureConnectionCallback, secureConnectionReasons] = makeSecureConnectionCallback()
    app.get('*', (req, res) => {
        // NOTE: `res.json()` doesn't add a newline so we do it manually.
        res.set('Content-Type', 'application/json')
        if (req.client.authorized) {
            res.send('{"mTLSValid": true}\n')
            return
        }

        // NOTE: The below code assumes
        //       - `secureConnectionReasons` will not be empty
        //       - there will be no data race for `secureConnectionReasons` access
        //       - the `secureConnection` callback will complete before this handler is invoked
        //       - `reason` is simple enough that no JSON escaping is needed
        const reason = secureConnectionReasons[secureConnectionReasons.length - 1]
        res.send('{"mTLSValid": false, "reason": ' + JSON.stringify(reason) + '}\n')
    })

    const server = https.createServer(options, app)
    // NOTE: It's necessary to use `addContext()` due to the way `createServer()`
    //       creates a TLS context:
    //       https://github.com/nodejs/node/blob/v14.15.4/lib/_tls_wrap.js#L1323
    server.addContext('*', options)
    server.on('secureConnection', secureConnectionCallback)
    server.listen(PORT, () => {
        console.log(`Example mTLS app listening at https://localhost:${PORT}`)
    })
}

if (require.main === module) {
    main()
}
