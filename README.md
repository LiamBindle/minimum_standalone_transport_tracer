## Minimum size standalone transport tracer run directory


#### Overview
This is a standalone simulation which requires <1GB of memory. It takes about 20 seconds to run. The compressed size is <2MB. 

It's a C6 transport tracer simulation, with emissions zeroed out.

#### Running
You can run the simulation* with
```shell
$ git clone https://github.com/LiamBindle/minimum_standalone_transport_tracer.git
$ cd minimum_standalone_transport_tracer
$ mpirun -np 6 gchp
```
\*_assuming your environment is loaded and `gchp` is in your `$PATH`_

#### Validating

You can validate the run with
```shell
$ ncks --chk_nan OutputDir/GCHP.SpeciesConc.*.nc4
```

