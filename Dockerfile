FROM python:3.10
ENV BINPATH=/opt/bin
ENV LANG=C.UTF-8
ENV TZ=Europe/Madrid

RUN apt-get update && \
    apt-get install -y apache2 bash && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    rm -rf /var/lib/apt_lists/*

# Create directories
RUN mkdir -p /home/cloud-user/OPUS-API
RUN mkdir -p /var/www


COPY requirements.txt /home/cloud-user/OPUS-API/requirements.txt
RUN python3.10 -m venv /home/cloud-user/OPUS-API/opusapienv

RUN /usr/bin/bash -c "source /home/cloud-user/OPUS-API/opusapienv/bin/activate && \
pip install --no-cache-dir --upgrade pip && \
pip install --no-cache-dir flask==2.3.2 werkzeug==2.3.3 gunicorn==20.1.0 && \
pip install --no-cache-dir -r /home/cloud-user/OPUS-API/requirements.txt && \
deactivate"

COPY . /home/cloud-user/OPUS-API

RUN mv /home/cloud-user/OPUS-API/opusdata.db /var/www/
RUN chmod 774 /var/www/opusdata.db

ENV OPUSAPI_PATH=/home/cloud-user/OPUS-API
ENV OPUSAPI_DB=/var/www/opusdata.db

EXPOSE 5000

RUN echo '#!/bin/bash\n\n\
source /home/cloud-user/OPUS-API/opusapienv/bin/activate && \
cd /home/cloud-user/OPUS-API && \
gunicorn -w 4 --bind 0.0.0.0:5000 --log-level debug --access-logfile - --error-logfile - opusapi:app' > /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
