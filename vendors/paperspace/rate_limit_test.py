import os
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from time import time
from threading import Event

apikey = os.getenv("PAPERSPACE_APIKEY")
machine_id = "ps0n56zmm"

url = "https://api.paperspace.io/machines/getMachine"
headers = {"X-Api-Key": apikey}
params = {"publicMachineId": machine_id}

jobs_cancelled = Event() # Thread-safe flag used to cancel requests
responses = [] # (status, text) pairs for each request


def make_request(jobs_cancelled):
	if jobs_cancelled.set(): # Check if the flag is not set
		return (None, None)

	# Make a request, and read out status/text
	r = requests.get(url, headers=headers, params=params)
	status = r.status_code
	text = r.text

	# If the status was non-200, cancel jobs
	if status != 200:
		jobs_cancelled.set()

	return (status, text)


# Setup for multiprocessing
max_requests = 10_000
max_workers = 50
print(f"Setting up {max_requests} jobs across {max_workers} workers")
with ThreadPoolExecutor(max_workers=max_workers) as executor:
	# Create futures
	futures = []
	for i in range(max_requests):
		print(f"\rSubmitting job {i+1} ({int(100*(i+1)/max_requests)}%)", end="")
		futures.append(executor.submit(make_request, jobs_cancelled))
	print("")

	# Process tasks as available
	for i, future in enumerate(as_completed(futures)):
		status, text = future.result()
		print(f"\rReceived response {i+1}, status {status} ({int(100*(i+1)/max_requests)}%)", end="")
		responses.append((status, text))
	print("")
