FROM hamster:v0.10.0 AS repo

USER hamster:1001
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0303/
COPY projects/project_0303 projects/project_0303/
CMD /bin/sh -lc "ruby hamster.rb --grab="

