/**
 * This script reads all the names from scroll_data + col_data (QWB's catalog).
 * It outputs a discrete listing of all fragments to QWB_cols-discrete.json.
 */

const fs = require('fs')
const mariadb = require('mariadb')
const chalk = require('chalk')

let textColumns = {}
const lowerRoman = / m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})/gm
const numPlusLetter = /^(\d{1,5})?([a-zA-Z]{1,2})$/m
const numberRange = /(\d{1,5})_(\d{1,5})/m
const letterRange = /(\d{1,5})?([a-zA-Z]{1,2})_([a-zA-Z]{1,5})/m

console.log(chalk.blue('Connecting to DB.  This may take a moment.'))
const p = mariadb.createPool({
  host: 'localhost',
  port: 3307,
  user:'root', 
  password: 'none',
  database: 'SQE_DEV',
  connectionLimit: 80
})

const getTextCols = pool => {
    return new Promise (async (resolve, reject) => {
        try{
            const conn = await pool.getConnection()
            const rows = await conn.query(`SELECT scroll_to_col.scroll_id as scroll_id, col_data.col_id as col_id, col_data.name as name
            FROM col_data
            JOIN scroll_to_col USING(col_id)`)
            for (let i = 0, row; (row = rows[i]); i++) {
                if (textColumns[row.scroll_id]) textColumns[row.scroll_id].push({[row.col_id]: row.name})
                else textColumns[row.scroll_id] = [{[row.col_id]: row.name}]
            }
            resolve(conn)
        } catch(err) {
            reject(err)
        }
    })
}

// See https://stackoverflow.com/questions/12376870/create-an-array-of-characters-from-specified-range
const alphaRange = (first, last) => {
  const a = first.charCodeAt(0)
  const b = last.charCodeAt(0) + 1
  return Array.apply(null, {length: Math.abs(b - a)})
    .map(function (x,i) { return String.fromCharCode(Math.min(a, b) + i) })
}

const numRange = (first, last) => {
  return Array.apply(null, {length: Math.abs(last - first) + 1})
    .map(function (x,i) { return (Math.min(first, last) + i).toString() })
}

const processRecords = async () => {
    try {
        const conn1 = await getTextCols(p)
        conn1.end()
        // Make discrete references for text
        for (const scroll_id in textColumns) {
            for (let i = 0, textColumn; (textColumn = textColumns[scroll_id][i]); i++) {
                for (let col_id in textColumn) {
                    if (textColumn[col_id].indexOf('frg.') > -1) {
                        let name = textColumn[col_id].replace('frg. ', '').replace(lowerRoman, '')
                        let individalFrags = []
                        const addedFrags = name.split('+')
                        addedFrags.forEach(addedFrag => {
                        let foundNumRange = false
                        let foundLetterRange = false
                        if (numberRange.test(addedFrag)) {
                            foundNumRange = true
                            const [full, start, end] = numberRange.exec(addedFrag)
                            const numbers = numRange(start, end)
                            individalFrags = [...individalFrags, ...numbers]
                        }
                        if (letterRange.test(addedFrag)) {
                            foundLetterRange = true
                            const [full, frgNum, start, end] =  addedFrag.match(letterRange)
                            const numbers = alphaRange(start, end)
                            individalFrags = [...individalFrags, ...numbers.map(x => (frgNum ? frgNum : '') + x)]
                        }
                        if (!foundNumRange && !foundLetterRange) individalFrags.push(addedFrag)
                        textColumn.frg = individalFrags
                        textColumn.col_id = col_id
                        })
                    } else {
                        let name = textColumn[col_id].replace('col. ', '').replace(lowerRoman, '')
                        let individalFrags = []
                        const addedFrags = name.split('+')
                        addedFrags.forEach(addedFrag => {
                        if (letterRange.test(addedFrag)) {
                            const [full, colNum, start, end] =  addedFrag.match(letterRange)
                            const numbers = alphaRange(start, end)
                            individalFrags = [...individalFrags, ...numbers.map(x => x)]
                            textColumn.col = colNum
                        } else if (numPlusLetter.test(addedFrag)) {
                            const [full, colNum, frgNum] =  addedFrag.match(numPlusLetter)
                            individalFrags = [...individalFrags, frgNum]
                            textColumn.col = colNum
                        } else {
                            textColumn.col = addedFrag
                        }
                        })
                        textColumn.frg = [...individalFrags]
                        textColumn.col_id = col_id
                    }
                }
            }
        }
        //Output the textColumn object.
        fs.writeFile('QWB_cols-discrete.json', JSON.stringify(textColumns, null, 2), (err) => {  
            // throws an error, you could also catch it here
            if (err) throw err;

            // success case, the file was saved
            console.log(chalk.green('JSON file saved!'))
            process.exit(0)
        })
    } catch(err) {
        console.error(err)
        process.exit(1)
    }
}

processRecords()