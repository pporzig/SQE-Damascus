/*
 Navicat Premium Data Transfer

 Source Server         : LocalHost
 Source Server Type    : MariaDB
 Source Server Version : 100212
 Source Host           : localhost:3306
 Source Schema         : SQE

 Target Server Type    : MariaDB
 Target Server Version : 100212
 File Encoding         : 65001

 Date: 01/02/2018 13:00:30
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for SQE_image
-- ----------------------------
DROP TABLE IF EXISTS `SQE_image`;
CREATE TABLE `SQE_image` (
  `sqe_image_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `image_urls_id` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Link to image_urls table which contains the url of the iiif server that provides this image and the default suffix used to get images from that server.',
  `filename` varchar(128) NOT NULL DEFAULT '''''' COMMENT 'Filename of the image, which matches exactly the filename of the image on the provider''s image server.',
  `native_width` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'We store internally the pixel width of the full size image.',
  `native_height` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'We store internally the pixel height of the full size image.',
  `dpi` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The DPI of the full size image (used to calculate relative scaling of images).',
  `type` tinyint(1) unsigned NOT NULL DEFAULT 0 COMMENT 'Two values:\nColor = 0\nGrayscale = 1\nPerhaps remove in favor of “wavelength_start" and “wavelength_end”.',
  `wavelength_start` smallint(5) unsigned NOT NULL DEFAULT 445 COMMENT 'Starting wavelength of image in nanometers.',
  `wavelength_end` smallint(5) unsigned NOT NULL DEFAULT 704 COMMENT 'Ending wavelength of image in nanometers.',
  `is_master` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Boolean determining if the image is a “master image”.  Since we have multiple images of each fragment, one image is designated as the master (generally the full color image), all others are non master images and will have a corresponding entry in “image_to_image_map” which provides and transforms (translate, scale, rotate) necessary to line the two images up with each other.',
  `image_catalog_id` int(11) unsigned DEFAULT 0,
  `edition_catalog_id` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`sqe_image_id`),
  UNIQUE KEY `url_UNIQUE` (`image_urls_id`,`filename`) USING BTREE,
  KEY `fk_image_to_edition` (`edition_catalog_id`),
  KEY `fk_image_to_catalog` (`image_catalog_id`),
  CONSTRAINT `fk_image_to_catalog` FOREIGN KEY (`image_catalog_id`) REFERENCES `image_catalog` (`image_catalog_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_image_to_edition` FOREIGN KEY (`edition_catalog_id`) REFERENCES `edition_catalog` (`edition_catalog_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_image_to_url` FOREIGN KEY (`image_urls_id`) REFERENCES `image_urls` (`image_urls_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=7374 DEFAULT CHARSET=utf8 COMMENT='This table defines an image.  It contains referencing data to access the image via iiif servers, it also stores metadata relating to the image itself, such as sizing, resolution, image color range, etc.  It also maintains a link to the institutional referencing system, and the referencing of the editio princeps (as provided by the imaging institution).';

-- ----------------------------
-- Table structure for area_group
-- ----------------------------
DROP TABLE IF EXISTS `area_group`;
CREATE TABLE `area_group` (
  `area_group_id` int(10) unsigned NOT NULL,
  `area_id` int(10) unsigned NOT NULL,
  `move_direction` set('x','y') NOT NULL DEFAULT '',
  `name` varchar(45) DEFAULT NULL,
  `commentary` text DEFAULT NULL,
  `z_index` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`area_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for area_group_member
-- ----------------------------
DROP TABLE IF EXISTS `area_group_member`;
CREATE TABLE `area_group_member` (
  `area_group_id` int(10) unsigned NOT NULL,
  `area_id` int(11) NOT NULL,
  `area_type` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`area_group_id`,`area_id`),
  CONSTRAINT `fk_group_member_to_group` FOREIGN KEY (`area_group_id`) REFERENCES `area_group` (`area_group_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for area_group_owner
-- ----------------------------
DROP TABLE IF EXISTS `area_group_owner`;
CREATE TABLE `area_group_owner` (
  `area_group_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`area_group_id`,`scroll_version_id`),
  KEY `fk_area_group_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_area_group_owner_to_area_group` FOREIGN KEY (`area_group_id`) REFERENCES `area_group` (`area_group_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_area_group_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for artefact
-- ----------------------------
DROP TABLE IF EXISTS `artefact`;
CREATE TABLE `artefact` (
  `artefact_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `region_in_master_image` polygon DEFAULT NULL COMMENT 'This is the exact polygon of the artefact’s location within the master image’s coordinate system.',
  `owner_id` smallint(6) NOT NULL,
  `date_of_adding` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Deprecated, do not use.',
  `commentary` text DEFAULT NULL,
  `sqe_image_id` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'This points to the master image (see SQE_image table) in which this artefact is found.',
  PRIMARY KEY (`artefact_id`,`sqe_image_id`),
  KEY `fk_artefact_to_image_idx` (`sqe_image_id`),
  KEY `artefact_id` (`artefact_id`),
  CONSTRAINT `fk_artefact_to_image` FOREIGN KEY (`sqe_image_id`) REFERENCES `SQE_image` (`sqe_image_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3067 DEFAULT CHARSET=utf8 COMMENT='Every scroll combination is made up from artefacts.  The artefact is a polygon region of an image which the editor deems to constitute a coherent piece of material (different editors may come to different conclusions on what makes up an artefact).  This may correspond to what the editors of an editio princeps have designated a “fragment”, but often may not, since the columns and fragments in those publications are often made up of joins of various types.  Joined fragments should not, as a rule, be defined as a single artefact with the SQE system.  Rather, each component of a join should be a separate artefact, and those artefacts can then be positioned properly with each other via the artefact_position table.';

-- ----------------------------
-- Table structure for artefact_owner
-- ----------------------------
DROP TABLE IF EXISTS `artefact_owner`;
CREATE TABLE `artefact_owner` (
  `artefact_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `scroll_version_id` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`artefact_id`,`scroll_version_id`),
  KEY `fk_artefact_owner_to_scroll_version` (`scroll_version_id`),
  CONSTRAINT `fk_artefact_owner_to_artefact` FOREIGN KEY (`artefact_id`) REFERENCES `artefact` (`artefact_id`),
  CONSTRAINT `fk_artefact_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3067 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for artefact_position
-- ----------------------------
DROP TABLE IF EXISTS `artefact_position`;
CREATE TABLE `artefact_position` (
  `artefact_position_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `artefact_id` int(10) unsigned NOT NULL,
  `position_in_scroll` point DEFAULT point(0,0) COMMENT 'X,Y location of artefact in scroll.',
  `z_index` tinyint(4) DEFAULT NULL COMMENT 'This value can move artefacts up or down in relation to other artefacts in the scroll.',
  `rotation` float unsigned NOT NULL DEFAULT 0 COMMENT 'Rotation of artefact in scroll.',
  `artefact_in_scroll` polygon DEFAULT NULL,
  `scroll_id` int(10) unsigned DEFAULT NULL,
  `commentary` text DEFAULT NULL,
  `date_of_adding` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`artefact_position_id`),
  KEY `fk_artefact_position_to_artefact` (`artefact_id`),
  KEY `fk_artefact_position_to_scroll` (`scroll_id`),
  CONSTRAINT `fk_artefact_position_to_artefact` FOREIGN KEY (`artefact_id`) REFERENCES `artefact` (`artefact_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_artefact_position_to_scroll` FOREIGN KEY (`scroll_id`) REFERENCES `scroll` (`scroll_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1462 DEFAULT CHARSET=utf8 COMMENT='This table defines the location and rotation of an artefact within the scroll.';

-- ----------------------------
-- Table structure for artefact_position_owner
-- ----------------------------
DROP TABLE IF EXISTS `artefact_position_owner`;
CREATE TABLE `artefact_position_owner` (
  `artefact_position_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `scroll_version_id` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`artefact_position_id`,`scroll_version_id`),
  KEY `fk_artefact_position_owner_to_scroll_version` (`scroll_version_id`),
  CONSTRAINT `fk_artefact_position_owner_to_artefact` FOREIGN KEY (`artefact_position_id`) REFERENCES `artefact_position` (`artefact_position_id`),
  CONSTRAINT `fk_artefact_position_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1462 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for char_of_writing
-- ----------------------------
DROP TABLE IF EXISTS `char_of_writing`;
CREATE TABLE `char_of_writing` (
  `char_of_writing_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `form_of_writing_id` int(11) unsigned NOT NULL DEFAULT 0,
  `unicode_char` char(1) NOT NULL DEFAULT '' COMMENT 'Unicode representation of the character read on the manuscript.',
  `width` smallint(5) unsigned NOT NULL DEFAULT 1000,
  `height` smallint(5) unsigned NOT NULL DEFAULT 1000,
  `line_offset` smallint(6) NOT NULL DEFAULT 0,
  `path` multipolygon DEFAULT NULL,
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`char_of_writing_id`,`form_of_writing_id`),
  UNIQUE KEY `form_char` (`form_of_writing_id`,`unicode_char`),
  KEY `form_of_writing` (`form_of_writing_id`),
  KEY `char` (`unicode_char`),
  CONSTRAINT `fk_to_form_of_writing` FOREIGN KEY (`form_of_writing_id`) REFERENCES `form_of_writing` (`form_of_writing_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table stores info about the characters of a particular scribal hand.';

-- ----------------------------
-- Table structure for char_of_writing_owner
-- ----------------------------
DROP TABLE IF EXISTS `char_of_writing_owner`;
CREATE TABLE `char_of_writing_owner` (
  `char_of_writing_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`char_of_writing_id`,`scroll_version_id`),
  KEY `cow_owner_to_scrollversion_idx` (`scroll_version_id`),
  CONSTRAINT `cow_owner_to_cow` FOREIGN KEY (`char_of_writing_id`) REFERENCES `char_of_writing` (`char_of_writing_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `cow_owner_to_scrollversion` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for col
-- ----------------------------
DROP TABLE IF EXISTS `col`;
CREATE TABLE `col` (
  `col_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`col_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11177 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for col_data
-- ----------------------------
DROP TABLE IF EXISTS `col_data`;
CREATE TABLE `col_data` (
  `col_data_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `col_id` int(10) unsigned NOT NULL,
  `name` varchar(45) NOT NULL DEFAULT '''''' COMMENT 'Unique name for the reconstructed column (should not be the same as any other column in the scroll).',
  PRIMARY KEY (`col_data_id`),
  KEY `fk_col_data_to_col_idx` (`col_id`),
  CONSTRAINT `fk_col_data_to_col` FOREIGN KEY (`col_id`) REFERENCES `col` (`col_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11177 DEFAULT CHARSET=utf8 COMMENT='This table defines the properties of a column of text within a scroll.';

-- ----------------------------
-- Table structure for col_data_owner
-- ----------------------------
DROP TABLE IF EXISTS `col_data_owner`;
CREATE TABLE `col_data_owner` (
  `col_data_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`col_data_id`,`scroll_version_id`),
  KEY `fk_col_data_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_col_data_owner_to_col_data` FOREIGN KEY (`col_data_id`) REFERENCES `col_data` (`col_data_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_col_data_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for col_to_line
-- ----------------------------
DROP TABLE IF EXISTS `col_to_line`;
CREATE TABLE `col_to_line` (
  `col_to_line_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `col_id` int(10) unsigned NOT NULL,
  `line_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`col_to_line_id`),
  UNIQUE KEY `col_line_idx` (`col_id`,`line_id`),
  KEY `fk_col_to_line_to_line_idx` (`line_id`),
  CONSTRAINT `fk_col_to_line_to_col` FOREIGN KEY (`col_id`) REFERENCES `col` (`col_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_col_to_line_to_line` FOREIGN KEY (`line_id`) REFERENCES `line` (`line_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=54448 DEFAULT CHARSET=utf8 COMMENT='This table links lines of a scroll to a specific column.';

-- ----------------------------
-- Table structure for col_to_line_owner
-- ----------------------------
DROP TABLE IF EXISTS `col_to_line_owner`;
CREATE TABLE `col_to_line_owner` (
  `col_to_line_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`col_to_line_id`,`scroll_version_id`),
  KEY `fk_col_to_linew_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_col_to_line_owner_to_col_to_line` FOREIGN KEY (`col_to_line_id`) REFERENCES `col_to_line` (`col_to_line_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_col_to_linew_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for discrete_canonical_references
-- ----------------------------
DROP TABLE IF EXISTS `discrete_canonical_references`;
CREATE TABLE `discrete_canonical_references` (
  `discrete_canonical_reference_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scroll_id` int(10) unsigned NOT NULL DEFAULT 0,
  `column_name` varchar(85) DEFAULT NULL,
  `fragment_name` varchar(85) DEFAULT NULL,
  `sub_fragment_name` varchar(85) DEFAULT NULL,
  `fragment_column` tinyint(3) unsigned DEFAULT NULL,
  `side` tinyint(3) unsigned DEFAULT NULL COMMENT '1 for recto, 2 for verso',
  `column_of_scroll_id` int(10) unsigned DEFAULT 0,
  PRIMARY KEY (`discrete_canonical_reference_id`),
  KEY `fk_discrete_can_ref_to_scroll_idx` (`scroll_id`),
  KEY `fk_discrete_can_ref_to_col_idx` (`column_of_scroll_id`),
  CONSTRAINT `fk_discrete_can_ref_to_col` FOREIGN KEY (`column_of_scroll_id`) REFERENCES `col` (`col_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_discrete_can_ref_to_scroll` FOREIGN KEY (`scroll_id`) REFERENCES `scroll` (`scroll_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=12666 DEFAULT CHARSET=utf8 COMMENT='This is table is a bit of a hack and contains many incorrect assignments.  It is intended as a method to match textual transcriptions and images to their canonical references (mainly in DJD).  This table was automatically populated by data from the IAA and from the QWB.  The main problem is that the IAA refers to plate references in the DJD, whereas the QWB transcriptions reference the transcriptions in DJD.  What is more, in the case of joins in DJD, QWB references only the full join, not its constituent parts, so there i currently no way to determine which part of the transcription belongs to which fragment, nor was it possible to even know the constituent fragments when notation like frg. 10a–13 is used.\n\nThis table should be able to address discretely every type of reference in the official publications of the scrolls.';

-- ----------------------------
-- Table structure for edition_catalog
-- ----------------------------
DROP TABLE IF EXISTS `edition_catalog`;
CREATE TABLE `edition_catalog` (
  `edition_catalog_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `composition` varchar(128) NOT NULL DEFAULT '''''' COMMENT 'Canonical name of the scroll.',
  `edition_name` varchar(45) NOT NULL DEFAULT '''''' COMMENT 'Name of the edition princeps.',
  `edition_volume` varchar(45) DEFAULT 'NULL' COMMENT 'Volume of the editio princeps.',
  `edition_location_1` varchar(45) DEFAULT 'NULL' COMMENT 'Top level reference in the editio princeps (perhaps a column reference or fragment number).',
  `edition_location_2` varchar(45) DEFAULT 'NULL' COMMENT 'Sub reference designation in editio princeps.',
  `edition_side` tinyint(1) unsigned NOT NULL DEFAULT 0 COMMENT 'Side designation in editio princeps.',
  PRIMARY KEY (`edition_catalog_id`),
  UNIQUE KEY `unique_edition_entry` (`edition_location_1`,`edition_location_2`,`edition_name`,`edition_side`,`edition_volume`,`composition`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=34647 DEFAULT CHARSET=utf8 COMMENT='This table contains the IAA data for the editio princeps reference for all of their images.';

-- ----------------------------
-- Table structure for edition_catalog_to_discrete_reference
-- ----------------------------
DROP TABLE IF EXISTS `edition_catalog_to_discrete_reference`;
CREATE TABLE `edition_catalog_to_discrete_reference` (
  `edition_catalog_id` int(10) unsigned NOT NULL DEFAULT 0,
  `discrete_canonical_reference_id` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`edition_catalog_id`,`discrete_canonical_reference_id`),
  KEY `fk_ed_cat_to_disc_ref_to_disc_can_ref_id` (`discrete_canonical_reference_id`),
  CONSTRAINT `fk_ed_cat_to_disc_ref_to_disc_can_ref_id` FOREIGN KEY (`discrete_canonical_reference_id`) REFERENCES `discrete_canonical_references` (`discrete_canonical_reference_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_ed_cat_to_disc_ref_to_edition_id` FOREIGN KEY (`edition_catalog_id`) REFERENCES `edition_catalog` (`edition_catalog_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Binding of IAA image reference system to the fuller discrete reference system.';

-- ----------------------------
-- Table structure for external_font
-- ----------------------------
DROP TABLE IF EXISTS `external_font`;
CREATE TABLE `external_font` (
  `external_font_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `font_id` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`external_font_id`),
  UNIQUE KEY `font_id_idx` (`font_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for external_font_glyph
-- ----------------------------
DROP TABLE IF EXISTS `external_font_glyph`;
CREATE TABLE `external_font_glyph` (
  `external_font_glyph_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `external_font_id` int(10) unsigned NOT NULL,
  `unicode_char` varbinary(4) NOT NULL,
  `path` multipolygon NOT NULL,
  `width` smallint(6) DEFAULT NULL,
  `height` smallint(5) unsigned DEFAULT NULL,
  PRIMARY KEY (`external_font_glyph_id`),
  UNIQUE KEY `char_idx` (`unicode_char`) USING BTREE,
  KEY `fk_efg_to_external_font_idx` (`external_font_id`),
  CONSTRAINT `fk_efg_to_external_font` FOREIGN KEY (`external_font_id`) REFERENCES `external_font` (`external_font_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2371 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for form_of_writing
-- ----------------------------
DROP TABLE IF EXISTS `form_of_writing`;
CREATE TABLE `form_of_writing` (
  `form_of_writing_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `scribes_scribe_id` int(10) unsigned NOT NULL,
  `pen` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `ink` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `scribal_font_type_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`form_of_writing_id`),
  KEY `fk_form_to_scribe_idx` (`scribes_scribe_id`),
  KEY `fk_form_to_char_style_idx` (`scribal_font_type_id`),
  CONSTRAINT `fk_form_to_char_style` FOREIGN KEY (`scribal_font_type_id`) REFERENCES `scribal_font_type` (`scribal_font_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_form_to_scribe` FOREIGN KEY (`scribes_scribe_id`) REFERENCES `scribe` (`scribe_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='Defines the actual scribe of of sign. As actual scribe the scribe as person using at the very moment a special „font“ caused by the mood the scribe is in (conecentrated, sloppy, fast and furious) and the used equipment. Thus even change of quills or the status of a quill (fresh filled, new, old) could be distinguished. ';

-- ----------------------------
-- Table structure for form_of_writing_owner
-- ----------------------------
DROP TABLE IF EXISTS `form_of_writing_owner`;
CREATE TABLE `form_of_writing_owner` (
  `form_of_writing_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`form_of_writing_id`,`scroll_version_id`),
  KEY `fk_form_of_writing_to_scrollversion_idx` (`scroll_version_id`),
  CONSTRAINT `fk_form_of_writing_owner_to_scribe` FOREIGN KEY (`form_of_writing_id`) REFERENCES `form_of_writing` (`form_of_writing_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_form_of_writing_to_scrollversion` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for image_catalog
-- ----------------------------
DROP TABLE IF EXISTS `image_catalog`;
CREATE TABLE `image_catalog` (
  `image_catalog_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `institution` varchar(128) DEFAULT 'NULL' COMMENT 'Institution responsible for (and probably hosting) the image.',
  `catalog_number_1` varchar(45) DEFAULT 'NULL' COMMENT 'Top level catologue reference (often a “plate”).',
  `catalog_number_2` varchar(45) DEFAULT 'NULL' COMMENT 'Sub reference designation (often a “fragment”).',
  `catalog_side` tinyint(1) unsigned DEFAULT 0 COMMENT 'Side reference designation.',
  PRIMARY KEY (`image_catalog_id`),
  UNIQUE KEY `unique_catalog_entry` (`catalog_number_1`,`catalog_number_2`,`catalog_side`,`institution`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=34775 DEFAULT CHARSET=utf8 COMMENT='The referencing system of the institution providing the images.';

-- ----------------------------
-- Table structure for image_to_edition_catalog
-- ----------------------------
DROP TABLE IF EXISTS `image_to_edition_catalog`;
CREATE TABLE `image_to_edition_catalog` (
  `edition_catalog_id` int(11) unsigned NOT NULL DEFAULT 0,
  `image_catalog_id` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`edition_catalog_id`,`image_catalog_id`),
  KEY `fk_to_catalog_id` (`image_catalog_id`),
  CONSTRAINT `fk_to_catalog_id` FOREIGN KEY (`image_catalog_id`) REFERENCES `image_catalog` (`image_catalog_id`),
  CONSTRAINT `fk_to_edition_id` FOREIGN KEY (`edition_catalog_id`) REFERENCES `edition_catalog` (`edition_catalog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Temporary table to link image catalog info with edition info until the SQE_image table is fully populated.  Once that table is populated this one will become redundant.  This was autogenerated from IAA data.';

-- ----------------------------
-- Table structure for image_to_image_map
-- ----------------------------
DROP TABLE IF EXISTS `image_to_image_map`;
CREATE TABLE `image_to_image_map` (
  `image_to_image_map_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `image1_id` int(10) unsigned NOT NULL DEFAULT 0,
  `image2_id` int(10) unsigned NOT NULL DEFAULT 0,
  `region_on_image1` polygon NOT NULL,
  `region_on_image2` polygon NOT NULL,
  `rotation` decimal(6,3) NOT NULL DEFAULT 0.000,
  `map_type` enum('IMAGE_TO_MASTER','BACK_TO_FRONT') DEFAULT NULL,
  `validated` tinyint(1) NOT NULL DEFAULT 0,
  `date_of_adding` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`image_to_image_map_id`,`image1_id`,`image2_id`),
  KEY `fk_image1_to_image_id` (`image1_id`),
  KEY `fk_image2_to_image_id` (`image2_id`),
  CONSTRAINT `fk_image1_to_image_id` FOREIGN KEY (`image1_id`) REFERENCES `SQE_image` (`sqe_image_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_image2_to_image_id` FOREIGN KEY (`image2_id`) REFERENCES `SQE_image` (`sqe_image_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table contains the mapping information to correlate images of the same object.';

-- ----------------------------
-- Table structure for image_urls
-- ----------------------------
DROP TABLE IF EXISTS `image_urls`;
CREATE TABLE `image_urls` (
  `image_urls_id` int(11) unsigned NOT NULL DEFAULT 0,
  `url` varchar(128) NOT NULL COMMENT 'Address to iiif compliant server.',
  `suffix` varchar(128) NOT NULL DEFAULT 'default.jpg' COMMENT 'Use this only if you need to set a specific suffix due to the server not properly supporting the standard “default.jpg”.',
  PRIMARY KEY (`image_urls_id`,`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='URL’s for the iiif image servers providing our images.';

-- ----------------------------
-- Table structure for kerning_of_char
-- ----------------------------
DROP TABLE IF EXISTS `kerning_of_char`;
CREATE TABLE `kerning_of_char` (
  `kerning` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Kerning in mm',
  `previous_char` char(1) NOT NULL,
  `chars_of_writing_char_of_writing_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`chars_of_writing_char_of_writing_id`,`previous_char`),
  CONSTRAINT `fk_to_chars_of_writing` FOREIGN KEY (`chars_of_writing_char_of_writing_id`) REFERENCES `char_of_writing` (`char_of_writing_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Describes character to character kerning relationships.';

-- ----------------------------
-- Table structure for line
-- ----------------------------
DROP TABLE IF EXISTS `line`;
CREATE TABLE `line` (
  `line_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`line_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for line_data
-- ----------------------------
DROP TABLE IF EXISTS `line_data`;
CREATE TABLE `line_data` (
  `line_data_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) DEFAULT 'NULL' COMMENT 'Name of line (should be unique in comparison to other lines in column).',
  `line_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`line_data_id`,`line_id`),
  KEY `fk_line_data_to_line_idx` (`line_id`),
  CONSTRAINT `fk_line_data_to_line` FOREIGN KEY (`line_id`) REFERENCES `line` (`line_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=54448 DEFAULT CHARSET=utf8 COMMENT='Data pertaining to the description of a line of transcribed text.';

-- ----------------------------
-- Table structure for line_data_owner
-- ----------------------------
DROP TABLE IF EXISTS `line_data_owner`;
CREATE TABLE `line_data_owner` (
  `line_data_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`line_data_id`,`scroll_version_id`),
  KEY `fk_line_data_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_line_data_owner_to_line_data` FOREIGN KEY (`line_data_id`) REFERENCES `line_data` (`line_data_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_line_data_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for line_to_sign
-- ----------------------------
DROP TABLE IF EXISTS `line_to_sign`;
CREATE TABLE `line_to_sign` (
  `line_to_sign_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sign_id` int(10) unsigned NOT NULL,
  `line_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`line_to_sign_id`),
  UNIQUE KEY `line_sign_idx` (`sign_id`,`line_id`) USING BTREE,
  KEY `fk_line_to_sign_to_line_idx` (`line_id`),
  CONSTRAINT `fk_line_to_sign_to_line` FOREIGN KEY (`line_id`) REFERENCES `line` (`line_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_line_to_sign_to_sign` FOREIGN KEY (`sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1733952 DEFAULT CHARSET=utf8 COMMENT='Linking of signs to a line.';

-- ----------------------------
-- Table structure for line_to_sign_owner
-- ----------------------------
DROP TABLE IF EXISTS `line_to_sign_owner`;
CREATE TABLE `line_to_sign_owner` (
  `line_to_sign_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`line_to_sign_id`,`scroll_version_id`),
  KEY `fl_to_sign_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_line_to_sign_owner_to_line_to_sign` FOREIGN KEY (`line_to_sign_id`) REFERENCES `line_to_sign` (`line_to_sign_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fl_to_sign_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for main_action
-- ----------------------------
DROP TABLE IF EXISTS `main_action`;
CREATE TABLE `main_action` (
  `main_action_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `time` datetime(6) DEFAULT current_timestamp(6) COMMENT 'The time that the execution was performed.',
  `rewinded` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean relaying whether the particular action has been rewound or not.',
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`main_action_id`),
  KEY `main_action_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `main_action_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2257 DEFAULT CHARSET=utf8 COMMENT='Table for an undo system.  This table stores the state of the action (rewound or not), the date of the change, and the version of the scroll that the action is associated with.  The table single_action links to the entries here and describe the table in which the action occurred, the id of the entry in that table that was involved, and the nature of the action (creating a connection between that entry and the scroll version of the main_action, or deleting the connection between that entry and the scroll version of the main_action).';

-- ----------------------------
-- Table structure for position_in_stream
-- ----------------------------
DROP TABLE IF EXISTS `position_in_stream`;
CREATE TABLE `position_in_stream` (
  `position_in_stream_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Uinique identifiere',
  `sign_id` int(11) unsigned NOT NULL COMMENT 'References a sign',
  `next_sign_id` int(10) unsigned DEFAULT NULL COMMENT 'Links to another sign in order to create a linked list.',
  `version` smallint(5) unsigned NOT NULL DEFAULT 0,
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`position_in_stream_id`),
  KEY `position_in_stream_next_sign_id_IDX` (`sign_id`),
  KEY `fk_position_to_next_sign` (`next_sign_id`),
  CONSTRAINT `fk_to_next_sign` FOREIGN KEY (`next_sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_to_sign` FOREIGN KEY (`sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1730492 DEFAULT CHARSET=utf8 COMMENT='Put signs in one-dimensional stream (≈ text)\nThe reason for this table is, that the manuscripts may contain parallel text-streams created by corrections. Sometimes also scholars put superlinear signs at different places. Thus, this is a discrete layer of interpretation between signs and words.';

-- ----------------------------
-- Table structure for position_in_stream_owner
-- ----------------------------
DROP TABLE IF EXISTS `position_in_stream_owner`;
CREATE TABLE `position_in_stream_owner` (
  `position_in_stream_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`position_in_stream_id`,`scroll_version_id`),
  KEY `fk_position_in_stream_onwer_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_position_in_stream_onwer_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_position_in_stream_owner_to_position_in_stream` FOREIGN KEY (`position_in_stream_id`) REFERENCES `position_in_stream` (`position_in_stream_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for position_in_stream_to_word_rel
-- ----------------------------
DROP TABLE IF EXISTS `position_in_stream_to_word_rel`;
CREATE TABLE `position_in_stream_to_word_rel` (
  `position_in_stream_id` int(10) unsigned NOT NULL COMMENT 'References a sign in a stream',
  `word_id` int(10) unsigned NOT NULL DEFAULT 0,
  `position_in_word` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`position_in_stream_id`,`word_id`),
  KEY `fk_sign_stream_has_words_sign_stream1_idx` (`position_in_stream_id`),
  KEY `fk_rel_to_word_idx` (`word_id`),
  CONSTRAINT `fk_rel_position_in_stream` FOREIGN KEY (`position_in_stream_id`) REFERENCES `position_in_stream` (`position_in_stream_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_rel_to_word` FOREIGN KEY (`word_id`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Links individual signs to words, which are then linked to data in the QWB database.';

-- ----------------------------
-- Table structure for real_char_area
-- ----------------------------
DROP TABLE IF EXISTS `real_char_area`;
CREATE TABLE `real_char_area` (
  `real_char_area_id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier',
  `sign_id` int(10) unsigned DEFAULT NULL,
  `char_of_writing_id` int(10) unsigned DEFAULT NULL,
  `path` multipolygon DEFAULT NULL COMMENT 'Outline of the character.  Coordinate system is that of the bounding box.',
  `x` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'x location in scroll.',
  `y` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'y location in scroll.',
  `width` smallint(5) unsigned NOT NULL DEFAULT 50 COMMENT 'Width of bounding box.',
  `height` smallint(5) unsigned NOT NULL DEFAULT 50 COMMENT 'Height of bounding box.',
  `line_offset` smallint(5) unsigned NOT NULL DEFAULT 0,
  `values_set` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'If true, then the area_in_scroll and rotation are set by the user and must not be affected by the automatic placing of the system',
  `exceptional` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`real_char_area_id`),
  KEY `fk_real_area_to_sign_idx` (`sign_id`),
  KEY `fk_real_area_to_char_of_writing_idx` (`char_of_writing_id`),
  CONSTRAINT `fk_real_area_to_char_of_writing` FOREIGN KEY (`char_of_writing_id`) REFERENCES `char_of_writing` (`char_of_writing_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_real_area_to_sign` FOREIGN KEY (`sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Defines a ROI on in the reconstructed scroll object.';

-- ----------------------------
-- Table structure for real_char_area_owner
-- ----------------------------
DROP TABLE IF EXISTS `real_char_area_owner`;
CREATE TABLE `real_char_area_owner` (
  `real_char_area_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`real_char_area_id`,`scroll_version_id`),
  KEY `fk_rad_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_rad_owner_to_real_area_data` FOREIGN KEY (`real_char_area_id`) REFERENCES `real_char_area` (`real_char_area_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_rad_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scribal_font_type
-- ----------------------------
DROP TABLE IF EXISTS `scribal_font_type`;
CREATE TABLE `scribal_font_type` (
  `scribal_font_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Provides metadata for „Fonts“ used by scribes .\n\nToDo: Define the ontology (fromal …) which should be used',
  `font_name` varchar(45) NOT NULL DEFAULT '???',
  PRIMARY KEY (`scribal_font_type_id`),
  UNIQUE KEY `style_name_idx` (`font_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scribal_font_type_owner
-- ----------------------------
DROP TABLE IF EXISTS `scribal_font_type_owner`;
CREATE TABLE `scribal_font_type_owner` (
  `scribal_font_type_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scribal_font_type_id`,`scroll_version_id`),
  KEY `fk_font_owner_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_font_owner_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_font_owner_to_font` FOREIGN KEY (`scribal_font_type_id`) REFERENCES `scribal_font_type` (`scribal_font_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scribe
-- ----------------------------
DROP TABLE IF EXISTS `scribe`;
CREATE TABLE `scribe` (
  `scribe_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(45) DEFAULT NULL,
  `commetary` text DEFAULT NULL,
  PRIMARY KEY (`scribe_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scribe_owner
-- ----------------------------
DROP TABLE IF EXISTS `scribe_owner`;
CREATE TABLE `scribe_owner` (
  `scribe_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scribe_id`,`scroll_version_id`),
  KEY `fk_scribe_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_scribe_owner_to_scribe` FOREIGN KEY (`scribe_id`) REFERENCES `scribe` (`scribe_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_scribe_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scroll
-- ----------------------------
DROP TABLE IF EXISTS `scroll`;
CREATE TABLE `scroll` (
  `scroll_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`scroll_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1107 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scroll_data
-- ----------------------------
DROP TABLE IF EXISTS `scroll_data`;
CREATE TABLE `scroll_data` (
  `scroll_data_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) DEFAULT 'NULL' COMMENT 'Name for scroll entity.',
  `scroll_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scroll_data_id`),
  KEY `fk_scroll_to_master_scroll_idx` (`scroll_id`),
  CONSTRAINT `fk_scroll_to_master_scroll` FOREIGN KEY (`scroll_id`) REFERENCES `scroll` (`scroll_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1122 DEFAULT CHARSET=utf8 COMMENT='Description of a reconstructed scroll or combination.';

-- ----------------------------
-- Table structure for scroll_data_owner
-- ----------------------------
DROP TABLE IF EXISTS `scroll_data_owner`;
CREATE TABLE `scroll_data_owner` (
  `scroll_data_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scroll_data_id`,`scroll_version_id`),
  KEY `fk_scroll_owner_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_scroll_owner_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_scroll_owner_to_scroll_data` FOREIGN KEY (`scroll_data_id`) REFERENCES `scroll_data` (`scroll_data_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scroll_to_col
-- ----------------------------
DROP TABLE IF EXISTS `scroll_to_col`;
CREATE TABLE `scroll_to_col` (
  `scroll_to_col_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scroll_id` int(10) unsigned NOT NULL,
  `col_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scroll_to_col_id`),
  UNIQUE KEY `scroll_col_idx` (`scroll_id`,`col_id`),
  KEY `fk_scroll_to_column_to_column_idx` (`col_id`),
  CONSTRAINT `fk_scroll_to_column_to_column` FOREIGN KEY (`col_id`) REFERENCES `col` (`col_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_scroll_to_column_to_scroll` FOREIGN KEY (`scroll_id`) REFERENCES `scroll` (`scroll_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11177 DEFAULT CHARSET=utf8 COMMENT='Links an entry in the col table to a reconstructed scroll.';

-- ----------------------------
-- Table structure for scroll_to_col_owner
-- ----------------------------
DROP TABLE IF EXISTS `scroll_to_col_owner`;
CREATE TABLE `scroll_to_col_owner` (
  `scroll_to_col_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`scroll_to_col_id`,`scroll_version_id`),
  KEY `fk_stco_toscroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_stco_to_scroll_to_column` FOREIGN KEY (`scroll_to_col_id`) REFERENCES `scroll_to_col` (`scroll_to_col_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_stco_toscroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for scroll_version
-- ----------------------------
DROP TABLE IF EXISTS `scroll_version`;
CREATE TABLE `scroll_version` (
  `scroll_version_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` smallint(5) unsigned NOT NULL,
  `scroll_id` int(10) unsigned NOT NULL,
  `version` smallint(5) unsigned NOT NULL DEFAULT 0 COMMENT 'This is the version that will be found in all the x_to_owner tables .for this particular version of a scroll.',
  `commentary` longtext DEFAULT NULL,
  `locked` tinyint(3) unsigned DEFAULT 0,
  PRIMARY KEY (`scroll_version_id`),
  UNIQUE KEY `user_scroll_version_idx` (`user_id`,`scroll_id`,`version`),
  KEY `fk_scroll_version_to_scroll_idx` (`scroll_id`),
  CONSTRAINT `fk_scroll_version_to_scroll` FOREIGN KEY (`scroll_id`) REFERENCES `scroll` (`scroll_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_scroll_version_to_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1221 DEFAULT CHARSET=utf8 COMMENT='This table defines unique versions of a reconstructed scroll.';

-- ----------------------------
-- Table structure for sign
-- ----------------------------
DROP TABLE IF EXISTS `sign`;
CREATE TABLE `sign` (
  `sign_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`sign_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1733986 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sign_char
-- ----------------------------
DROP TABLE IF EXISTS `sign_char`;
CREATE TABLE `sign_char` (
  `sign_char_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sign_id` int(10) unsigned NOT NULL,
  `is_variant` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean set to true when current entry is a variant interpretation of a sign.',
  `sign_type_id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `break_type` set('LINE_START','LINE_END','COLUMN_START','COLUMN_END','SCROLL_START','SCROLL_END') DEFAULT NULL,
  `sign` char(8) NOT NULL DEFAULT '''''' COMMENT 'Unicode representation of a sign.',
  `width` decimal(6,3) unsigned NOT NULL DEFAULT 1.000 COMMENT 'Width setting (usually used for spaces).',
  `might_be_wider` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean determining if the width value is uncertain.',
  `vocalization` tinyint(4) DEFAULT NULL COMMENT 'Setting for vocalization system (e.g., Tiberian, Babylonian, Palestian vocalization systems).  Not yet implemented.',
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`sign_char_id`),
  KEY `fk_sign_char_to_sign_idx` (`sign_id`),
  KEY `fk_sign_char_to_sign_typ_idx` (`sign_type_id`),
  CONSTRAINT `fk_sign_char_to_sign` FOREIGN KEY (`sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_sign_char_to_sign_typ` FOREIGN KEY (`sign_type_id`) REFERENCES `sign_type` (`sign_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1734229 DEFAULT CHARSET=utf8 COMMENT='This table describes signs on a manuscript.  Currently this includes both characters and spaces, it could perhaps also include other elements that one might want to define as a sign.';

-- ----------------------------
-- Table structure for sign_char_owner
-- ----------------------------
DROP TABLE IF EXISTS `sign_char_owner`;
CREATE TABLE `sign_char_owner` (
  `sign_char_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sign_char_id`,`scroll_version_id`),
  KEY `fk_sign_char_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_sign_char_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_sign_char_owner_to_sign_char` FOREIGN KEY (`sign_char_id`) REFERENCES `sign_char` (`sign_char_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sign_char_reading_data
-- ----------------------------
DROP TABLE IF EXISTS `sign_char_reading_data`;
CREATE TABLE `sign_char_reading_data` (
  `sign_char_reading_data_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sign_char_id` int(11) unsigned NOT NULL COMMENT 'Unique identifier',
  `readability` enum('COMPLETE','INCOMPLETE_BUT_CLEAR','INCOMPLETE_AND_NOT_CLEAR') DEFAULT 'COMPLETE',
  `readable_areas` set('NW','NE','MW','ME','SW','SE') DEFAULT NULL COMMENT '2x4-field set to locate readable areas\ncan be used to set brackets in a more sophisticated way\n\nNW    NE\nMNW MNE\nMSW MSE\nSW    SE',
  `is_reconstructed` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Boolean determining if the current character is reconstructed or not.',
  `is_retraced` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Boolean for determining if character has been retraced.',
  `editorial_flag` enum('NO','CONJECTURE','SHOULD_BE_ADDED','SHOULD_BE_DELETED') DEFAULT 'NO' COMMENT 'This relays the intents of the editor regarding the current character.',
  `correction` set('OVERWRITTEN','HORIZONTAL_LINE','DIAGONAL_LEFT_LINE','DIAGONAL_RIGHT_LINE','DOT_BELOW','DOT_ABOVE','LINE_BELOW','LINE_ABOVE','BOXED','ERASED') DEFAULT NULL COMMENT 'Type of scribal correction mark.',
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`sign_char_reading_data_id`),
  KEY `fk_sign_char_rd_to_sign_char_idx` (`sign_char_id`),
  CONSTRAINT `fk_sign_char_rd_to_sign_char` FOREIGN KEY (`sign_char_id`) REFERENCES `sign_char` (`sign_char_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=747378 DEFAULT CHARSET=utf8 COMMENT='Contains data related to the readability of a sign.';

-- ----------------------------
-- Table structure for sign_char_reading_data_owner
-- ----------------------------
DROP TABLE IF EXISTS `sign_char_reading_data_owner`;
CREATE TABLE `sign_char_reading_data_owner` (
  `sign_char_reading_data_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sign_char_reading_data_id`,`scroll_version_id`),
  KEY `fk_sign_char_rd_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_sign_char_rd_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_sign_char_rd_owner_to_sign_char_rd` FOREIGN KEY (`sign_char_reading_data_id`) REFERENCES `sign_char_reading_data` (`sign_char_reading_data_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sign_relative_position
-- ----------------------------
DROP TABLE IF EXISTS `sign_relative_position`;
CREATE TABLE `sign_relative_position` (
  `sign_relative_position_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sign_id` int(10) unsigned NOT NULL,
  `type` enum('ABOVE_LINE','BELOW_LINE','LEFT_MARGIN','RIGHT_MARGIN','MARGIN','UPPER_MARGIN','LOWER_MARGIN') DEFAULT NULL COMMENT 'Position of character relative to the text block.',
  `level` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'This is used when a character has multiple levels of relation to the text it relates to.  For instance a note to the main text may be in the margin, which would be a level 1 change in position.  That marginal text may also have a superlinear note , which would be marked both type “LEFT_MARGIN” level “1” and type “ABOVE_LINE” level “2”. to it',
  PRIMARY KEY (`sign_relative_position_id`),
  KEY `fk_sign_rel_pos_to:sign_idx` (`sign_id`),
  CONSTRAINT `fk_sign_rel_pos_to:sign` FOREIGN KEY (`sign_id`) REFERENCES `sign` (`sign_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=6023 DEFAULT CHARSET=utf8 COMMENT='This table describes the position of a character in relation to the text it is related to. ';

-- ----------------------------
-- Table structure for sign_relative_position_owner
-- ----------------------------
DROP TABLE IF EXISTS `sign_relative_position_owner`;
CREATE TABLE `sign_relative_position_owner` (
  `sign_relative_position_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sign_relative_position_id`,`scroll_version_id`),
  KEY `fk_sign_rel_pos_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_sign_rel_pos_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_sign_rel_pos_owner_to_sign_rel_pos` FOREIGN KEY (`sign_relative_position_id`) REFERENCES `sign_relative_position` (`sign_relative_position_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sign_type
-- ----------------------------
DROP TABLE IF EXISTS `sign_type`;
CREATE TABLE `sign_type` (
  `sign_type_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(45) NOT NULL DEFAULT '???',
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`sign_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for single_action
-- ----------------------------
DROP TABLE IF EXISTS `single_action`;
CREATE TABLE `single_action` (
  `single_action_id` bigint(19) unsigned NOT NULL AUTO_INCREMENT,
  `main_action_id` int(10) unsigned NOT NULL,
  `action` enum('add','delete') NOT NULL COMMENT 'This sets the type of action.  There are only two, adding a connection to data or deleting a connection to data (this is done in the x_to_owner table).  The actual data is not deleted (at some point we may need to implement some form of garbage collection).',
  `table` varchar(45) NOT NULL DEFAULT '' COMMENT 'Name of the table where the change in data occured.',
  `id_in_table` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'id of the record linked or unlinked to the scroll version (of the linked main_action) in the “table”_to_owner table.',
  PRIMARY KEY (`single_action_id`),
  KEY `fk_single_action_to_main_idx` (`main_action_id`),
  CONSTRAINT `fk_single_action_to_main` FOREIGN KEY (`main_action_id`) REFERENCES `main_action` (`main_action_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3415 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sqe_session
-- ----------------------------
DROP TABLE IF EXISTS `sqe_session`;
CREATE TABLE `sqe_session` (
  `sqe_session_id` char(36) NOT NULL,
  `user_id` smallint(5) unsigned NOT NULL,
  `scroll_version_id` int(11) NOT NULL,
  `session_start` timestamp(6) NOT NULL DEFAULT current_timestamp(6),
  `last_internal_session_end` timestamp(6) NULL DEFAULT NULL,
  PRIMARY KEY (`sqe_session_id`),
  KEY `fk_sqe_sesseio_to_user_idx` (`user_id`),
  CONSTRAINT `fk_sqe_sesseio_to_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `user_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `user_name` varchar(30) DEFAULT 'NULL' COMMENT 'System username.',
  `pw` char(64) DEFAULT 'NULL' COMMENT 'Password for system access.',
  `forename` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `organization` varchar(50) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL COMMENT 'max size according to RF 5321',
  `registration_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user` (`user_name`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8 COMMENT='This table stores the data of all registered users,\nCreated by Martin 17/03/03';

-- ----------------------------
-- Table structure for user_attribute
-- ----------------------------
DROP TABLE IF EXISTS `user_attribute`;
CREATE TABLE `user_attribute` (
  `user_attribute_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sign_id` int(11) unsigned NOT NULL,
  `user_attribute_type_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`user_attribute_id`),
  KEY `fk_sign_correction_correction_type1_idx` (`user_attribute_type_id`),
  CONSTRAINT `fk_user_defined_attribute` FOREIGN KEY (`user_attribute_type_id`) REFERENCES `user_defined_attribute` (`user_defined_attribute_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Created by Martin 17/04/18';

-- ----------------------------
-- Table structure for user_comment
-- ----------------------------
DROP TABLE IF EXISTS `user_comment`;
CREATE TABLE `user_comment` (
  `comment_id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` smallint(5) unsigned NOT NULL,
  `comment_text` varchar(5000) DEFAULT NULL,
  `entry_time` datetime DEFAULT NULL,
  PRIMARY KEY (`comment_id`,`user_id`),
  KEY `fk_user_comment_to_user_idx` (`user_id`),
  CONSTRAINT `fk_user_comment_to_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='Created by Martin 17/03/03';

-- ----------------------------
-- Table structure for user_contributions
-- ----------------------------
DROP TABLE IF EXISTS `user_contributions`;
CREATE TABLE `user_contributions` (
  `contribution_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` smallint(5) DEFAULT NULL,
  `contribution` mediumtext DEFAULT NULL,
  `entry_time` datetime DEFAULT NULL,
  PRIMARY KEY (`contribution_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Created by Martin 17/03/29';

-- ----------------------------
-- Table structure for user_defined_attribute
-- ----------------------------
DROP TABLE IF EXISTS `user_defined_attribute`;
CREATE TABLE `user_defined_attribute` (
  `user_defined_attribute_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `attribute` varchar(45) NOT NULL,
  `commentary` text DEFAULT NULL,
  `tag` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`user_defined_attribute_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for user_sessions
-- ----------------------------
DROP TABLE IF EXISTS `user_sessions`;
CREATE TABLE `user_sessions` (
  `session_id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` smallint(5) unsigned NOT NULL,
  `session_key` char(56) DEFAULT NULL,
  `session_start` datetime DEFAULT NULL,
  `session_end` datetime DEFAULT NULL,
  `current` tinyint(1) DEFAULT NULL COMMENT 'Boolean determining whether the current session is still in progress or has been finished (user has exited).',
  PRIMARY KEY (`session_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8 COMMENT='This table stores a record of all user sessions.\nCreated by Martin 17/03/03';

-- ----------------------------
-- Table structure for word
-- ----------------------------
DROP TABLE IF EXISTS `word`;
CREATE TABLE `word` (
  `word_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier',
  `qwb_word_id` int(11) unsigned DEFAULT NULL COMMENT 'Old word identifier from QWB.',
  `commentary` text DEFAULT NULL,
  PRIMARY KEY (`word_id`),
  KEY `old_word_idx` (`qwb_word_id`)
) ENGINE=InnoDB AUTO_INCREMENT=380474 DEFAULT CHARSET=utf8 COMMENT='A collection of signs from a stream. Maintains link to original QWB word id.';

-- ----------------------------
-- Table structure for word_owner
-- ----------------------------
DROP TABLE IF EXISTS `word_owner`;
CREATE TABLE `word_owner` (
  `word_id` int(10) unsigned NOT NULL,
  `scroll_version_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`word_id`,`scroll_version_id`),
  KEY `fk_word_owner_to_scroll_version_idx` (`scroll_version_id`),
  CONSTRAINT `fk_word_owner_to_scroll_version` FOREIGN KEY (`scroll_version_id`) REFERENCES `scroll_version` (`scroll_version_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_word_owner_to_word` FOREIGN KEY (`word_id`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for cursor_proc
-- ----------------------------
DROP PROCEDURE IF EXISTS `cursor_proc`;
delimiter ;;
CREATE DEFINER=`SQE`@`localhost` PROCEDURE `cursor_proc`()
BEGIN
   DECLARE art_id INT UNSIGNED DEFAULT 0;
   -- this flag will be set to true when cursor reaches end of table
   DECLARE exit_loop BOOLEAN;         
   -- Declare the cursor
   DECLARE artefact_cursor CURSOR FOR
     SELECT artefact_id FROM artefact;
   -- set exit_loop flag to true if there are no more rows
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET exit_loop = TRUE;
   -- open the cursor
   OPEN artefact_cursor;
   -- start looping
   artefact_loop: LOOP
     -- read the name from next row into the variables 
     FETCH  artefact_cursor INTO art_id;
     -- check if the exit_loop flag has been set by mysql, 
     -- close the cursor and exit the loop if it has.
     IF exit_loop THEN
         CLOSE artefact_cursor;
         LEAVE artefact_loop;
     END IF;
     INSERT IGNORE INTO artefact_owner (artefact_id, scroll_version_id) VALUES(art_id, 1);
   END LOOP artefact_loop;
 END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getCatalogAndEdition
-- ----------------------------
DROP PROCEDURE IF EXISTS `getCatalogAndEdition`;
delimiter ;;
CREATE DEFINER=`SQE`@`localhost` PROCEDURE `getCatalogAndEdition`(param_plate VARCHAR(45), param_fragment VARCHAR(45), param_side TINYINT(1))
    DETERMINISTIC
    SQL SECURITY INVOKER
select image_catalog.image_catalog_id, edition_catalog.edition_catalog_id 
from image_catalog 
left join image_to_edition_catalog USING(image_catalog_id) 
left join edition_catalog USING(edition_catalog_id)
where image_catalog.catalog_number_1 = param_plate AND image_catalog.catalog_number_2 = param_fragment 
AND image_catalog.catalog_side = param_side;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getMasterImageListings
-- ----------------------------
DROP PROCEDURE IF EXISTS `getMasterImageListings`;
delimiter ;;
CREATE DEFINER=`SQE`@`localhost` PROCEDURE `getMasterImageListings`()
    DETERMINISTIC
    SQL SECURITY INVOKER
select edition_catalog.composition, image_catalog.institution, image_catalog.catalog_number_1, image_catalog.catalog_number_2,  edition_catalog.edition_name, edition_catalog.edition_volume, edition_catalog.edition_location_1, edition_catalog.edition_location_2, SQE_image.sqe_image_id
from SQE_image 
left join image_catalog USING(image_catalog_id)
left join edition_catalog USING(edition_catalog_id)
where SQE_image.is_master=1 AND image_catalog.catalog_side=0 order by edition_catalog.composition;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getScrollArtefacts
-- ----------------------------
DROP PROCEDURE IF EXISTS `getScrollArtefacts`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getScrollArtefacts`(scroll_id VARCHAR(128), side TINYINT)
    DETERMINISTIC
    SQL SECURITY INVOKER
SELECT distinct artefact.artefact_id as id, ST_AsText(ST_Envelope(artefact.region_in_master_image)) as rect, ST_AsText(artefact.region_in_master_image) as poly, ST_AsText(artefact.position_in_scroll) as pos, image_urls.url as url, image_urls.suffix as suffix, SQE_image.filename as filename, SQE_image.dpi as dpi from artefact inner join SQE_image USING(sqe_image_id) inner join image_urls USING(image_urls_id) inner join image_to_edition_catalog USING(image_catalog_id) inner join edition_catalog_to_discrete_reference USING(edition_catalog_id) inner join discrete_canonical_references USING(discrete_canonical_reference_id) inner join scroll USING(scroll_id) inner join edition_catalog USING(edition_catalog_id) where scroll.scroll_id=scroll_id and edition_catalog.edition_side=side;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getScrollHeight
-- ----------------------------
DROP PROCEDURE IF EXISTS `getScrollHeight`;
delimiter ;;
CREATE DEFINER=`bronson`@`localhost` PROCEDURE `getScrollHeight`(scroll_id_num int unsigned, version_id int unsigned)
    DETERMINISTIC
    SQL SECURITY INVOKER
select artefact_id, ST_Y(position_in_scroll) + ((ST_Y(ST_PointN(ST_ExteriorRing(ST_ENVELOPE(region_in_master_image)), 3)) - ST_Y(ST_PointN(ST_ExteriorRing(ST_ENVELOPE(region_in_master_image)), 1))) * (1215 / SQE_image.dpi)) as max_y from artefact_position join artefact_position_owner using(artefact_position_id) join artefact using(artefact_id) join scroll_version using(scroll_version_id) join SQE_image USING(sqe_image_id) join image_catalog using(image_catalog_id) where artefact_position.scroll_id=scroll_id_num and artefact_position_owner.scroll_version_id = version_id and image_catalog.catalog_side=0 order by max_y DESC limit 1;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getScrollVersionArtefacts
-- ----------------------------
DROP PROCEDURE IF EXISTS `getScrollVersionArtefacts`;
delimiter ;;
CREATE DEFINER=`bronson`@`localhost` PROCEDURE `getScrollVersionArtefacts`(scroll_id_num int unsigned, version_id int unsigned)
    DETERMINISTIC
    SQL SECURITY INVOKER
SELECT distinct artefact.artefact_id as id, ST_AsText(ST_Envelope(artefact.region_in_master_image)) as rect, ST_AsText(artefact.region_in_master_image) as poly, ST_AsText(artefact.position_in_scroll) as pos, image_urls.url as url, image_urls.suffix as suffix, SQE_image.filename as filename, SQE_image.dpi as dpi, artefact.rotation as rotation from artefact_owner join artefact using(artefact_id) join scroll_version using(scroll_version_id) inner join SQE_image USING(sqe_image_id) inner join image_urls USING(image_urls_id) inner join image_catalog using(image_catalog_id) where artefact.scroll_id=scroll_id_num and artefact_owner.scroll_version_id = version_id and image_catalog.catalog_side=0;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for getScrollWidth
-- ----------------------------
DROP PROCEDURE IF EXISTS `getScrollWidth`;
delimiter ;;
CREATE DEFINER=`bronson`@`localhost` PROCEDURE `getScrollWidth`(scroll_id_num int unsigned, version_id int unsigned)
    DETERMINISTIC
    SQL SECURITY INVOKER
select artefact_id, ST_X(position_in_scroll) + ((ST_X(ST_PointN(ST_ExteriorRing(ST_ENVELOPE(region_in_master_image)), 2)) - ST_X(ST_PointN(ST_ExteriorRing(ST_ENVELOPE(region_in_master_image)), 1))) * (1215 / SQE_image.dpi)) as max_x from artefact_position join artefact_position_owner using(artefact_position_id) join artefact using(artefact_id) join scroll_version using(scroll_version_id) join SQE_image USING(sqe_image_id) join image_catalog using(image_catalog_id) where artefact_position.scroll_id=scroll_id_num and artefact_position_owner.scroll_version_id = version_id and image_catalog.catalog_side=0 order by max_x DESC limit 1;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_fragment
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_fragment`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_fragment`(
								IN scroll_id INTEGER,
								INOUT column_name VARCHAR(45),
								OUT column_count INTEGER,
								OUT column_id INTEGER,
								INOUT full_output LONGTEXT
							)
    DETERMINISTIC
BEGIN
	
	SET column_name = CONCAT('^', column_name, '( [iv]+)?$');
	SELECT  
		column_of_scroll.column_of_scroll_id, 
		column_of_scroll.name,
		count(column_of_scroll.column_of_scroll_id)
	INTO column_id, column_name, column_count
	FROM column_of_scroll
	WHERE column_of_scroll.scroll_id=scroll_id
	AND column_of_scroll.name REGEXP column_name;
	
	IF column_count = 0 THEN
		SET full_output = '{"ERROR_CODE":5, "ERROR_TEXT":"Fragment not found"}';
	END IF;

END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_fragment_text
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_fragment_text`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_fragment_text`(
						IN scroll_name VARCHAR(45),
						IN column_name VARCHAR(45)
					)
get_fragment_text:BEGIN
	DECLARE next_id_var		INTEGER;
	DECLARE break_type_var	INTEGER;
	DECLARE full_output		LONGTEXT;
	DECLARE line_output		TEXT;
	DECLARE scroll_id		INTEGER;
	DECLARE column_count	INTEGER;
	DECLARE column_id	INTEGER;
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE old_column INTEGER DEFAULT 0;
	DECLARE new_column INTEGER DEFAULT 0;

	DECLARE my_cursor CURSOR FOR 
		SELECT 
			CONCAT( '{"LINE":"', line_of_column_of_scroll.name, 
				'","LINE_ID":', line_of_column_of_scroll.line_id, 
				',"SIGNS":['),
			position_in_stream.next_sign_id, column_of_scroll_id, column_of_scroll.name
		FROM column_of_scroll
		JOIN line_of_column_of_scroll ON line_of_column_of_scroll.column_id=column_of_scroll.column_of_scroll_id
		JOIN real_area ON real_area.line_of_scroll_id = line_of_column_of_scroll.line_id
		JOIN sign ON sign.real_areas_id=real_area.real_area_id
		JOIN position_in_stream ON position_in_stream.sign_id=sign.sign_id
		WHERE column_of_scroll.column_of_scroll_id in (
				SELECT  column_of_scroll.column_of_scroll_id
				FROM column_of_scroll
				WHERE column_of_scroll.scroll_id=scroll_id
				AND column_of_scroll.name REGEXP column_name
			)
		AND (sign.sign_id is null OR FIND_IN_SET('LINE_START', sign.break_type))
		ORDER BY ST_X(ST_CENTROID(real_area.area_in_scroll)), ST_Y(ST_CENTROID(real_area.area_in_scroll)) ;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
		
	CALL get_scroll(scroll_name, scroll_id, full_output);
	
	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_fragment_text;		
	END IF;
	
	CALL get_fragment(scroll_id, column_name,column_count, column_id, full_output);

	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_fragment_text;		
	END IF;
	
	SET full_output = CONCAT('{"SCROLL":"' , scroll_name, 
					'","SCROLL_ID":', scroll_id,
					',"FRAGMENTS":[');	
					
	SET line_output = '';	
	OPEN my_cursor;
	
	get_lines: LOOP	
		FETCH my_cursor into  line_output, next_id_var, new_column, column_name;
		
		IF finished = 1 THEN
			LEAVE get_lines;
		END IF;
		
		IF new_column != old_column THEN
			SET full_output = concat(
				full_output,
				'{"FRAGMENT":"', column_name,
				'","FRAGMENT_ID":', new_column,
				',"LINES":['
				);
			SET old_column=new_column;
		END IF;

		SET full_output = concat(full_output,line_output);
		CALL get_sign_json(next_id_var, full_output);
		SET full_output = concat(full_output, ']},');
	END LOOP get_lines;

	SET full_output = CONCAT(SUBSTRING(full_output, 1, CHAR_LENGTH(full_output)-1),']}]}');
	SELECT full_output;
END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_line_text
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_line_text`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_line_text`(
						IN scroll_name VARCHAR(45),
						IN column_name VARCHAR(45),
						IN line_name   VARCHAR(45)
					)
get_line_text:BEGIN
	DECLARE next_id_var		INTEGER;
	DECLARE break_type_var	INTEGER;
	DECLARE full_output		TEXT;
	DECLARE scroll_id		INTEGER;
	DECLARE column_count		INTEGER;
	DECLARE column_id	INTEGER;
	
	CALL get_scroll(scroll_name, scroll_id, full_output);
	
	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_line_text;		
	END IF;
	
	call get_fragment(scroll_id, column_name,column_count, column_id, full_output);

	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_line_text;		
	END IF;
	
	IF  column_count>1 THEN
		SELECT '{"ERROR_CODE":6, "ERROR_TEXT":"No unique fragment"}';
		LEAVE get_line_text;		
	END IF;
		
	SELECT 	CONCAT(',"LINES":[{"LINE":\"', line_of_column_of_scroll.name, 
					'","LINE_ID":', line_of_column_of_scroll.line_id, 
					',"SIGNS":['),		
			position_in_stream.next_sign_id
		INTO full_output, next_id_var
		FROM line_of_column_of_scroll
		JOIN real_area ON real_area.line_of_scroll_id = line_of_column_of_scroll.line_id
		JOIN sign ON sign.real_areas_id=real_area.real_area_id
		JOIN position_in_stream ON position_in_stream.sign_id=sign.sign_id
		WHERE line_of_column_of_scroll.column_id = column_id
		AND line_of_column_of_scroll.name like line_name
		AND (sign.sign_id is null OR FIND_IN_SET('LINE_START', sign.break_type));
	
	SET full_output=CONCAT('{"SCROLL":"' , scroll_name, 
					'","SCROLL_ID":', scroll_id, 
					',"FRAGMENTS":[{',
					'"FRAGMENT":"', column_name,
					'","FRAGMENT_ID":', column_id, full_output);
	
	CALL get_sign_json(next_id_var, full_output);
		
	SELECT CONCAT(full_output, ']}]}]}');

END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_line_text_html
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_line_text_html`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_line_text_html`(
						IN scroll_name VARCHAR(45),
						IN column_name VARCHAR(45),
						IN line_name   VARCHAR(45)
					)
get_line_text:BEGIN
	DECLARE next_id_var		INTEGER;
	DECLARE break_type_var	INTEGER;
	DECLARE full_output		TEXT;
	DECLARE scroll_id		INTEGER;
	DECLARE column_count		INTEGER;
	DECLARE column_id	INTEGER;
	
	CALL get_scroll(scroll_name, scroll_id, full_output);
	
	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_line_text;		
	END IF;
	
	call get_fragment(scroll_id, column_name,column_count, column_id, full_output);

	IF full_output IS NOT NULL THEN
		SELECT full_output;
		LEAVE get_line_text;		
	END IF;
	
	IF  column_count>1 THEN
		SELECT '{"ERROR_CODE":6, "ERROR_TEXT":"No unique fragment"}';
		LEAVE get_line_text;		
	END IF;
		
	SELECT 	CONCAT('<span class="QWB_LINE" data-line-i="', line_of_column_of_scroll.line_id, 
					'">', line_of_column_of_scroll.name, '</span>\n'),		
			position_in_stream.next_sign_id
		INTO full_output, next_id_var
		FROM line_of_column_of_scroll
		JOIN real_area ON real_area.line_of_scroll_id = line_of_column_of_scroll.line_id
		JOIN sign ON sign.real_areas_id=real_area.real_area_id
		JOIN position_in_stream ON position_in_stream.sign_id=sign.sign_id
		WHERE line_of_column_of_scroll.column_id = column_id
		AND line_of_column_of_scroll.name like line_name
		AND (sign.sign_id is null OR FIND_IN_SET('LINE_START', sign.break_type));
	
	SET full_output=CONCAT('<div class="QWB_LINE">\n<span class="QWB_SCROLL" data-scroll-id="' , scroll_id, 
					'">', scroll_name, 
					'</span>\n<span class="QWB_FRAGMENT" data-fragment-id="', column_id,
					'">', column_name, '</span>\n', full_output);
	
	CALL get_sign_html(next_id_var, full_output);
		
	SELECT CONCAT(full_output, ']}]}]}');

END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_scroll
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_scroll`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_scroll`(
								INOUT scroll_name	VARCHAR(50),
								OUT scroll_id INTEGER,
								INOUT full_output LONGTEXT
								)
    DETERMINISTIC
BEGIN
	SELECT `scroll`.scroll_id
	INTO scroll_id
	FROM `scroll`
	WHERE `scroll`.name like scroll_name;
	
	IF scroll_id IS NULL THEN
		SET full_output = '{"ERROR_CODE":4, "ERROR_TEXT":"Scroll not found"}';
	END IF;
END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_sign_html
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_sign_html`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_sign_html`(
						IN 		next_id_var INTEGER	,
						INOUT full_output LONGTEXT
						)
BEGIN
	SET @output_text ='';
	SET @is_last = 0;
	SET @next_id_var=next_id_var;
	
	PREPARE stm FROM 
		"SELECT 
			IF(sign.sign_type_id=9, @output_text,
			CONCAT_WS('',@output_text,
					'<span class=QWB_SIGN',
					IF(FIND_IN_SET('OVERWRITTEN', sign.correction)>0, ' QWB_OVERWRITTEN', ''),
					IF(FIND_IN_SET('ERASED', sign.correction)>0, ' QWB_ERASED', ''),
					IF(sign.is_reconstructed=1, ' QWB_RECONSTRUCTED', ''),
					IF(sign.is_reconstructed=1, ' QWB_RECONSTRUCTED', ''),
					



sign.sign_id,', ',
					'\"SIGN\":\"',if(sign.sign like '',' ', sign.sign),'\", ', 
					'\"SIGN_TYPE\":\"', sign_type.type,'\", ',
					'\"SIGN_WIDTH\":', sign.width ,', ',
					'\"MIGHT_BE_WIDER\":', if(might_be_wider, 'true', 'false') ,', ',
					'\"READABILITY\":\"', sign.readability,'\", ',
					'\"IS_RECONSTRUCTED\":',if(is_reconstructed, 'true', 'false') ,', ',
					'\"IS_RETRACED\":',if(is_retraced, 'true', 'false') ,', ',
					'\"CORRECTION\":', set_to_json_array(sign.correction) ,', ',
					'\"RELATIVE_POSITION\":[', (select 
							CONCAT('\"',GROUP_CONCAT(sign_relative_position.`type` ORDER BY LEVEL ASC SEPARATOR '\",\"'),
								 '\"')
							FROM sign_relative_position
							WHERE sign_relative_position.sign_relative_position_id=sign.sign_id), 
					']},')), 
			position_in_stream.next_sign_id,
			IFNULL(FIND_IN_SET('LINE_END',sign.break_type),0)
			INTO  @output_text, @next_id_var, @is_last	
			FROM sign
			JOIN position_in_stream ON position_in_stream.sign_id=sign.sign_id
			JOIN sign_type ON sign_type.sign_type_id=sign.sign_type_id
			WHERE sign.sign_id=?";
			
	WHILE @is_last = 0   DO
		EXECUTE stm USING @next_id_var;
	END WHILE;
	DEALLOCATE PREPARE stm;
	SET full_output = concat(full_output, SUBSTRING(@output_text, 1, CHAR_LENGTH(@output_text)-1));
END;
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_sign_json
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_sign_json`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_sign_json`(
						IN 		next_id_var INTEGER	,
						INOUT full_output LONGTEXT
						)
BEGIN
	SET @output_text ='';
	SET @is_last = 0;
	SET @next_id_var=next_id_var;
	
	PREPARE stm FROM 
		"SELECT 
			IF(sign.sign_type_id=9, @output_text,
			CONCAT_WS('',@output_text,
					'{\"SIGN_ID\":',sign.sign_id,', ',
					'\"SIGN\":\"',if(sign.sign like '',' ', sign.sign),'\", ', 
					'\"SIGN_TYPE\":\"', sign_type.type,'\", ',
					'\"SIGN_WIDTH\":', sign.width ,', ',
					'\"MIGHT_BE_WIDER\":', if(might_be_wider, 'true', 'false') ,', ',
					'\"READABILITY\":\"', sign.readability,'\", ',
					'\"IS_RECONSTRUCTED\":',if(is_reconstructed, 'true', 'false') ,', ',
					'\"IS_RETRACED\":',if(is_retraced, 'true', 'false') ,', ',
					'\"CORRECTION\":', set_to_json_array(sign.correction) ,', ',
					'\"RELATIVE_POSITION\":[', (select 
							CONCAT('\"',GROUP_CONCAT(sign_relative_position.`type` ORDER BY LEVEL ASC SEPARATOR '\",\"'),
								 '\"')
							FROM sign_relative_position
							WHERE sign_relative_position.sign_relative_position_id=sign.sign_id), 
					']},')), 
			position_in_stream.next_sign_id,
			IFNULL(FIND_IN_SET('LINE_END',sign.break_type),0)
			INTO  @output_text, @next_id_var, @is_last	
			FROM sign
			JOIN position_in_stream ON position_in_stream.sign_id=sign.sign_id
			JOIN sign_type ON sign_type.sign_type_id=sign.sign_type_id
			WHERE sign.sign_id=?";
			
	WHILE @is_last = 0   DO
		EXECUTE stm USING @next_id_var;
	END WHILE;
	DEALLOCATE PREPARE stm;
	SET full_output = concat(full_output, SUBSTRING(@output_text, 1, CHAR_LENGTH(@output_text)-1));
END;
;;
delimiter ;

-- ----------------------------
-- Function structure for set_to_json_array
-- ----------------------------
DROP FUNCTION IF EXISTS `set_to_json_array`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `set_to_json_array`(my_set VARCHAR(250)) RETURNS varchar(250) CHARSET utf8
    DETERMINISTIC
BEGIN
	 IF my_set IS NOT NULL AND my_set NOT LIKE '' THEN
				RETURN CONCAT('["', REPLACE(my_set,',','","'), '"]');
				ELSE
				RETURN '[]';
	END IF;
END;
;;
delimiter ;

-- ----------------------------
-- Function structure for SPLIT_STRING
-- ----------------------------
DROP FUNCTION IF EXISTS `SPLIT_STRING`;
delimiter ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `SPLIT_STRING`(x VARCHAR(255), delim VARCHAR(12), pos INT) RETURNS varchar(255) CHARSET utf8
    DETERMINISTIC
    SQL SECURITY INVOKER
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '');
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
