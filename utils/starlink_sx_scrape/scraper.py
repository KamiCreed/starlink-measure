#!/usr/bin/env python3

import os
from time import sleep
from time import time
from datetime import datetime
import re

from config import local_stores

import pandas as pd
from bs4 import BeautifulSoup

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

LATENCY = 'LATENCY'
AZIMUTH = 'Az'
ELEVATION = 'El'

def main():
    chrome_options = Options()
    #chrome_options.add_argument("--disable-extensions")
    #chrome_options.add_argument("--disable-gpu")
    #chrome_options.add_argument("--no-sandbox") # linux only
    #chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")
    # chrome_options.headless = True # also works

    driver = webdriver.Chrome(options=chrome_options)
    driver.get('https://starlink.sx')
    driver.implicitly_wait(5)

    for key, val in local_stores.items():
        driver.execute_script("window.localStorage.setItem(arguments[0], arguments[1]);", key, val)

    driver.refresh()
    element = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "satellites-table"))
    )

    file_timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    dest_fold = 'starlink_satellite_data'
    os.makedirs(dest_fold, exist_ok=True)
    dest_path = os.path.join(dest_fold, f"satellites_{file_timestamp}.csv")

    for i in range(30):
        time_start = time()
        content = driver.page_source

        soup = BeautifulSoup(content, 'html.parser')
        num_sats_str = str(soup.find('div', dict(id='satellites')))
        num_sats = re.search('(\d+)', num_sats_str).group()
        
        sat_table = soup.find("tbody", dict(id='satellites-table')).parent
        df_table = pd.read_html(str(sat_table))[0]
        df_table[LATENCY] = df_table[LATENCY].str.extract('(\d+\.\d+)', expand=False)
        df_table[AZIMUTH] = df_table[AZIMUTH].str.extract('(\d+\.?\d*)', expand=False)
        df_table[ELEVATION] = df_table[ELEVATION].str.extract('(\d+\.?\d*)', expand=False)
        df_table['timestamp'] = time_start
        df_table['connectable_sats'] = num_sats

        df_table.to_csv(dest_path, mode='a', index=False, header=not os.path.exists(dest_path))
        time_end = time()
        sleep(1 - (time_end - time_start))

    driver.close()

main()
