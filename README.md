# sizefmt

A small library to format file sizes.

### Synopsis

```d
unittest
{
    assert("%s".format(Size(1)) == "1 B");
    assert("%s".format(Size(42)) == "42 B");
    assert("%g".format(Size(1024)) == "1 KB");
    assert("%.2f".format(Size(2_590_000)) == "2.47 MB");
}
```

### Options

You can control the formatting rules with `Size.config.options`:
```d
unittest
{
    Size.config.push();
    scope(exit) Size.config.pop();
    
    Size.config.symbol = "O";
    Size.config.unitName = "octet";
    Size.config.unitNamePlural = "octets";
    Size.config.prefixUse = PrefixUse.decimal;
    Size.config.useNameIfNoPrefix = true;

    assert("%s".format(Size(1)) == "1 octet");
    assert("%s".format(Size(42)) == "42 octets");
    assert("%s".format(Size(1000)) == "1.00 kO");
    assert("%.2f".format(Size(2_590_000)) == "2.59 MO");
}

unittest
{
    Size.config.push();
    scope(exit) Size.config.pop();

    Size.config.spacing = Spacing.tabular;
    assert("|%4.1f|".format(Size(42)) ==        "|  42 B |");
    assert("|%4.1f|".format(Size(2_590_000)) == "| 2.5 MB|");

    Size.config.prefixUse = PrefixUse.IEC;
    assert("|%s|".format(Size(42)) ==        "|     42 B  |");
    assert("|%s|".format(Size(2_590_000)) == "|   2.47 MiB|");
}
```

---
License: BSL 1.0

Copyright 2014, Nicolas Sicard
