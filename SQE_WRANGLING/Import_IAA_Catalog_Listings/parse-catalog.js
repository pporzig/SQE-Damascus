/**
 * This parser receives a CSV file output from the
 * IAA Menorah database and parses it for insertion
 * into the SQE database.
 */

const csv=require('csvtojson')
const args = require('minimist')(process.argv.slice(2))
const fs = require('fs').promises
const manualRefs = require('./Data/manual-refs.json')

const editions = require('./parsers.js').editions
const expander = require('./reference-expansion.js').expander

const defaultFilePath = './Data/IAA-DJD-Fragment-Reference-10-02-2019.txt'
let failed = []
let problems = {}
const problemPattern = /.*([\., +;:-]).*/
const decimal = /[\d]{1,3}\.[\d]{1,3}/
const cleanPlate = /(^\-)|(^\()|(\)$)/g
let writeQueue = {}
if (!args.f) {
    console.warn(`If you don't provide a filename with the -f switch,
    the default will be used: '${defaultFilePath}'.`)
}
const inputFile = args.f || defaultFilePath

const parseListingFile = async () => {
    try {
        const listings = await csv({delimiter: 'auto'}).fromFile(inputFile)
        const tasks = []
        listings.map(async listing => tasks.push(parseListing(listing)))
        tasks.map(async task => {try{await task} catch(err) {console.error(err)}})
        await fs.writeFile('write.json', JSON.stringify(writeQueue, null, 2))
        await fs.writeFile('Debugging/problems.json', JSON.stringify(problems, null, 2))
        await fs.writeFile('Debugging/failed.json', JSON.stringify(failed, null, 2))
        await fs.writeFile('Debugging/failed-patterns.json', JSON.stringify(failed.reduce((x, y) => {
            x[y["DJD- publication number"]] = `${y["Manuscript number"]}: IAA plate ${y["Plate number- IAA inventory"]}, IAA fragment ${y["Fragment number (on IAA plate)"]}.`
            return x;
        }, {}), null, 2))
    } catch(err) {
        console.error(err)
        process.exit(1)
    }

    console.log(`\nFinished processing references.
    Succeeded in parsing ${writeQueue.length} references, failed to parse ${failed.length} references.`)
    process.exit(0)
}

const parseListing = async (record) => {
    return new Promise((resolve, reject) => {
        const reference = record['DJD- publication number']
        const csv = `${record['Manuscript number']}	${record['Plate number- IAA inventory']}	${record['Fragment number (on IAA plate)']}	${reference}`
        if (manualRefs[csv]) writeQueue[csv] = manualRefs[csv]
        else {
            writeQueue[csv] = []
            try {
                let parsedReferences = []
                for (parser in editions) {
                    if (editions[parser].pat.test(reference)) {
                        parsedReferences.push(editions[parser].parse(reference))
                    }
                }
                if (parsedReferences.length === 0) {
                    failed.push(record)
                    parsedReferences.push({
                        edition: null,
                        volume: null,
                        ed_plate: null,
                        ed_fragment: null
                    })
                } else {
                    parsedReferences = expander(parsedReferences[0])
                }

                parsedReferences.map(ref => {
                    let comment
                    if (ref.ed_fragment) {
                        [ref.ed_fragment, comment] = ref.ed_fragment.split('(')
                        ref.ed_fragment = ref.ed_fragment.trim().replace(/(;$)|(:$)|(\.$)|(,$)/g, "").trim()
                        if (comment) comment = '(' + comment
                        if (problemPattern.test(ref.ed_fragment) && !decimal.test(ref.ed_fragment)){
                            if (!problems[csv]) problems[csv] = []
                            problems[csv].push({
                                manuscript: record['Manuscript number'],
                                plate: record['Plate number- IAA inventory'],
                                fragment: record['Fragment number (on IAA plate)'],
                                ...ref,
                                comment: comment
                            })
                        }
                    }

                    if (problemPattern.test(ref.ed_plate)){
                        if (!problems[csv]) problems[csv] = []
                        problems[csv].push({
                            manuscript: record['Manuscript number'],
                            plate: record['Plate number- IAA inventory'],
                            fragment: record['Fragment number (on IAA plate)'],
                            ...ref
                        })
                    }

                    writeQueue[csv].push({
                        manuscript: record['Manuscript number'].trim(),
                        plate: record['Plate number- IAA inventory'].trim().replace(cleanPlate, '').trim(),
                        fragment: record['Fragment number (on IAA plate)'],
                        ...ref,
                        comment: comment
                    })
                })

                resolve()
            } catch(err) {
                console.error(err)
                reject()
            }
        }

    })
}

parseListingFile()