const args = require('minimist')(process.argv.slice(2))
const axios = require('axios')
const puppeteer = require('puppeteer')
const chalk = require('chalk')

if (!args.s || !args.c) {
  console.error(chalk.red(`
You need to provide some more parameters for this to work.`))
  console.log(chalk.blue(`
Please provide at least a scroll_version_id with the -s 
switch and a col_id with the -c switch.
  `))
  console.log(`
  The following parameters are optional:
  -i  Sets the session_id token
  -o  Sets output file name (default: "output.png")
  -f  Sets the output font (uses system names; default: "DSS 4Q51")
  -h  Sets the height of the line spacing (default: 2)
  -w  Sets the spacing between words (default: 3)

An example:`)
  console.log(chalk.green(`
node create-image.js -s 876 -c 9817 -o 4Q35-f1.png -f "DSS 4Q51" -h 1 -w 2
  `))
  process.exit(1) 
}
const scrollVersionID = args.s
const colID = args.c
const session_id = args.i || 'B2A50B52-E1CE-11E8-A12D-E5B7EAEE5222'
const font = args.f || 'DSS 4Q51'
const fileName = args.o || 'output.png'
const lineHeight = args.h || 2
const spacing = args.w || 3
const fontSize = 12

const attrValue = {
    "1":"LETTER",
    "2":"SPACE",
    "3":"POSSIBLE_VACAT",
    "4":"VACAT",
    "5":"DAMAGE",
    "6":"BLANK LINE",
    "7":"PARAGRAPH_MARKER",
    "8":"LACUNA",
    "9":"BREAK",
    "10":"LINE_START",
    "11":"LINE_END",
    "12":"COLUMN_START",
    "13":"COLUMN_END",
    "14":"SCROLL_START",
    "15":"SCROLL_END",
    "16":"",
    "17":"MIGHT_BE_WIDER",
    "18":"INCOMPLETE_BUT_CLEAR",
    "19":"INCOMPLETE_AND_NOT_CLEAR",
    "20":"IS_RECONSTRUCTED",
    "21":"CONJECTURE",
    "22":"SHOULD_BE_ADDED",
    "23":"SHOULD_BE_DELETED",
    "24":"OVERWRITTEN",
    "25":"HORIZONTAL_LINE",
    "26":"DIAGONAL_LEFT_LINE",
    "27":"DIAGONAL_RIGHT_LINE",
    "28":"DOT_BELOW",
    "29":"DOT_ABOVE",
    "30":"LINE_BELOW",
    "31":"LINE_ABOVE",
    "32":"BOXED",
    "33":"ERASED",
    "34":"ABOVE_LINE",
    "35":"BELOW_LINE",
    "36":"LEFT_MARGIN",
    "37":"RIGHT_MARGIN",
    "38":"MARGIN",
    "39":"UPPER_MARGIN",
    "40":"LOWER_MARGIN"
}

const buildCorpus = async () => {
    try {
        const lineData = await axios.post(
            'https://dev.qumranica.org/Scrollery/0_2_4/resources/cgi-bin/scrollery-cgi.pl',
            {
                transaction: "getLinesJSON",
                SESSION_ID: session_id,
                scroll_version_id: scrollVersionID,
                col_id: colID
            }
        )
        const signData = await axios.post(
            'https://dev.qumranica.org/Scrollery/0_2_4/resources/cgi-bin/scrollery-cgi.pl',
            {
                transaction: "getSignsJSON",
                SESSION_ID: session_id,
                scroll_version_id: scrollVersionID,
                col_id: colID
            }
        )
        const signCharData = await axios.post(
            'https://dev.qumranica.org/Scrollery/0_2_4/resources/cgi-bin/scrollery-cgi.pl',
            {
                transaction: "getSignCharsJSON",
                SESSION_ID: session_id,
                scroll_version_id: scrollVersionID,
                col_id: colID
            }
        )
        return {lineData, signData, signCharData}
    } catch(error) {
      console.log(chalk.red('We\'ve encountered an error'))
      console.error(error)
    }
}

