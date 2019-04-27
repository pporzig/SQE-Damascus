const mariadb = require('mariadb')
const pool = mariadb.createPool({host: 'localhost', port:3307, user:'root', password:'none', database: 'SQE_DEV', connectionLimit: 85})
const axios = require('axios')
const fs = require('fs')
const readline = require('readline')
const log = require('single-line-log')(process.stdout)
const clui = require('clui')

const Progress = clui.Progress
const thisProgressBar = new Progress(20)

// let batchUsed = 0
// const batchSize = 20
// We will count the completed rows because this is async
let completed = 0
// We will store the results in an array to write to file at the end
let failed = []
let avgTime = []

pool.getConnection()
  .then(conn => {
    // Note with scroll_version.user_id = 1, we get only the
    // default SQE data.
    conn.query(`
    SELECT CONCAT(image_urls.proxy, image_urls.url, SQE_image.filename) AS url
    FROM SQE_image
    JOIN image_urls USING(image_urls_id)
    WHERE image_urls_id != 0
    ORDER BY SQE_image.sqe_image_id
    `)
      .then((rows) => {
        results = new Array(rows.length)  // Now we know how many results to expect, so instantiate the results Array

        // Get the text for each line (processLine launches an async database query)
        // for (let i = 0, row; (row = rows[i]); i++) {
        //   requestImage(row.url, i, rows.length - 1)

        //   // processLineWords(row, i, rows.length - 1)
        // }
        requestImage(rows, 0, 0, Date.now())
        conn.end()  // kill this connection to free up others
      })
      .catch(err => {
        //handle error
        console.error(err)
        conn.end()
        process.exit(1)
      })

  }).catch(err => {
    //not connected
      console.error(err)
      process.exit(1)
  })

  const requestImage = async (urls, count, retries, start) => {
    try {
        res = await axios.get(`${urls[count].url}/info.json`)
        await getSizedImage(urls[count].url, res.data.sizes, 0)
        completed += 1
        avgTime.push(Date.now() - start)
        printProgress((completed / urls.length) * 100, `${urls[count].url}/full/${res.data.sizes[0].width},/0/default.jpg`, urls.length, completed)
        if (completed === urls.length) {
            if (failed.length > 0) {
                const file = fs.createWriteStream('seed-failed.txt')
                file.on('error', function(err) { console.error('Cannot write to file.') })
                failed.forEach(function(v) { file.write(v + '\n') })
                file.end()
                console.log(`Missed ${failed.length}`)
            }
            process.exit(0)
        }
        // batchUsed--
        // if (batchUsed < batchSize)
        requestImage(urls, ++count, 0, Date.now())
    } catch(err) {
        if (retries <= 20) {
            requestImage(urls, count, ++retries, start) // Try 20 times to get file
        } else { // Give up and move on
            console.error(err)
            failed.push(urls[count].url)
            //console.error(err)
            completed += 1
            avgTime.push(Date.now() - start)
            printProgress((completed / urls.length) * 100, 'Failed! ' + urls[count].url, urls.length, completed)
            if (completed === urls.length) {
                if (failed.length > 0) {
                    const file = fs.createWriteStream('seed-failed.txt')
                    file.on('error', function(err) { console.error('Cannot write to file.') })
                    failed.forEach(function(v) { file.write(v + '\n') })
                    file.end()
                    console.log(`Missed ${failed.length}`)
                }
                process.exit(0)
            }
            // if (batchUsed < batchSize)
            requestImage(urls, ++count, 0, Date.now())
        }
    }
}

const getSizedImage = async (url, sizes, count) => {
    if (count < 20) {
        try {
            await Promise.all([
                axios.get(`${url}/full/${sizes[0].width},/0/default.jpg`),
                axios.get(`${url}/full/${sizes[1].width},/0/default.jpg`),
                axios.get(`${url}/full/${sizes[2].width},/0/default.jpg`),
                axios.get(`${url}/full/${sizes[3].width},/0/default.jpg`)
            ])
        } catch(err) {
            getSizedImage(url, sizes, ++count)
        }
    } else {
        throw `Failed ${url}/full/${sizes[0].width},/0/default.jpg`
    }
}

const printProgress = (progress, url, imagesTotal, imagesCompleted) => {
  const imagesLeft = imagesTotal - imagesCompleted
  const averageTime = (avgTime.reduce((a, b) => a + b, 0) / avgTime.length) / 1000 // Average time in seconds
  const timeLeft = (averageTime * imagesLeft) / 3600 // Time left in hours
  log.clear()
  log(`${thisProgressBar.update(imagesCompleted, imagesTotal)} ${truncateDecimals(timeLeft, 1)} hours left for ${imagesLeft} imgs (avg ${truncateDecimals(averageTime, 1)} secs) - ${url.replace('https://qumranica.org/image-proxy?address=', '')}`)
}

function truncateDecimals (num, digits) {
    var numS = num.toString(),
        decPos = numS.indexOf('.'),
        substrLength = decPos == -1 ? numS.length : 1 + decPos + digits,
        trimmedResult = numS.substr(0, substrLength),
        finalResult = isNaN(trimmedResult) ? 0 : trimmedResult;

    return parseFloat(finalResult);
}