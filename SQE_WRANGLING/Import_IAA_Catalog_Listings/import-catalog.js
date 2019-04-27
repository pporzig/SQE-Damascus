const mariadb = require('mariadb')
const references = require('./write.json')
const pool = mariadb.createPool({
     host: 'localhost',
     port: 3307,
     user:'root',
     password: 'none',
     connectionLimit: 75,
     database: "SQE_DEV"
})
const _cliProgress = require('cli-progress')
const bar = new _cliProgress.Bar({}, _cliProgress.Presets.shades_classic)
let prog = 0

const importReferences = async () => {
    console.log('Preparing to load entries.')
    console.log('\tPlease be patient, it takes about 10 seconds to prepare for writing.')
    bar.start(Object.keys(references).length, 0)
    for (const key in references) {
        for (const ref of references[key]) {
            insertRef(ref)
        }
    }
}

const insertRef = async (ref) => {
    let sides = []
    if (ref.plate.indexOf('Rec') > -1) {
        ref.plate = ref.plate.match(/\d+/)[0]
        sides = [0]
    } else if (ref.plate.indexOf('Vrs') > -1) {
        ref.plate = ref.plate.match(/\d+/)[0]
        sides = [1]
    } else sides = [0,1]

    for (let i = 0; i <=1; i++) {
        try {
            const imageCatNo = writeCatalog(ref, i)
            const editionNo = writeEdition(ref, i)
            await writeImgEd(await imageCatNo, await editionNo)
        } catch(err) {
            console.error(err)
            process.exit(1)
        }
    }
    bar.update(++prog)
    if (Object.keys(references).length === prog) {
        try {
            await pool.end()
        } catch(err) {
            console.error(err)
            process.exit(1)
        } finally {
            console.log('Successfully finished writing entries to the database.')
            bar.stop()
            process.exit(0)
        }
    }
}

const writeCatalog = async (cat, side) => {
    let conn
    let imageCatNo
    try {
        conn = await pool.getConnection()
        const res = await conn.query(
            `INSERT INTO image_catalog (institution, catalog_number_1, catalog_number_2, catalog_side)
                VALUE (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE image_catalog_id = LAST_INSERT_ID(image_catalog_id)`,
            [
                "IAA",
                cat.plate,
                cat.fragment,
                side
            ])
        imageCatNo = res.insertId
    } catch (err) {
        await sleep(5)
        return writeCatalog(cat, side)
    } finally {
        if (conn) {
            conn.end()
            return imageCatNo
        }
    }
}

const writeEdition = async (edition, side) => {
    let conn
    let editionNo
    try {
        conn = await pool.getConnection()
        const res = await conn.query(
            `INSERT INTO edition_catalog (manuscript, edition_name, edition_volume, edition_location_1, edition_location_2, edition_side, comment)
                VALUE (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE edition_catalog_id = LAST_INSERT_ID(edition_catalog_id)
            `,
            [
                edition.manuscript,
                edition.edition || null,
                edition.volume || null,
                edition.ed_plate || null,
                edition.ed_fragment || null,
                side,
                edition.comment || null
            ])
        editionNo = res.insertId
    } catch (err) {
        await sleep(5)
        return writeEdition(edition, side)
    } finally {
        if (conn) {
            conn.end()
            return editionNo
        }
    }
}

const writeImgEd = async (imageCatNo, editionNo) => {
    let conn
    let imgEdNo
    try {
        conn = await pool.getConnection()
        const res = await conn.query(
            `INSERT IGNORE INTO image_to_edition_catalog (image_catalog_id, edition_catalog_id)
                VALUE (?, ?)`,
            [
                imageCatNo,
                editionNo
            ])
        imgEdNo = res.insertId
    } catch (err) {
        await sleep(5)
        return writeImgEd(imageCatNo, editionNo)
    } finally {
        if (conn) {
            conn.end()
            return imgEdNo
        }
    }
}

const sleep = (ms) => {
    return new Promise(resolve=>{
        setTimeout(resolve,ms)
    })
}

importReferences()