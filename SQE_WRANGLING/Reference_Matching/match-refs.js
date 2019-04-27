const fs = require('fs')
const toCSV = require('array-to-csv')
// const romanNumeralToDecimal = require('roman-numeral-to-decimal')
const toRoman = require('roman-numerals').toRoman
const chalk = require('chalk')

const qwb = require('./QWB_cols-discrete.json')
const iaa = require('./IAA-discrete.json')

let matches = []
let failed = []

const processMatches = () => {
    for (scrollID in qwb) {
        if (iaa[scrollID]) {
            for (colName of qwb[scrollID]) {
                if (colName[colName.col_id].indexOf("frg") > -1) {
                    for (frg of colName.frg) {
                        let tempMatch = []
                        if (iaa[scrollID].frg[frg]) tempMatch.push(...iaa[scrollID].frg[frg])
                        if (tempMatch.length > 2 && !isNaN(~~colName.col) && iaa[scrollID].columns[toRoman(~~colName.col)]) {
                            tempMatch = tempMatch.filter(value => -1 !== iaa[scrollID].columns[toRoman(~~colName.col)].indexOf(value))
                        }
                        if (tempMatch.length === 2) matches.push(...tempMatch.map(x => [x, ~~colName.col_id]))
                        else failed.push({scroll_id: scrollID, col_id: colName.col_id, col_name: colName[colName.col], frg: frg})
                    }
                } else {
                    if (colName.frg.length > 0) {
                        for (frg of colName.frg) {
                            let tempMatch = []
                            if (iaa[scrollID].frg[frg.toUpperCase()]) tempMatch.push(...iaa[scrollID].frg[frg.toUpperCase()])
                            if (iaa[scrollID].frg[frg.toLowerCase()]) tempMatch.push(...iaa[scrollID].frg[frg.toLowerCase()])
                            if (tempMatch.length > 2 && !isNaN(~~colName.col) && iaa[scrollID].columns[toRoman(~~colName.col)]) {
                                tempMatch = tempMatch.filter(value => -1 !== iaa[scrollID].columns[toRoman(~~colName.col)].indexOf(value))
                            }
                            if (tempMatch.length === 2) matches.push(...tempMatch.map(x => [x, ~~colName.col_id]))
                        }
                    } else {
                        if (!isNaN(~~colName.col) && iaa[scrollID].columns[toRoman(~~colName.col)]) matches.push(...iaa[scrollID].columns[toRoman(~~colName.col)].map(x => [x, ~~colName.col_id]))
                        else failed.push({scroll_id: scrollID, col_id: colName.col_id, col_name: colName[colName.col]})
                    }
                }
            }
        } else failed.push({scroll_id: scrollID})
    }
    const matchLength = matches.length
    matches = toCSV([
      ['edition_catalog_id', 'col_id'],
      ...matches
    ])
    fs.writeFile('matches.csv', matches, (err) => {
        // throws an error, you could also catch it here
        if (err) throw err;

        // success case, the file was saved
        console.log(chalk.green('matches.csv file saved!'))
        fs.writeFile('failed.json', JSON.stringify(failed, null, 2), (err) => {
            // throws an error, you could also catch it here
            if (err) throw err;

            // success case, the file was saved
            console.log(chalk.green('failed.json file saved!'))
            console.log(chalk.yellow(`${matchLength} matches, ${failed.length} failed.`))
            process.exit(0)
        })
    })
}

processMatches()