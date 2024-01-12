---
title: "ClosedParser real-world testing"
excerpt: "ClosedXML has a new high-performance formula parser... so how to test it?"
categories: ["dev-diary"]
author: Jan Havlíček
image: /storage/blog/formulas-common-crawl/closedparser-web.png 
date: 2024-01-12 01:47:00
---

Formulas are a cornerstone of workbooks. They are used in basically every feature and have to be taken in account in the rest. It's imperative that it doesn't refuse to parse valid formula.

That is the reason why I invested a lot of time high-performance parser of formulas - ClosedParser. It also has a online demo page at [parser.closedxml.io](https://parser.closedxml.io/).

So how to check it? Of course there are unit tests and so on, but that is not enough. We need to know that it will actually work in the real world.

That is pretty important, because OOXML documentation is notoriously inaccurate and not in-line with what Excel actually supports.

# Research paper

One of the nice source of information about how are formulas used in the wild is the
[Enron's Spreadsheets and Related Emails: A Dataset and Analysis](https://www.researchgate.net/publication/304552688_Enron's_Spreadsheets_and_Related_Emails_A_Dataset_and_Analysis)
paper. It used data from bankrupt Enron corporation trial (yes, that one) to extract some nice information about Excel usage in the real world.

![Tux, the Linux mascot](/storage/blog/formulas-common-crawl/formula-statistics.png)
![Tux, the Linux mascot](/storage/blog/formulas-common-crawl/longest-chain.png)

The Enron and EUSES corpuses are nice, but are over two decades old. How about something newer?

# Common Crawl to the rescue

The CommonCrawl project is a non-profit that crawl the internet and provides free access to the crawled files. Surely we can find some Excel files
there.

Download files with expected mime using [commoncrawl-fetcher-lite](https://github.com/tballison/commoncrawl-fetcher-lite) and extract all formulas
from sheets using classic XML parsing and XPath in `xl/worksheets/sheet*.xml` files of XLSX. That eliminates the problem of not being able to get
formulas from more complicated files that can't be opened in ClosedXML.

There are of course some limitations, e.g. not all files report correct MIME type and would thus be skipped, but enough of them will report correct
one.

# Results

A large CSV file of 2'631'852 formulas. Parse it through ClosedParser and the result is 7 fails. Mostly invalid formulas.

```
"{}"
Array has to have at least one element

" $35 EACH)"
Incorrect formula

"+A432:B446B429:A433:A448"
Technically speaking, the `B446B429` could be valid defined name. Need to
investigate further.

"SUM(INDEX(Table1[PSU],1):_xlfn.SINGLE(Table1[PSU]))"
"SUM(INDEX(Table1[Top Board],1):_xlfn.SINGLE(Table1[Top Board]))"
"SUM(INDEX(Table1[Fan],1):_xlfn.SINGLE(Table1[Fan]))"
Invalid formula. SUM/SINGLE isn't ref function (=can't return reference) and
the range operator is thus invalid. Also, SINGLE function existed only in ~one
version of Excel and has been removed (not even deprecated).

"_xlfn.LAMBDA(_xlpm.range,
  _xlfn.LET(
    _xlpm.rng,IF(ISREF(_xlpm.range),_xlpm.range,INDIRECT(_xlpm.range)),
    _xlpm.first,_xlfn.TAKE(_xlpm.rng,1,1),
    _xlpm.last,_xlfn.TAKE(_xlpm.rng,-1,-1),
    ADDRESS(ROW(_xlpm.first),COLUMN(_xlpm.first),4)&"":""&
    ADDRESS(ROW(_xlpm.last),COLUMN(_xlpm.last),4)
  )
)(data[])"

This is an equivalent of `LAMBDA(x,x*x)(5)`, basically define lambda and
immediate evaluate it. That is not valid from grammar POV.
Yay, another case of OOXML inaccurate documentation.
```

It looks like a success and ClosedParser won't choke on real-world data.

# Looking forward

CommonCrawl is a great resource I am looking forward to utilize more. One of pretty important things to do will be to check how many files can
ClosedXML open and what is the most common reason why not. ClosedXML shouldn't crash on load of valid file.
