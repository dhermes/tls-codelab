const commandLineArgs = require('command-line-args')
const fs = require('fs')
const requestPromise = require('request-promise-native')
const requestErrors = require('request-promise-native/errors')

const PORT = 8443
const URL = `https://localhost:${PORT}`
const OPTION_DEFINITIONS = [
    { name: 'cert' },
    { name: 'key' },
    { name: 'root-ca' },
]

function getOptions() {
    const cliOptions = commandLineArgs(OPTION_DEFINITIONS)
    const rootCA = cliOptions['root-ca']
    return { cert: cliOptions.cert, key: cliOptions.key, rootCA }
}

async function main() {
    const cliOptions = getOptions()
    const options = {}
    if (cliOptions.cert) {
        options.cert = fs.readFileSync(cliOptions.cert)
    }
    if (cliOptions.key) {
        options.key = fs.readFileSync(cliOptions.key)
    }
    if (cliOptions.rootCA) {
        options.ca = [fs.readFileSync(cliOptions.rootCA)]
    }

    try {
        const response = await requestPromise.get(URL, options)
        console.log(response.trimEnd())
    } catch (err) {
        if (!(err instanceof requestErrors.RequestError)) {
            throw err
        }

        console.log(`Error Code: ${err.error.code}`)
        console.log(`Error Message: ${err.error.message}`)
    }
}

if (require.main === module) {
    main()
}
