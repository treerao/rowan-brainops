FROM docker:cli
RUN apk add --no-cache socat
COPY handler.sh /usr/local/bin/handler.sh
RUN chmod +x /usr/local/bin/handler.sh
EXPOSE 9111
CMD ["socat", "TCP-LISTEN:9111,reuseaddr,fork", "EXEC:/usr/local/bin/handler.sh"]
