const mariadb = require('mariadb')
const pool = mariadb.createPool({host: 'localhost', port:3307, user:'root', password:'none', database: 'SQE_DEV', connectionLimit: 85})
const fs = require('fs')

// We will count the completed rows because this is async
let completed = 0
// We will store the results in an array to write to file at the end
let results

pool.getConnection()
  .then(conn => {
    // Note with scroll_version.user_id = 1, we get only the
    // default SQE data.
    conn.query(`SELECT scroll_data.name AS scroll_name, col_data.name AS col_name, line_data.name AS line_name, line_data.line_id AS line_id
      FROM scroll_data
      JOIN scroll_data_owner USING(scroll_data_id)
      JOIN scroll_version USING(scroll_version_id)
      JOIN scroll_to_col USING(scroll_id)
      JOIN col_data USING(col_id)
      JOIN col_to_line USING(col_id)
      JOIN line_data USING(line_id)
      WHERE scroll_version.user_id = 1
      ORDER BY scroll_data.scroll_id, col_data.col_id, line_data.line_id`)
      .then((rows) => {
        results = new Array(rows.length)  // Now we know how many results to expect, so instantiate the results Array

        // Get the text for each line (processLine launches an async database query)
        for (let i = 0, row; (row = rows[i]); i++) {
          processLine(row, i, rows.length - 1)
          // processLineWords(row, i, rows.length - 1)
        }
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

/**
 * 
 * Get the text for a single line.
 * Put the result in the right place
 * in the results Array.
 * When we have incremented the completed
 * variable to the same number as the length,
 * then we are done and can write the results
 * to file. 
 */
const processLine = (row, count, length) => {
  pool.getConnection()
  .then(conn => {
    conn.query(`SELECT sign_char.sign as sign, GROUP_CONCAT(sign_char_attribute.attribute_value_id) as attribute
    FROM sign
    JOIN sign_char USING(sign_id)
    JOIN sign_char_attribute USING(sign_char_id)
    JOIN line_to_sign USING(sign_id)
    WHERE line_to_sign.line_id = ?
    GROUP BY sign_char.sign_char_id
    ORDER BY sign_char.sign_char_id`, [row.line_id])
      .then((rows) => {

        // Process each letter in the line and build the text of the line
        let lineString = ''
        for (let i = 0, letter; (letter = rows[i]); i++) {
          const attributes = letter.attribute.split(',')
          if (attributes.indexOf('2') > -1) lineString += ' '
          if (attributes.indexOf('1') > -1) {
            if (attributes.indexOf('20') > -1) lineString += '-' // Put dashes in place of reconstructions
            else lineString += letter.sign // Use real letters when they exist
          } 
        }
        results[count] = `${row.scroll_name} ${row.col_name}, ${row.line_name}\t${lineString}\n`

        // Increment the completed count, print our progress, and free up the connection
        conn.end()
        completed += 1
        printProgress((completed / length) * 100) // Keep an eye on the progress by printing it to console.
        
        if (completed === length) { // All rows have now been retrieved
          const file = fs.createWriteStream('SQE_Texts.txt')
          file.on('error', err => console.error(err))
          results.forEach(v => file.write(v))
          file.end()
          file.on('finish', () => { // The file write is async, so we wait till it is finished.
            process.exit(0)  // then we stop the program.
          })
        }
      })
      .catch(err => {
        //handle error
        console.error(err)
        conn.end()
        process.exit(1)
      })
      
  }).catch(err => {
    //If we can't get a connection right away, we wait and try again and again
    processLine(row, count, length)
  })
}

/**
 * 
 * Get the text for a single line.
 * Put the result in the right place
 * in the results Array.
 * When we have incremented the completed
 * variable to the same number as the length,
 * then we are done and can write the results
 * to file. 
 */
const processLineWords = (row, count, length) => {
  pool.getConnection()
  .then(conn => {
    conn.query(`SELECT sign_char.sign as sign, GROUP_CONCAT(sign_char_attribute.attribute_value_id) as attribute, position_in_stream_to_word_rel.word_id as word
    FROM sign
    JOIN sign_char USING(sign_id)
    JOIN sign_char_attribute USING(sign_char_id)
    JOIN line_to_sign USING(sign_id)
    JOIN position_in_stream USING(sign_id)
    LEFT JOIN position_in_stream_to_word_rel USING(position_in_stream_id)
    WHERE line_to_sign.line_id = ?
    GROUP BY sign_char.sign_char_id
    ORDER BY sign_char.sign_char_id`, [row.line_id])
      .then((rows) => {

        // Process each letter in the line and build the text of the line
        let wordID = undefined
        let lineString = ''
        for (let i = 0, letter; (letter = rows[i]); i++) {
          const attributes = letter.attribute.split(',')
          if (attributes.indexOf('2') > -1) lineString += ' '
          if (attributes.indexOf('1') > -1) {
            if (attributes.indexOf('20') > -1) lineString += '-' // Put dashes in place of reconstructions
            else lineString += letter.sign // Use real letters when they exist
          }
          if (wordID && !letter.word) {
            lineString += `${wordID} `
          }
          wordID = letter.word
        }
        results[count] = `${row.scroll_name} ${row.col_name}, ${row.line_name}\t${lineString}\n`

        // Increment the completed count, print our progress, and free up the connection
        conn.end()
        completed += 1
        printProgress((completed / length) * 100) // Keep an eye on the progress by printing it to console.
        
        if (completed === length) { // All rows have now been retrieved
          const file = fs.createWriteStream('SQE_Texts.txt')
          file.on('error', err => console.error(err))
          results.forEach(v => file.write(v))
          file.end()
          file.on('finish', () => { // The file write is async, so we wait till it is finished.
            process.exit(0)  // then we stop the program.
          })
        }
      })
      .catch(err => {
        //handle error
        console.error(err)
        conn.end()
        process.exit(1)
      })
      
  }).catch(err => {
    //If we can't get a connection right away, we wait and try again and again
    processLineWords(row, count, length)
  })
}

const printProgress = progress => {
  process.stdout.clearLine()
  process.stdout.cursorTo(0)
  process.stdout.write(`${Math.round(progress * 100) / 100} % complete`)
}