TieredMemDB
===========

This project is a fork of [Redis](https://redis.io), adapted for systems
with multiple memory tiers. New memory technologies include memories that
have very high bandwidth at the cost of latency, slower large capacity
at lower cost, sharing memory among multiple machines in a rack, and so on.

The overall performance of a system can be improved if frequently accessed
("hot") data is kept in a faster tier while "warm" data that still needs
to be readily available in memory (rather than disk or similar slow storage)
yet is not as critical, may be kept in a slower memory tier.

This README doesn't describe usual usage of Redis. We assume you already
have general experience with [Redis](https://github.com/redis/redis).


Building TieredMemDB
--------------------

Generally, TieredMemDB is close to vanilla Redis, and can be used on the
same set of systems. You can even build without tier support, as all
functionality of Redis should be left intact. To actually get the benefits
of memory tiers, you need the following extra dependencies:

    * ndctl and daxctl
    * memkind (included in tarballs)

Building TieredMemDB is as simple as:

    % make

As usual, you can -- and probably want to -- confirm the built code works
well:

    % make test

The crux of TieredMemDB is the tiered allocator, which beside `MALLOC=libc`
and `MALLOC=jemalloc` supported by Redis adds:

    % make MALLOC=memkind

but in release tarballs and this git tree, memkind is already the default.


Rebasing TieredMemDB
--------------------

The set of patches over base Redis that comprises TieredMemDB can be applied
onto your modified versions of Redis as well. To do that, or to update
Redis to a new minor version (because of eg. a security update), you rebase
the tree available on [GitHub](https://github.com/TieredMemDB/TieredMemDB),
or ask git to produce a patch, with our branch checked out:

    % git diff 6.2.6 @

which can then be applied via `patch` over, in this case, Redis 6.2.6.
