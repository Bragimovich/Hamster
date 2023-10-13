FROM hamster:v0.10.1 AS repo

USER hamster:1000
WORKDIR /home/hamster/Hamster

RUN mkdir -p projects/project_0073_pr_com_scrape/
COPY projects/project_0073_pr_com_scrape projects/project_0073_pr_com_scrape/
CMD /bin/sh -lc "ruby hamster.rb --grab="

