const mariadb = require('mariadb')
const pool = mariadb.createPool({
     host: 'localhost',
     port: 3307,
     user:'root',
     password: 'none',
     connectionLimit: 75,
     database: "SQE_DEV"
})

const createTables = async () => {
    try {

        // Create all edition_catalog_owner entries
        await pool.query(`
INSERT IGNORE INTO edition_catalog_author (edition_catalog_id, user_id)
SELECT edition_catalog_id, 1
FROM edition_catalog
        `)

        // Create all possible image_catalog_owner entries
        await pool.query(`
INSERT IGNORE INTO image_catalog_author (image_catalog_id, user_id)
SELECT DISTINCT image_catalog.image_catalog_id, 1
FROM image_catalog
        `)

        // Create all possible SQE_image_owner entries
        await pool.query(`
INSERT IGNORE INTO SQE_image_author (sqe_image_id, user_id)
SELECT DISTINCT SQE_image.sqe_image_id, 1
FROM SQE_image
        `)

    } catch(err) {
        console.error(err)
        process.exit(1)
    } finally {
        process.exit(0)
    }

}

createTables()