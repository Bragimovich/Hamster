# Hamster


Then run installator and follow its instractions:

```
./install.sh
```

## How to run it

The Hamster now can work in two ways.

Before you go by one of them, you need to fill file `~/ini/Hamster/config.yml` with actual content if you started this script on your local computer.

### Ruby way

```bash
hamster --dig=N
```

Then write a code at `scrape.rb`, and try:

```bash
hamster --grab=N
```

Where `N` is a project number you can find at the [LokiC Scrape Tasks][] under the column **id**. More details you
can find at the [Google Document][].

### Docker way

```bash
hamster dig N
```

Then write a code at `scrape.rb`. While you will create your script you can debug it using Docker container with all needed environment. To run this container just try:

```bash
hamster docker
```

You'll see something like this:

```
~/Hamster $ 
```

Ok, you're in the Docker container. You can use it as typical Linux CLI. It has all needed gems to develop you script. To run your script in the container, just type:

```bash
ruby hamster.rb --grab=N
```

Type `exit` if you want to finish the session.

Also, you can run your script using the fallowing command:

```bash
hamster grab N
```

[LokiC Scrape Tasks]: https://lokic.locallabs.com/scrape_tasks
[Google Document]: https://docs.google.com/document/d/1q0beVvXyA_NWhaTTmcP3GqcvRsg95io1yy1gSSFqD2A/
