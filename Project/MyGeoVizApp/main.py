"""
Author: Haolin Li
Last Updated: 12/10/2023

This script downloads the Continuum of Care (CoC) shapefiles from the
HUD Exchange website. The script downloads the shapefiles for all
states for a given year. The script creates a directory structure
that is organized by year and state. The script will not download
shapefiles for a state if the shapefiles already exist in the
target directory.

target directory structure:
    Data
    ├── 2007
    │   ├── Alabama
    │   │   ├── CoC_GIS_2007.shp
    │   │   ├── CoC_GIS_2007.shx
    │   │   ├── ...
    │   ├── Alaska
    │   │   ├── ...
    │   ├── ...
    ├── 2008
    │   ├── ...
    ├── ...
"""

import os
import requests
import zipfile
from io import BytesIO

# states and their abbreviations
states = {
    "MI": "Michigan"
}

base_url = "https://files.hudexchange.info/reports/published"
target_directory = "Data"


def download_and_extract_coc_shapefiles(year, states, base_url, target_directory):
    for state_abbr, state_name in states.items():
        url = f"{base_url}/CoC_GIS_State_Shapefile_{state_abbr}_{year}.zip"
        response = requests.get(url)

        if response.status_code == 200:
            # make sure the target directory exists
            state_directory = os.path.join(target_directory, str(year), state_name)
            os.makedirs(state_directory, exist_ok=True)

            # process the zip file
            with zipfile.ZipFile(BytesIO(response.content)) as zip_ref:
                for member in zip_ref.infolist():
                    # add the year and state name to the path
                    path_parts = member.filename.split('/')[1:]
                    extracted_path = os.path.join(state_directory, *path_parts)

                    if member.is_dir():
                        os.makedirs(extracted_path, exist_ok=True)
                    else:
                        with open(extracted_path, 'wb') as file:
                            file.write(zip_ref.read(member.filename))

            print(f"Downloaded and extracted {state_name} data for {year}")
        else:
            print(f"Failed to download data for {state_name} in {year}")


# and other years
for year in range(2010, 2023):
    download_and_extract_coc_shapefiles(year, states, base_url, target_directory)

