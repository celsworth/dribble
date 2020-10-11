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

For the time being, this is always case-insensitive (this is a TODO to add smartcase like below)

## Exact Substring Matching

If you don't want regex, surround a term with quotes. This will disable the regex engine and do an exact (case-insensitive) match. This is normally most useful if you want to search for a space, or other regex operator characters:

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

Valid fields and operators are listed below. Note the difference in behaviour between `~` and `=`. One considers the term to be a regex, the other uses it as a substring.



### Fields

Most of these are self explanatory.

```
name    (string)
size    (size)
done    (float)  # percentage, use 0-100
label   (string)
peers   (int)    # Peers Total
ratio   (float)
```

> TODO: add the rest :)


### Operators

For string fields:

```
=       # contains (substring)
!=      # does not contain
==      # exactly equal to (entire string match)
!==     # not equal to
~       # matches (regex)
!~      # does not match
```

For size/int/float fields:

```
=       # equal to
!=      # not equal to
>       # greater than
>=      # greater than or equal to
<       # less than
<=      # less than or equal to
```

> TODO: add more, anything you could think of

Size fields (torrent size, downloaded, uploaded) behave like int fields but also accept suffixes to make writing sizes easier. These are `K`, `M`, `G`, and `T`. You can also add on an `i` to make them Base2, eg `Mi`. The trailing `b` is optional, so `M` and `MB` are equivalent. Finally, all these suffixes are entirely case-insensitive. `Mi`, `MiB`, `mi`, and `mib` are all equivalent.

```
size<100     # no suffix means bytes - size below 100 bytes
size<100M    # size below 100MB
size<100MB   # size below 100MB
size<100mib  # size below 100MiB ; suffixes are all case-insensitive
```



TODO: exact match in field operators?

> name="foo"

