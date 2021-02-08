const axios = require('axios')
const commandLineArgs = require('command-line-args')
const fs = require('fs')
const https = require('https')

const URL = 'https://localhost:9443'
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
    return { cert, key, rootCA }
}

async function main() {
    const cliOptions = getOptions()
    const options = {}
    options.cert = fs.readFileSync(cliOptions.cert)
    options.key = fs.readFileSync(cliOptions.key)
    if (cliOptions.rootCA) {
        options.ca = [fs.readFileSync(cliOptions.rootCA)]
    }
    const axiosOptions = {
        httpsAgent: new https.Agent(options),
    }

    const response = await axios.get(URL, axiosOptions)
    console.log(response.data)
}

if (require.main === module) {
    main()
}
