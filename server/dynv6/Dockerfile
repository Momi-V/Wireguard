FROM alpine:latest

RUN apk add --no-cache bash curl bind-tools

ADD ./dyndns.bash /
RUN chmod +x ./dyndns.bash

CMD ["./dyndns.bash"]
