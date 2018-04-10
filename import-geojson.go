/*
** This program reads a directory full of GeoJSON
** files with the polygon clipping data for the
** IAA images.  It parses and repairs them, then
** it inserts them into the database.  The folder
** containing the GeoJSON files is hard coded at
** line 41.
 */
package main

import (
	"database/sql"
	"encoding/json"
	"io/ioutil"
	"log"
	"strings"

	//"github.com/Bronson-Brown-deVost/gosqljson"
	"fmt"
	"unicode"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB
var err error
var failedFiles []string

var polygons struct {
	Type        string    `json:"type"`
	Coordinates [][][]int `json:"coordinates"`
}

func init() {
	db, err = sql.Open("mysql", "root:none@tcp(localhost:3307)/SQE_DEV?charset=utf8")
	checkErr(err, "n")
	db.SetMaxOpenConns(100)
}

func main() {
	dir := "/Users/bronson/School/Programming/JSON1/"
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range files {
		readFile(dir, f.Name())
	}

	println("Finished inserting records.")
	if len(failedFiles) > 0 {
		println("Some files failed.")
		for i, v := range failedFiles {
			println(fmt.Sprintf("%d - %s", i, v))
		}
	}

	// insertRecord(record, filename)
}

func checkErr(err error, img string) {
	if err != nil {
		failedFiles = append(failedFiles, img)
		panic(err)
	}
}

/*
** The GeoJSON files from Tel Aviv typically need a number
** of fixes for malformed JSON.  The following catches all
** cases I ran up against.
 */
func readFile(dir string, file string) {
	println("Starting: " + file)
	poly, err := ioutil.ReadFile(dir + file)
	checkErr(err, "n")
	data := string(poly)
	data = strings.Replace(data, "][", "],[", -1)
	data = strings.Replace(data, "][", "],[", -1)
	data = strings.Replace(data, "]\n	\"", "],\"", -1)
	data = strings.Replace(data, ",	]", "	]", -1)
	data = strings.Replace(data, "],	]", "	]", -1)
	err = json.Unmarshal([]byte(data), &polygons)
	checkErr(err, "n")
	processed, err := json.Marshal(polygons)
	checkErr(err, "n")
	insertRecord(string(processed[:]), dir, file)
}

func insertRecord(record string, dir string, filename string) {
	img := strings.Split(filename, "json")[0]
	img = strings.Replace(img, " ", "", -1)
	img = img + "tif"

	rows, err := db.Query(
		`
SELECT sqe_image_id, 
	composition, 
	edition_location_1, 
	edition_location_2, 
	scroll_version_id
FROM SQE_image
	JOIN edition_catalog USING(edition_catalog_id)
	JOIN scroll_data USING(scroll_id)
	JOIN scroll_data_owner USING(scroll_data_id)
WHERE filename=?`,
		img)
	checkErr(err, "n")
	var sqeID int
	var composition string
	var loc_1 string
	var loc_2 string
	var scrollVerID int
	for rows.Next() {
		err = rows.Scan(&sqeID, &composition, &loc_1, &loc_2, &scrollVerID)
		checkErr(err, "n")
	}

	if sqeID != 0 {
		data, err := db.Exec(
			`
	INSERT INTO artefact (region_in_master_image, sqe_image_id) 
		VALUES (ST_GeomFromGeoJSON(?), ?) 
	ON DUPLICATE KEY UPDATE artefact_id=LAST_INSERT_ID(artefact_id)`,
			record, sqeID)
		checkErr(err, img)
		var artID int64
		artID, err = data.LastInsertId()

		data, err = db.Exec(
			`
	INSERT INTO artefact_owner (artefact_id, scroll_version_id) 
		VALUES (?, ?)`,
			artID, scrollVerID)
		checkErr(err, img)

		data, err = db.Exec(
			`
	INSERT INTO artefact_data (artefact_id, name) 
		VALUES (?, ?) 
	ON DUPLICATE KEY UPDATE artefact_data_id=LAST_INSERT_ID(artefact_data_id)`,
			artID, fmt.Sprintf("%s - %s - %s", composition, loc_1, loc_2))
		checkErr(err, img)
		var artDataID int64
		artDataID, err = data.LastInsertId()

		data, err = db.Exec(
			`
	INSERT INTO artefact_data_owner (artefact_data_id, scroll_version_id) 
		VALUES (?, ?)`,
			artDataID, scrollVerID)
		checkErr(err, img)

		println("Done with: " + img)
	} else {
		failedFiles = append(failedFiles, img)
		println("Failed with: " + img)
	}

}

func stripSpaces(str string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			// if the character is a space, drop it
			return -1
		}
		// else keep it in the string
		return r
	}, str)
}
