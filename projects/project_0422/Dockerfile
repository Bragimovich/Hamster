FROM hamster:v0.10.1 AS repo

USER hamster:1000
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0422/
COPY projects/project_0422 projects/project_0422/
CMD /bin/sh -lc "ruby hamster.rb --grab="
