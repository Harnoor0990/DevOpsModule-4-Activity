FROM docker.io/python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
EXPOSE 5000
RUN useradd -m appuser
USER appuser
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]