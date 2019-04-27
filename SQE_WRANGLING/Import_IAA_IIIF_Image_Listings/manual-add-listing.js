const csv=require('csvtojson')
const args = require('minimist')(process.argv.slice(2))
const mariadb = require('mariadb')
const pool = mariadb.createPool({host: 'localhost', port:3307, user:'root', password:'none', database: 'SQE_DEV', connectionLimit: 10})

if (!args.f) {
    console.error('You must supply the path to a CSV file with the -f switch.')
    process.exit(1)
}

const processFile = async () => {
    try {
       const csvFile = args.f

        const entries = await csv().fromFile(csvFile)

        for (entry of entries) {
            const sideR = await createEntry(entry, 0)
            if (sideR.warningStatus !== 0) throw(new Error(JSON.stringify(entry)))
            const sideV = await createEntry(entry, 1)
            if (sideV.warningStatus !== 0) throw(new Error(JSON.stringify(entry)))
        }

        console.log('Finished adding images with edition data.')
        process.exit(0)
    } catch(err) {
        console.error('Process failed.')
        console.error(err)
        process.exit(1)
    }
}

const createEntry = async (entry, side) => {
    return new Promise(async (resolve, reject) => {
        try {
            const edition = await pool.query(`
            INSERT INTO edition_catalog (manuscript, edition_name, edition_volume, edition_location_1, edition_location_2, edition_side, scroll_id)
            VALUES('${entry.DJD_scroll}', '${entry.edition_name}', '${entry.DJD_volume}', '${entry.DJD_plate}', '${entry.DJD_scroll_fragment}', ${side}, ${entry.scroll_id})
            ON DUPLICATE KEY UPDATE edition_catalog_id = LAST_INSERT_ID(edition_catalog_id)
            `)

            const image = await pool.query(`
            INSERT INTO image_catalog (institution, catalog_number_1, catalog_number_2, catalog_side)
            VALUES('${entry.Institution}', ${entry.IAA_plate}, ${entry.IAA_fragment}, ${side})
            ON DUPLICATE KEY UPDATE image_catalog_id = LAST_INSERT_ID(image_catalog_id)
            `)

            const binding = await pool.query(`
            INSERT IGNORE INTO image_to_edition_catalog (edition_catalog_id, image_catalog_id)
            VALUES(${edition.insertId}, ${image.insertId})
            `)

            resolve(binding)
        } catch(err) {
            reject(err)
        }
    })
}

processFile()