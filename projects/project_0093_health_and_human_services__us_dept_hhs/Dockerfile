FROM hamster:v0.10.1 AS repo

USER hamster:1001
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0093/
COPY projects/project_0093 projects/project_0093/
CMD /bin/sh -lc "ruby hamster.rb --grab="

