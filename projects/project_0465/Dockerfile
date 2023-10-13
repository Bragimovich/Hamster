FROM hamster:v0.10.1 AS repo

USER hamster:1005
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0506/
COPY projects/project_0506 projects/project_0506/
CMD /bin/sh -lc "ruby hamster.rb --grab="

