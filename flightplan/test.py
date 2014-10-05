import re
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium import webdriver
from datetime import datetime

def getPrice(query):

	q = ""
	for stop in query:
		q = q + "/" + stop[0] + "-" + stop[1] + "/" + stop[2].strftime('%Y-%m-%d')

	# Start the WebDriver and load the page
	wd = webdriver.Firefox()
	wd.get("http://www.kayak.de/flights" + q)
	
	# Wait for the dynamically loaded elements to show up
	#WebDriverWait(wd, 1000).until(EC.title_contains("von"))

	# And grab the page HTML source
	html_page = wd.page_source
	wd.quit()
	
	pattern = re.compile(u"bestPrice[^>]*>[0-9]+")
	minprice = -1
	for p in pattern.findall(html_page):
		price = int(p[p.index('>') + 1:])
		if minprice == -1 or price < minprice:
			minprice = price
	
	return minprice

print(getPrice( (
					("VIE", "TXL", datetime(2015, 2, 3)),
					("TXL", "NYC", datetime(2015, 2, 7)),
					("NYC", "VIE", datetime(2015, 2, 10)),
				) ))

