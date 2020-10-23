# Filtering

The UI contains a powerful search box in the top right.

Here's a quick rundown of what it can do.

## Regex Matching

By default, if you just start typing, it will do a regex match on names of torrents. These terms are space separated and individually form their own regexes. You can use regex operators here:

```
boo     # find all torrents containing boo
^boo    # .. with a name starting with boo
boo$    # .. with a name ending with boo
b.o     # .. with names containing b, followed by any single char, followed by o
boo hoo # .. with both boo, and hoo, anywhere in the name (not necessarily in that order)
```

This is smart-case sensitive. If you type an uppercase character then only exact-case matching is performed. If it's all lowercase, then case-insensitive matching is done.

## Exact Substring Matching

If you don't want regex, surround a term with quotes. This will disable the regex engine and do an exact match. This is normally most useful if you want to search for a space, or other regex operator characters:

```
"^boo"      # containing ^boo
"boo hoo"   # containing boo hoo exactly
```

## Field Operators

All the above is just a bit of a shortcut. You can specify the name of a field, followed by an operator, followed by the same search terms used above, and so far all of them have been shortcuts:

```
name~boo
name~^boo       # starts with boo
name=^boo       # contains ^boo
name="boo hoo"
```

Valid fields and operators are listed below. Note the difference in behaviour between `~` and `=`. One considers the term to be a regex, the other uses it as a substring; see Operators below.


### Fields

Most of these are self explanatory.

```
status     (status)
name       (string)
label      (string)
tracker    (string)
done       (float)  # percentage, use 0-100
ratio      (float)
started    (time)
finished   (time)
created    (time)
size       (size)
downloaded (size)   # bytes downloaded
uploaded   (size)   # bytes uploaded
down       (size)   # download speed (bytes/sec)
up         (size)   # up speed (bytes/sec)
seeders    (int)    # Seeders Total
seedersc   (int)    # Seeders Connected
peers      (int)    # Peers Total
peersc     (int)    # Peers Connected
```

### Operators

There are different types of fields as indicated in the brackets above.

The status field only supports equality or non-equality; `=` or `!=`. It accepts the following options `seeding`, `error`, `downloading`, `paused`, `stopped`, `hashing`. For example:

```
status=paused
status!=seeding
```


For string fields:

```
=       # contains (substring)
!=      # does not contain
==      # exactly equal to (entire string match)
!==     # not equal to
~       # matches (regex)
!~      # does not match
```

Granted, some of these read a bit oddly, but I started with `~` to mean regex, then figured that entire string equality wouldn't be used that often so relegated it to the longer `==`, which left `=` for contains. Suggestions for other symbols welcome.

size/time/int/float fields make a bit more sense:

```
=       # equal to
!=      # not equal to
>       # greater than
>=      # greater than or equal to
<       # less than
<=      # less than or equal to
```

Size fields (torrent size, downloaded, uploaded) behave like int fields but also accept suffixes to make writing sizes easier. These are `K`, `M`, `G`, and `T`. You can also add on an `i` to make them Base2, eg `Mi`. The trailing `b` is optional, so `M` and `MB` are equivalent. Finally, all these suffixes are entirely case-insensitive. `Mi`, `MiB`, `mi`, and `mib` are all equivalent.

```
size<100     # no suffix means bytes - size below 100 bytes
size<100M    # size below 100MB
size<100MB   # size below 100MB
size<100mib  # size below 100MiB ; suffixes are all case-insensitive
```

Time fields accept relative intervals or absolute dates, like so:

```
started<1w         # started less than a week ago
created>2y         # created more than 2 years ago
started>2020-01-01 # started after January 1st, 2020
started>2020/01/01 # started after January 1st, 2020
```

Valid suffixes here are `s` (second), `m` (minute), `h` (hour), `d` (day), `w` (week), and `y` (year). Note that "years" are 31,536,000 seconds, not calendar years.

The absolute date syntax implicitly nails the time to midnight. So you can't currently do `started=2020-01-01` and expect useful results I'm afraid (but `started>=2020-01-01 started<2020-01-02` would work). Maybe in future. Maybe also support times in future.

## AND/OR keywords

By default, all terms entered are `AND`ed together. You can specify AND explicitly if you like. These are equivalent:

```
boo hoo
boo and hoo
boo AND hoo # and/AND is case-insensitive
```

If you actually want to search for the term and, quote it: `"and"`.

The other keyword is `OR`, which is again case-insensitive:

```
boo or hoo
```

And naturally this works for fields:

```
up>0 or down>0    # torrents with any activity
```

## Aliases

To ease filtering for some common expressions, there are some defined shortcut aliases:

```
$active           # equal to up>0 or down>0
$idle             #          up=0 down=0
$stuck            #          done<100 down=0 status!=stopped status!=paused
```

## TODO

  * precedence isn't currently supported. I tried, but reached the limits of my elm/parser knowhow. Parsing the trailing `)` got problematic :(
