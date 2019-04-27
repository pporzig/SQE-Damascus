/**
 * This script reads all the names from edition_catalog (the IAA's catalog) 
 * and from scroll_data + col_data (QWB's catalog).  It uses these data to
 * match the names in the two catalogs and create a csv output that can be
 * used to correlate each image with its corresponding text transcription
 * in the database.  The output file is called, QWB_IAA-cols.csv.  On the 
 * last run this parser made about 14,000 matches.
 * 
 * It outputs two other files: QWB_cols-discrete.json, and IAA-discrete.json.
 * These files can be used for debugging to see how well the parser was able
 * to break the joins and difficult names into discrete entities.
 */

const fs = require('fs')
const mariadb = require('mariadb')
const chalk = require('chalk')

let imageColumns = {}

console.log(chalk.blue('Connecting to DB.  This may take a moment.'))
const p = mariadb.createPool({
  host: 'localhost',
  port: 3307,
  user:'root', 
  password: 'none',
  database: 'SQE_DEV',
  connectionLimit: 80
})

const getImageCols = async pool => {
    try {
        const conn = await pool.getConnection()
        const rows = await conn.query(`SELECT DISTINCT scroll_id, edition_catalog_id AS ed_id, edition_location_1 AS loc1, edition_location_2 AS loc2
        FROM edition_catalog`)
        for (let i = 0, row; (row = rows[i]); i++) {
            imageColumns[row.scroll_id] = {...imageColumns[row.scroll_id]}
            imageColumns[row.scroll_id].all = imageColumns[row.scroll_id].all ? [...imageColumns[row.scroll_id].all, row.ed_id] : [row.ed_id]
            if (!imageColumns[row.scroll_id].columns) imageColumns[row.scroll_id].columns = {}
            if (!imageColumns[row.scroll_id].columns[row.loc1]) imageColumns[row.scroll_id].columns[row.loc1] = []
            if (row.loc1) imageColumns[row.scroll_id].columns[row.loc1] = [...imageColumns[row.scroll_id].columns[row.loc1], row.ed_id]
            if (!imageColumns[row.scroll_id].frg) imageColumns[row.scroll_id].frg = {}
            if (row.loc2) imageColumns[row.scroll_id].frg[row.loc2] = imageColumns[row.scroll_id].frg[row.loc2] ? [...imageColumns[row.scroll_id].frg[row.loc2], row.ed_id] : [row.ed_id]
        }
        fs.writeFile('IAA-discrete.json', JSON.stringify(imageColumns, null, 2), (err) => {  
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

getImageCols(p)