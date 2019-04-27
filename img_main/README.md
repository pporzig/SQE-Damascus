# Image Downloader

This module downloads images from various sites. The benefits of having the images local are for research purposes only.

## Image Main (images_main.py)
Install a local python 3 virtual environment, using the `DSS_Editions/requirements.txt`.

Activate the source and run `images_main.py`. There are three required command line arguments.

1. resolution of image (e.g., 100)
2. IAA/PAM plate number (consult the Reed Catalogue)
3. Optional: a scroll siglum, e.g., 4Q394. If you use the optional siglum, you will need to install selenium driver `venv/bin` to run Chrome in a headless state.