const processLine = (signData, signCharData, startSign) => {
    let lineString = ''
    let length = 0
    let isSuperscript = false
    let isSubscript = false
    do {
        const sign = signCharData[signData[startSign].sign_char_ids[0]].sign
        let attrs = ''
        for (const attr of signCharData[signData[startSign].sign_char_ids[0]].attribute_values) {
            attrs += ` ${attrValue[attr]}`
            attrs += sign === '°' ? ' SPACE' : ''
        }
        if (!isSuperscript && attrs.indexOf('ABOVE_LINE') > -1) {
          lineString += '<sup>'
          isSuperscript = true
        }
        if (!isSubscript && attrs.indexOf('BELOW_LINE') > -1) {
          lineString += '<sub>'
          isSubscript = true
        }
        lineString += '<span'
        if (attrs) lineString += ` class="${attrs}"`
        if (sign !== '' || attrs.indexOf('SPACE') > -1) length++
        lineString += `>${sign === '°' ? '' : sign}</span>`
        if (isSubscript && attrs.indexOf('BELOW_LINE') === -1) {
          lineString += '</sub>'
          isSubscript = false
        }
        if (isSuperscript && attrs.indexOf('ABOVE_LINE') === -1) {
          lineString += '</sup>'
          isSuperscript = false
        }
    } while ((startSign = signData[startSign].next_sign_ids[0]) &&
                signCharData[signData[startSign].sign_char_ids].attribute_values.indexOf(11) < 0)
    return {lineString, length}
}

const processCol = async () => {
    let {lineData, signData, signCharData} = await buildCorpus()
    signData = signData.data.results.map(a => JSON.parse(a.sign)).reduce((obj, item) => {
        const k = Object.keys(item)[0]
     obj[k] = item[k]
     return obj
   }, {})
    signCharData = signCharData.data.results.map(a => JSON.parse(a.sign)).reduce((obj, item) => {
        const k = Object.keys(item)[0]
     obj[k] = item[k]
     return obj
   }, {})
   let longestLine = 0
   let numberOfLines = 0
   const css = `
   <style>
   @font-face {
        font-family: customFont;
        src: url(./${font});
    }
    
    p {
      line-height: ${lineHeight}px;   /* within paragraph */
      margin-bottom: 0px;
      font-family: "${font}";
      font-size: ${fontSize}px;
    }

    sup, sub {
      display:inline-block;
      width:0%;
      margin: 0;
    }
    
    span.SPACE {
      padding: ${spacing}px;
    }

    span.SPACE:after {
    content: '\\FEFF';
    }

    span.IS_RECONSTRUCTED {
    color: white;
    }

    span.LINE_START {
    margin-left: 1em;
    }

    span.INCOMPLETE_AND_NOT_CLEAR {
    //color: blue;
    }

    span.INCOMPLETE_BUT_CLEAR {
    //color: red;
    }

    sup {
    position: relative;
    top: -1em;
    font-size: 50%;
    vertical-align: top;
    //vertical-align: super;
    }

    sub {
    position: relative;
    font-size: 50%;
    bottom: -1em;
    vertical-align: bottom;
    }

    div.hide-reconstructed-text span.SCROLL_START {
    opacity: 0;
    }
</style>
   `
    let htmlString = `<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>title</title>
    ${css}
  </head>
  <body>
  <div dir="rtl" class="hide-reconstructed-text">`
    for (const line of lineData.data.results) {
        for (const sign of Object.keys(JSON.parse(line.line))) {
            numberOfLines++
            let {lineString, length} = processLine(signData, signCharData, JSON.parse(line.line)[sign].line_sign_id)
            if (length > longestLine) longestLine = length
            htmlString += `<p>${lineString}</p>`
        }       
    }
    htmlString += `
    </div>
  </body>
</html>`
    const browser = await puppeteer.launch({
        headless: false,
        ignoreHTTPSErrors: true,
        timeout: 1000
    })
    const page = await browser.newPage();

    await page.setRequestInterception(true)
    page.on('request', request => {
        if (request.resourceType === 'Script') {
            request.abort();
        } else {
            request.continue();
        }
    })
    //console.log(htmlString)
    await page.goto('data:text/html;charset=UTF-8,' + htmlString, {waitUntil: 'networkidle0'})
    page.setViewport({width: Math.floor(longestLine * fontSize * 0.75), height: Math.floor(numberOfLines * (lineHeight + fontSize) * fontSize * 0.1), deviceScaleFactor: 3})
    await page.screenshot({path: fileName,
        clip: {x: 0, y:0, width: Math.floor(longestLine * fontSize * 0.75), height: Math.floor(numberOfLines * (lineHeight + fontSize) * fontSize * 0.1)}
    })

    browser.close()
    console.log(chalk.green('Success!')) 
    console.log(chalk.blue(` Output image of scroll ${scrollVersionID}, column ${colID} to ${fileName} using the ${font} font.`))
    process.exit() 
}

processCol()