# Database structure

The main organizing table to which every other SQE data table eventually links is the _scroll_ table via a version specified in the _scroll_version_ and corresponding _scroll_version_group_.  That table constitutes an abstract container within which various GIS positional entities can be placed (see the _artefact_position_/_artefact_shape_ and *real_char_area* tables).  These positioned entities then link outward to other data and metadata:

# Image data via *artefact_position* → *artefact* → *SQE_image* (etc.)
# Text data via *real_char_area* → *sign*
## *sign* → *sign_char* → *sign_char_reading_data*
## *sign* → *sign_relative_position*
## *sign* → *position_in_stream* → *position_in_stream_to_word_rel* → *word* (etc.)
## *sign* → *line_to_sign* → *line* → *col_to_line* → *col* (and all related tables)

The *scroll_version* is also linked to tables containing only metadata, such as *scroll_data*, *form_of_writing*, *char_of_writing*, *word*, and *sign_relative_position*, among others.

h2. Textual data

The primary table for text transcriptions is the abstract *sign* table.  The textual transcriptions are organized primarily through a linked list of *sign* table entries via entries in the *position_in_stream* table, thus creating a *sign stream*.  This *position_in_stream* table establishes the order of signs and contains the entire corpus of literature in the database.  Each sign in the sign stream can be referenced by an entry in the *line_to_sign* table.  Lines can be grouped into columns in the *col_to_line* table, and columns are collected into scrolls via the *scroll_to_col* table.

The *sign* table entries also link to a number of tables providing metadata for that sign, such as *real_char_area* for GIS positional data of the ink mark(s) that make(s) up the character, or *sign_char* → *sign_char_reading_data* for textual information about the sign reading and various editorial observations about it.

h2.  Image data

The image data, consists of images from the providing institution (generally the IAA), the reference to which is stored in the *SQE_image* table.  This table may contain many variant images of the same subject, for instance, images taken at various wavelengths.  When multiple images of the same subject exist, one image is marked in the *SQE_image* table as the master, and all others are linked to it via the table *image_to_image_map* which contains the relevant information to align the secondary image to the master (i.e., sizing, translation, and rotation).  

Each image contains more than simply the information related to a fragment; at the very least it contains a background which is generally irrelevant to material analysis.  For this reason, each image is further reduced into artefacts in the *artefact* table, which specifies the polygonal coordinates within the image where the distinct material remains are located.  Each image will contain at least one artefact, and artefacts can be linked to a scroll with specific coordinates within that scroll in the *artefact_position* table ([[SQE_Database_Structure#Linking-of-image-and-text|see linking of text and image]]).

h2.  Linking of image and text

The linkage between images (via *artefact_position*) and textual data (via *real_char_area*) is accomplished via the GIS positional data.  Thus if one wants to find the characters in a certain location on a scoll fragment, one would search the *real_char_area* table entries that are linked to the scroll version for all entries that occupy that region in the scroll's coordinate system.

!screenshot_1_1512910365_Sign_to_ink_linking.png!

h2.  Version management

The SQE database uses a model in which data table entries are never altered or deleted.  Rather, when a user wishes to delete some datum from the scroll (or "combination") they are working on, that table entry is simply unlinked from the current scroll version.  When a user wishes to change a value in any entry, that entry is copied into a new entry with the desired alterations.  The old entry is unlinked from the current combination version and the new entry is linked in its place.  For example, the table *sign_char* contains information about a single sign within the sign stream, an example of which is the following: 

|_.sign_char_id |_.sign_id |_.is_variant |_.sign_type_id |_.break_type |_.sign |_.width |_.might_be_wider |_.vocalization |
| 2 | 2 | 0 | 1 | NULL | ל | 1.00 | 0 | NULL |

If a user wished to change the sign reading in this entry from ל to ב, the actual entry is not altered, rather it is duplicated to a new entry with a new id and the desired change in data:

|_.sign_char_id |_.sign_id |_.is_variant |_.sign_type_id |_.break_type |_.sign |_.width |_.might_be_wider |_.vocalization |
| 1987239 | 2 | 0 | 1 | NULL | ב | 1.00 | 0 | NULL |

Every table with data that can be altered by users has a corresponding table linking it to user versions in the format _table name__owner.  In this example the corresponding owner table to *sign_char* is *sign_char_owner*, and it would be updated as follows.  

First we delete the link to the old entry:

|._sign_char_id |._scroll_version_id |
| 2 | 13425 |

Then we create a link to the new entry:

|._sign_char_id |._scroll_version_id |
| 1987239 | 13425 |

The old entry in *sign_char* is not deleted for several reasons: firstly, the database tracks every alteration to _owner_ tables so that the user may undo or redo any alterations; and secondly, that old entry may still be in use by another scroll version, or might be used again in the future.