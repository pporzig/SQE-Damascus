# -*- encoding: utf-8 -*-

import time
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from bs4 import BeautifulSoup
import os, re
import csv
import builtwith
import requests


def get_source(scroll):
    """
    Return source for Leon Levy Page
    """

    scroll = scroll + "-1"

    browser = webdriver.Chrome()
    browser.get(
        "https://www.deadseascrolls.org.il/explore-the-archive/manuscript/" + scroll
    )
    print("Opening Google Chrome at " + scroll + " to download ... ")
    time.sleep(5)

    # Assign page source var
    html = browser.page_source

    ##Get Soup of HTML to calculate page loads
    soup = BeautifulSoup(html, "lxml")

    # Get sh-result-header.h2 to divide results by total (as of 10-04-2019; changed on 02-05-2019)
    refresh_times = soup.find("div", class_="c-search-page__status")

    ## Adjust wait time dependent on internet speed
    count = refresh_times.text.strip()
    times = re.findall(r"\d+", count)
    

    ## Clean Numbers to Get times to refresh
    if int(times[1]) == 12:
        times[1] = 12
    elif int(times[1]) < 24:
        times[1] = 24
    
    refresh = (int(times[1]) / int(times[0]))
    x2load = str(refresh)
    print("Chrome will refresh " + x2load + " time(s).")
    # print(refresh)
    if refresh == 1:
        pass
    else:
        # load_more_link = browser.find_element_by_tag_name("c-search-page__load-more") #body > div.c-page.c-page--manuscript > div.c-page__content.u-no-padding > div.c-search-page > div.c-search-page__content > div.c-search-page__load-more-wrapper > button
        load_more_link = browser.find_element_by_xpath(
            "/html/body/div[1]/div[3]/div[1]/div[2]/div[5]/button"
        )  # body > div.c-page.c-page--manuscript > div.c-page__content.u-no-padding > div.c-search-page > div.c-search-page__content > div.c-search-page__load-more-wrapper > button
        count = 12
        for i in range(0, int(refresh)):
            try:
                load_more_link.click()
                time.sleep(5)
                count = int(count) + 12
                print("Refreshing html…")
            except Exception:
                pass
    browser.implicitly_wait(7)
    html_source = browser.page_source
    browser.close()

    with open("img/ll_source/" + scroll + ".html", "w") as htm:
        htm.write(html_source)
        htm.close()
    return html_source


def parse_source(html):
    """
    Parse source and return PAMs in list
    """
    PAMS = []
    comp_data = {}
    frag_data = {}

    soup = BeautifulSoup(html, "lxml")
    
    
    # print(len(img_details)) #check if result is the same as the showing X of X 
    # print(image_content.prettify()) #check content in output

    sidebar = soup.find('div', {'class': "c-search-sidebar u-hide-small"})
    # print(sidebar.prettify())

    ## Element :: Get The Title of the Composition
    title = soup.find('div', {"class": "c-search-sidebar__model-id c-search-sidebar__model-id--with-tooltip"})
    qnum, humRead = title.text.split('-')
    comp_data['ed_abbr'] = qnum.strip()
    comp_data['title'] = humRead.replace(' ', '')
    
    sidebar_tags = sidebar.find_all('a', {'class': 'c-item-metadata__facet'})
    
    comp_data['cave_search'] = sidebar_tags[0].text.strip()
    comp_data['composition'] = sidebar_tags[1].text.strip()
    comp_data['text_type'] = sidebar_tags[2].text.strip()
    comp_data['language'] = sidebar_tags[3].text.strip()
    comp_data['script_style'] = sidebar_tags[4].text.strip()
    comp_data['script'] = sidebar_tags[5].text.strip()
    comp_data['material'] = sidebar_tags[6].text.strip()



    #get body content
    image_content = soup.find('div', {'class': 'o-search-result-layout__wrapper'})
    # TODO: Pick up here and parse each image container into a dictionary
    img_thumbs = image_content.find_all('div', {'class': 'c-image-result__image'})

    # TODO: add each fragment dictionary to the comp_data dictionary
    
    # print(image_content.prettify())
    
    img_regex = re.compile('o-search-result-layout.*')
    imgs = image_content.find_all('a', {'class': img_regex})
    for index, img in enumerate(imgs):
        
        # Fragment Thumbnail
        url_div = img.find('div', {'class': 'c-image-result__image'})
        thumb_re = re.compile(r'((http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9%_:?\+.~#&//=]*))')
        thumb_http = thumb_re.search(url_div['style'])
        frag_data['thumb'] = thumb_http.group(1)

        frag_specs = img.find('div', {'class': 'c-image-result__metadata'})

        # Fragment Title (B-NUM)
        frag_data['title'] = frag_specs.find('span', {'class': 'c-image-result__title'}).text.strip()
        
        # Fragment Plate Numbers
        frag_data['plate_nums'] = frag_specs.find('div', {'class': 'c-image-result__plate-numbers'}).text.strip()
        
        raw = frag_specs.text.strip()

        # Regex for Date taken:
        date_is = re.compile(r'Taken \w+ (\d{,4})')
        img_date_found = date_is.search(raw)
        frag_data['img_date'] = img_date_found.group(1)
        
        side_is = re.compile(r'\b(Verso)\b|\b(Recto)\b', flags=re.IGNORECASE)
        side = side_is.search(raw)
        if side is not None:
            frag_data['side'] = side.group(1)
        else:
            frag_data['side'] = None

        type_is = re.compile(r'(\b(Infrared) Image\b|\b(Color) Image\b|\b(Scanned Infrared) Negative\b)', flags=re.IGNORECASE)
        type = type_is.search(raw)
        frag_data['type'] = type.group(1)
        
        pam_is = re.compile(r'PAM M(\d{,2}\.\d{,3})')
        pam = pam_is.search(raw)
        if pam is not None:
            frag_data['pam'] = pam.group(1)
        else:
            frag_data['pam'] = None

        
        # TODO: REINDEX PLATE NUM IF PAM is not None:
        print(frag_data)

        # TODO: Create final JSON for each fragment (not composition!)
        
    return PAMS


def fetch_iaa(q_sig):
    """
    Grab source page for Q_Siglum and Parse PAM Images
    """
    scroll_source = get_source(q_sig)
    return parse_source(scroll_source)

