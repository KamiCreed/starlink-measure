First download/install the Chrome webdriver either using `apt` or place
the .exe in the same folder.

```
sudo apt install chromium-chromedriver
```

Use pipenv to install packages and setup environment:
```
pipenv install
pipenv shell
```

Create the file `config.py` and populate with the following:

```python
local_stores = {
    'disclaimerShown': 'true',
    'observerLat': '41.49923',
    'dishyAngle': '18',
    'dishyTilt': '18',
    'observerLng': '1.8950696'
    }
```

`observerLat` and `observerLng` is your Starlink dishy's latitude and longitudes.

Then, just run the scraper:
```
python scraper.py
```
