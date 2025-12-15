# Use the minimal Alpine Linux base image
FROM alpine:latest

# Install curl and cron
RUN apk add --no-cache curl dcron

# Create a directory for persistent config
RUN mkdir -p /config

# Copy the script into the container
COPY check_ip.sh /usr/local/bin/check_ip.sh

# Make sure the script is executable
RUN chmod +x /usr/local/bin/check_ip.sh

# Add a cron job to run the script every hour
RUN echo "7 * * * * /usr/local/bin/check_ip.sh >> /var/log/cron.log 2>&1" | crontab -

# Create the log file for tailing
RUN touch /var/log/cron.log

# Command to run cron in the foreground and tail the log file
CMD ["sh", "-c", "crond -f -l 8 & wait $!"]
