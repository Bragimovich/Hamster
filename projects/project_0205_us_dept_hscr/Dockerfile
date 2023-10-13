FROM hamster:v0.10.1 AS repo

USER hamster:1001
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0205/
COPY projects/project_0205 projects/project_0205/
CMD /bin/sh -lc "ruby hamster.rb --grab="

