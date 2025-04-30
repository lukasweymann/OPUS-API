FROM python:3.10
ENV BINPATH=/opt/bin
ENV LANG=C.UTF-8
ENV TZ=Europe/Madrid

# Install Apache and configure system
RUN apt-get update && \
    apt-get install -y apache2 bash && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    rm -rf /var/lib/apt_lists/*

# Create directories
RUN mkdir -p /home/cloud-user/OPUS-API
RUN mkdir -p /var/www
RUN mkdir -p /var/run/apache2
RUN mkdir -p /var/lock/apache2

# Set up virtual environment
COPY requirements.txt /home/cloud-user/OPUS-API/requirements.txt
RUN python3.10 -m venv /home/cloud-user/OPUS-API/opusapienv

# Install dependencies including Gunicorn
RUN /usr/bin/bash -c "source /home/cloud-user/OPUS-API/opusapienv/bin/activate && \
pip install --no-cache-dir --upgrade pip && \
pip install --no-cache-dir flask==2.3.2 werkzeug==2.3.3 gunicorn==20.1.0 && \
pip install --no-cache-dir -r /home/cloud-user/OPUS-API/requirements.txt && \
deactivate"

# Copy application files
COPY . /home/cloud-user/OPUS-API

# Configure database
RUN mv /home/cloud-user/OPUS-API/opusdata.db /var/www/
RUN chmod 774 /var/www/opusdata.db

# Set environment variables
ENV OPUSAPI_PATH=/home/cloud-user/OPUS-API
ENV OPUSAPI_DB=/var/www/opusdata.db
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/var/log/apache2

# Expose ports
EXPOSE 5000

# Create and make executable a startup script
RUN echo '#!/bin/bash\n\n\
export APACHE_RUN_USER=www-data\n\
export APACHE_RUN_GROUP=www-data\n\
export APACHE_PID_FILE=/var/run/apache2/apache2.pid\n\
export APACHE_RUN_DIR=/var/run/apache2\n\
export APACHE_LOCK_DIR=/var/lock/apache2\n\
export APACHE_LOG_DIR=/var/log/apache2\n\n\
echo "ServerName localhost" >> /etc/apache2/apache2.conf\n\n\
# Start Apache in foreground with debug logging
/usr/sbin/apache2 -D FOREGROUND -e debug &\n\n\
# Start Flask with debug logging and access logging
source /home/cloud-user/OPUS-API/opusapienv/bin/activate && \
cd /home/cloud-user/OPUS-API && \
gunicorn -w 4 --bind 0.0.0.0:5000 --log-level debug --access-logfile - --error-logfile - opusapi:app' > /start.sh
RUN chmod +x /start.sh

# Start both services using the script
CMD ["/start.sh"]