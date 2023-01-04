# Table of Contents

- [TieredMemDB](#tieredmemdb)
- [Features](#features)
- [TieredMemDB documentation](#tieredmemdb-documentation)
  - [Requirements](#requirements)
  - [Building from sources](#building-from-sources)
  - [Configuration parameters](#configuration-parameters)
  - [Additional INFO statistics](#additional-info-statistics)
- [Memkind](#memkind)
  
# TieredMemDB
TieredMemDB is a Redis branch that fully uses the advantages of DRAM and Intel Optane Persistent Memory (PMEM). It is fully compatible with Redis and supports all its structures and features. The main idea is to use a large PMEM capacity to store user data and DRAM speed for latency-sensitive structures. We also offer the possibility of defining the DRAM to PMEM ratio, which will be automatically monitored and maintained by application. This allows you to fully adapt the utilization of the memory to your hardware configuration.

The source code of TieredMemDB can be found in this [GitHub repository](https://github.com/TieredMemDB/TieredMemDB).

# Features
* Different types of memory - use both DRAM and PMEM in one application.
* Memory allocation policy - define how each memory should be used. You can specify DRAM / PMEM ratio that will be monitored and maintained by application.
* Redis compatible - supports all features and structures of Redis.
* Configurable - use simple parameters to configure new features.

# How to create new branch based on Redis tag branch

New realeases are uploaded to Redis from time to time. In order to make Redis
work with pmem, appropriate changes must be made.  It is needed to create
a new branch on tieredmemdb based on the Redis. This manual will present
an example based on creating new branch 7.0.5-devel from Redis tag 7.0.5.

1. First, administrator should create a new branch on tieredmemdb based on
clean Redis branch (7.0.5).
2.	Fork tieredmemdb on github:

    https://github.com/TieredMemDB/TieredMemDB. 
    
3.	Create a local clone of the tieredmemdb.
4.	Switch on a new branch based on the Redis tag:

    'git switch -c <tag_name-devel> (git switch -c 7.0.5-devel)'

5.	Now it is necessary to add changes that makes Redis supports pmem. To
do this, you should use commits from the previous tieredmemdb branch. You
can use pre-made script to generate cherry-pick command based on the previous
tieredmemdb branch. You need to use the command:

    'python3 tmdb-cherry-pick.py tieredmemdb/<branch name>'
    ('python3 tmdb-cherry-pick.py tieredmemdb/7.0.4-devel')

The output will look like:

    'cherry-pick <commit sha> <commit sha> ….'

That commits will make Redis work compatible with pmem.
You will find this pre-made python script on:

    https://github.com/intel-innersource/applications.benchmarking.benchmark.pmdk-benchmarks-automation/blob/master/utils/tmdb-add-pmem-support.py

6.	Use generated cherry-pick command to add the appropriate commits to
your branch based on Redis.
7.	Sometimes there will be some merge conflict to solved. Go through
them carefully.
8.	Push changes to your fork:

    'git push <remote name>'

9.	You can go to github’s site and create a pull request
( https://help.github.com/articles/creating-a-pull-request/ ). After
that wait until your changes passed the tests on github and the benchmark tests.
The tests allow you to check whether the branch has been created correctly.

# TieredMemDB documentation
## Requirements
TieredMemDB requires Linux kernel 5.1 or higher. This version introduces [KMEM DAX](https://patchwork.kernel.org/project/linux-nvdimm/cover/20190225185727.BCBD768C@viggo.jf.intel.com/) feature which is used to expose PMEM device as a system-ram.

Information how to configure KMEM DAX are available on this [blog post](https://pmem.io/2020/01/20/memkind-dax-kmem.html).

## Building from sources
For automatic recognition of KMEM DAX NUMA node libdaxctl-devel (v66 or later) is necessary to be installed in your system.

TieredMemDB sources are available on github.

Libmemkind is used as a submodule so it need to initialized with:

```
% git submodule init
% git submodule update
```

Building with Memkind as an allocator is done by:

```
% make MALLOC=memkind
```

## Configuration parameters
The application has additional configuration parameters related to the handling of two types of memories.

### Memory Allocation Policy
The main one is the ability to define Memory Allocation Policy. It allow modifying mechanism how heap memory is allocated via zmalloc() function calls. It can target DRAM, Persistent Memory or both. In general, bigger allocations should be stored in Persistent Memory which provides a higher capacity, while smaller and more frequently used should be stored in DRAM.

Memory Allocation Policy is defined in redis.conf or via command line argument:

*memory-alloc-policy:*
* *only-dram* - use only DRAM, do not use Persistent Memory
* *only-pmem* - use only Persistent Memory, do not use DRAM
* *threshold* - use both Persistent Memory and DRAM and threshold described by static-threshold
* *ratio* - use both Persistent Memory and DRAM and ratio described by dram-pmem-ratio

**Parameters used when THRESHOLD policy is selected:**

When Threshold policy is selected, application will check *static-threshold* parameter. Allocation of the size smaller than this threshold goes to DRAM. Allocation of the size equal or bigger than this threshold goes to Persistent Memory. Parameter can be modified when application is running using *CONFIG SET*.

Example:

Minimum allocation size measured in bytes which goes to Persistent Memory

```
static-threshold 64
```

**Parameters used when RATIO policy is selected:**

Application allocates part of data in DRAM and part in Persistent Memory based on value of internal dynamic threshold and *dram-pmem-ratio*. Application monitors DRAM and Persistent Memory utilization and modifies value of internal dynamic threshold by increasing or decreasing it to achieve expected *dram-pmem-ratio*.

The syntax of *dram-pmem-ratio directive* is the following:

*dram-pmem-ratio <dram_value> <pmem_value>*

Expected proportion of memory placement between DRAM and Persistent Memory. Real DRAM:PMEM ratio depends on workload and its variability. *dram_value* and *pmem_value* are values from range <1,INT_MAX>

Example:

Place 25% of all memory in DRAM and 75% in Persistent Memory

```
dram-pmem-ratio 1 3
```

Internal dynamic threshold have minimum possible limit defined by *dynamic-threshold-min* and maximum possible limit defined by *dynamic-threshold-max*. They should be adapted to the size of the objects handled by the database.

Initial value of dynamic threshold

```
initial-dynamic-threshold 64
```

Minimum value of dynamic threshold. The use of lower values for this parameter may be required when the database handles a large number of objects of small size and the target ratio is set to allocate mainly from PMem, e.g. when the majority of objects will be smaller than 64 bytes a *dram-pmem-ratio* is set to 1-8.

```
dynamic-threshold-min 24
```

Maximum value of dynamic threshold

```
dynamic-threshold-max 10000
```

An additional parameter determines how often the application should monitor the current ratio and adjust the internal dynamic threshold.

DRAM/PMEM ratio period measured in milliseconds

```
memory-ratio-check-period 100
```

### Persistent Memory Variant
When the Memory Allocation Policy is set to a value other than *dram-only* it means that some memory will be allocated on one or more PMEM nodes.
Persistent Memory Variant specifies how the Memory Allocator chooses PMEM NUMA node and what happens when that node runs out of free space.

Persistent Memory Variant is defined in redis.conf or via command line argument:

* *single* - in this variant memory comes from the closest Persistent Memory NUMA node at the time of allocation. If there is not enough free memory in this node to satisfy an allocation request, inactive pages from this node are moved into the swap space.
* *multiple* - in this variant memory comes from the closest Persistent Memory NUMA node available at the time of allocation. When there is not enough free memory in this node to satisfy an allocation request, the allocation pattern switches to the next closest persistent NUMA node. When available space is exhausted in all persistent NUMA nodes - the swap space is used.

If there is no free memory left in the swap space, an "Out of Memory" error occurs, regardless of the value of Memory Variant. By default TieredMemDB uses a "single" variant.

Example:

Use all available PMEM NUMA nodes

```
pmem-variant multiple
```

### Hashtable on DRAM
The main hashtable may be one large allocation. In a situation where the base consists mainly of a large number of small keys and values, the allocation of the main hashtable affects significantly the PMEM/DRAM ratio. On the other hand, as it is very often used for writing and reading, so it should be placed in DRAM. The following option allows you to choose where you want to allocate the hashtable to depending on your needs.

Example:

Keep hashtable structure on DRAM or on PMEM

```
hashtable-on-dram yes/no
```

## Additional INFO statistics
With the *INFO MEMORY* command it is possible to monitor the parameters used by application to maintain DRAM/PMEM ratio. The following parameters have been added:

```
127.0.0.1:6379> info memory
 Memory
 …
 pmem_threshold:30
 used_memory_dram:865144
 used_memory_dram_human:844.87K
 used_memory_pmem:41216
 used_memory_pmem_human:40.25K
```


# Memkind
The Memkind allocator is crucial for the TieredMemDB application. It is used as an Extensible Heap Manager built on top of jemalloc which enables control of memory characteristics and a partitioning of the heap between kinds of memory. Memkind supports a type of memory based on KMEM DAX mechanism and the possibility of exposing memory from the device as an additional NUMA node.

Memkind is a general-purpose allocator, but for an application like Redis it was also optimized by passing specific parameters during “configure” part:

* The number of arenas – for PMEM-based memory types Memkind usually creates 4 x CPU arenas. For a single-threaded application, it can be limited to 1 arena. This speeds up scenarios when allocator statistics are gathered by iterating through all arenas.
* Lg_quantum – inherits the value from jemalloc config in Redis. It creates an additional allocation class which is very often used by Redis. This helps to increase memory utilization.
