const axios = require('axios')
const commandLineArgs = require('command-line-args')
const fs = require('fs')
const https = require('https')

const OPTION_DEFINITIONS = [
    { name: 'root-ca' },
    { name: 'url' },
]

function getOptions() {
    const cliOptions = commandLineArgs(OPTION_DEFINITIONS)
    const rootCA = cliOptions['root-ca']
    const url = cliOptions.url || 'https://localhost:8443'
    return { rootCA, url }
}

async function main() {
    const cliOptions = getOptions()
    const options = {}
    if (cliOptions.rootCA) {
        options.ca = [fs.readFileSync(cliOptions.rootCA)]
    }
    const axiosOptions = {
        httpsAgent: new https.Agent(options),
    }

    try {
        const response = await axios.get(cliOptions.url, axiosOptions)
        console.log(`Response: ${JSON.stringify(response.data)}`)
    } catch (err) {
        if (!(err.isAxiosError)) {
            throw err
        }

        console.log(`   Error Code: ${err.code}`)
        console.log(`Error Message: ${err.message}`)
    }
}

if (require.main === module) {
    main()
}
