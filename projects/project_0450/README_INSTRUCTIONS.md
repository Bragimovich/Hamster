There are mainly 3 functions in the manager:

-store_case_nubmers
-download
-store


- store_case_numbers:

this method iterates a loop from letter A to Z and search organisations by letter
when we search using letter it gives us a bunch of records. Every Record has multiple cases against their searches.
we save the case numbers and other party information and store it in the database on runtime.
iterates on every letter and every page against the search.

-download:

this function firstly fetch all the case_numbers which we inserted using (store_case_numbers).
we search using the case_numbers and it redirects us to the main page.
we download the first page and see if there are pagination exists on the activities
we download all the pages and the save them in the directory with the name of case numbers

-store:
we fetch all the folders of the case numbers and open them one by one and parse the files within them.
