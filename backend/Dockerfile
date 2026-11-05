FROM python:3.12-slim

WORKDIR /code

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Chromium for the bank-deal scraper (services/bank_scan.py). `--with-deps`
# pulls the shared libraries the browser needs, which the slim image lacks.
RUN playwright install --with-deps chromium

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
