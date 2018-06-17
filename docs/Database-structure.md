- [Database structure](#database-structure)
- [Textual data](#textual-data)
  - [Text order](#text-order)
  - [Mapping to lines and columns](#mapping-to-lines-and-columns)
  - [Sign metadata](#sign-metadata)
    - [Geometric metadata](#geometric-metadata)
    - [Textual metadata](#textual-metadata)
- [Image data](#image-data)
  - [Artefact polygons](#artefact-polygons)
  - [Artefact position](#artefact-position)
- [Linking of image and text](#linking-of-image-and-text)
- [Version management](#version-management)

# Database structure

The main organizing table to which every other SQE data table eventually links is the **scroll** table via a version specified in the **scroll_version** and corresponding **scroll_version_group** (for shared scroll combinations).  That **scroll** table constitutes an abstract container within which various positional entities can be situated (see the **artefact_position**/**artefact_shape** and **roi_position**/**roi_shape** tables).  These positioned entities then link outward to other data and metadata:

- Image data via **artefact_position** → **artefact_shape** → **SQE_image** (etc.)
- Text data via **roi_position** → **sign_char_roi** → **sign_char** → **sign**
  - **sign** → **sign_char** → **sign_char_attribute** → **attribute_value** → **attribute**
  - **sign** → **position_in_stream** → **position_in_stream_to_word_rel** → **word** (etc.)
  - **sign** → **line_to_sign** → **line** → **col_to_line** → **col** (and all related tables)

The **scroll_version** is also linked via an X_owner table to tables containing metadata, such as **scroll_data_owner** for **scroll_data**, **form_of_writing_owner** for **form_of_writing**, **char_of_writing_owner** for **char_of_writing**, etc.

# Textual data

The primary table for text transcriptions is the abstract **sign** table.  The textual transcriptions are organized primarily through a linked list of **sign** table entries via entries in the **position_in_stream** table, thus creating a sign stream.

## Text order

The reading order of the transcribed text is not dictated by its position in a column or a line, as might be expected in more traditional transcription systems.  It is the **position_in_stream** table that establishes the order of signs and contains the entire corpus of literature in the database.  Each sign may have multiple entries in the **position_in_stream** table, thus allowing multiple diverging and converging reading orders, hence the term stream.

## Mapping to lines and columns

Each sign in the sign stream can be referenced by an entry in the **line_to_sign** table, thus attaching a sign to a line.  Lines can be grouped into columns in the **col_to_line** table, and columns are collected into scrolls via the **scroll_to_col** table.

## Sign metadata

The **sign** table entries also link to a number of tables providing metadata for that sign via the table **sign_char**.  This metadata may be positional data for the ink mark(s) that make(s) up the character as found in **roi_position** and **roi_shape** (linked via **sign_char** → **sign_char_roi**), or textual information about the sign reading and various editorial observations about it.

### Geometric metadata

The shape of the ink marks or "regions of interest" that make up a character and its position within a virtual scroll are stored in two tables: **roi_shape** and **roi_position**.  The path for the outline of the ink mark is stored as a vector polygon.  Currently the database stores this as binary data, but it can input and output both WKT and GeoJSON representations.  The position of the ink mark is stored as a 2D transform matrix in the format [[x<sub>1</sub>,x<sub>2</sub>,tx],[y<sub>1</sub>,y<sub>2</sub>,ty]].  A digital representation of the path within the coordinate system of the virtual scroll is accomplished by applying the transform matrix to each point in the path of the roi_shape.

### Textual metadata

A **sign** may have one or more linked **sign_char** entries (if more than one, then one linked entry in **sign_char** will have a value of 0 for the column **is_variant** and the others will have a value of 1).  Each **sign_char** may have one or more linked attributes via **sign_char_attribute** which can be applied in any desired sequence.  User defined attributes can be created by adding a new entry to the **attribute** table and its possible values to the **attribute_value** table.

# Image data

The image data consists of IIIF Image API references to images from the providing institution (generally the IAA) stored in the **SQE_image** table.  This table may contain many variant images of the same subject, for instance, images taken at various wavelengths or lighting schemes.  When multiple images of the same subject exist, one image is marked in the **SQE_image** table as the master, and all others are linked to it via the table **image_to_image_map** which contains the relevant information to align the secondary image to the master (i.e., sizing, translation, and rotation).  

## Artefact polygons

Each image contains more than simply the information related to a scroll fragment; at the very least it contains a background which is generally irrelevant to material analysis.  For this reason, each image is further reduced into artefacts in the **artefact_shape** table, which specifies the polygonal coordinates within the image where the distinct material remains are located.  The path for the outline of the artefact is stored as a vector polygon in **artefact_shape**.  Currently the database stores this as binary data, but it can input and output both WKT and GeoJSON representations.

## Artefact position

Artefacts can be linked to a virtual scroll and positioned within that scroll via a transform matrix stored in the **artefact_position** table.  The position of the artefact is stored as a 2D transform matrix in **artefact_position** with the format [[x<sub>1</sub>,x<sub>2</sub>,tx],[y<sub>1</sub>,y<sub>2</sub>,ty]].  A digital representation of the artefact shape within the coordinate system of the virtual scroll is accomplished by applying the transform matrix from **artefact_position** to each point in the path of the corresponding **artefact_shape**.

# Linking of image and text

The linkage between images (via **artefact_position**/**artefact_shape**) and textual data (via **roi_position**/**roi_shape**) is accomplished by computational analysis of the geometric data.  Thus if one wants to find the characters situated in a certain location on a scoll fragment, one would read all **roi_shape** entries belonging to the scroll_version_id and then transform them using the corresponding data in  **roi_position**.  Then each ROI can be tested to see if it occupies any part of the specified location in the virtual scroll (this can be sped up with a two-pass algorithm).

![SQE geometric mapping](./SQE_Ink_to_Char_mapping.png)

# Version management

The SQE database uses a model in which data table entries are never altered or deleted.  Rather, when a user wishes to delete some datum from the scroll (or "combination") they are working on, that table entry is simply unlinked from the current **scroll_version_id** in the relevant **X_owner** table.  When a user wishes to change a value in any entry, that entry is copied into a new entry with the desired alterations.  The old entry is unlinked from the current **scroll_version_id** and the new entry is linked in its place.  For example, the table **sign_char** contains information about a single sign within the sign stream, an example of which is the following: 

| sign_char_id | sign_id | is_variant | sign_type_id | break_type | sign | width | might_be_wider | vocalization |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2 | 2 | 0 | 1 | NULL | ל | 1.00 | 0 | NULL |

If a user wished to change the sign reading in this entry from ל to ב, the actual entry is not altered, rather it is duplicated to a new entry with a new id and the desired change in data:

| sign_char_id | sign_id | is_variant | sign_type_id | break_type | sign | width | might_be_wider | vocalization |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1987239 | 2 | 0 | 1 | NULL | ב | 1.00 | 0 | NULL |

Every table with data that can be altered by users has a corresponding table linking it to user versions in the format **table-name_owner**.  In this example the corresponding owner table to **sign_char** is **sign_char_owner**, and it would be updated as follows.  

First we delete the link to the old entry:

| sign_char_id | scroll_version_id |
| :---: | :---: |
| 2 | 13425 |

Then we create a link to the new entry:

| sign_char_id | scroll_version_id |
| :---: | :---: |
| 1987239 | 13425 |

The old entry in **sign_char** is not deleted for several reasons: firstly, the database tracks every alteration to **owner** tables so that the user may undo or redo any alterations; and secondly, that old entry may still be in use by another scroll version, or might be used again in the future.