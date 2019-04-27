# SQE-text-extract

Javascript code to extract running text from the Scripta Qumranica database.

## Prerequisites

You must have the SQE database running locally on your system.  The easiest way to get that is to clone the [SQE Scrollery-website project](https://github.com/Scripta-Qumranica-Electronica/Scrollery-website) and install it via the [Quick Start Instructions](https://github.com/Scripta-Qumranica-Electronica/Scrollery-website/blob/master/docs/SETUP.md#quick-start-instructions).

## Instructions

Clone the repository, then run `yarn`to install the dependencies.  Then simply run `yarn extract` and wait for the process to end.  The output is saved as a tab separated file to `SQE_texts.txt`.

## Notes

This program should only be run on a fresh instance of the SQE database and relies on the fact that the texts in that database were loaded sequentially.  The script is not using the linked list in the `position_in_stream` table for the ordering of signs since the default state of the database is in the proper order already.

This code was put together hastily and could certainly be sped up considerably with a bit more time and thought.  If you want to change how letters are treated, then you will want to edit lines 69–79 which evaluate how the text and its attributes are converted into a string for output into the text file.