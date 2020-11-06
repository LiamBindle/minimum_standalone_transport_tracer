## Minimum size standalone transport tracer run directory


#### Overview
This is a standalone simulation which requires <1GB of memory. It takes about 20 seconds to run. The compressed size is <2MB. 

It's a 1-day 6-core C6 transport tracer simulation, with emissions zeroed out.

#### Running
You can run the simulation* by doing
```shell
$ git clone https://github.com/LiamBindle/minimum_standalone_transport_tracer.git
$ cd minimum_standalone_transport_tracer
$ mpirun -np 6 gchp
```
\*_assuming your environment is loaded and `gchp` is in your `$PATH`_

#### Rerunning
You can rerun the simulation by doing
```shell
$ rm -f cap_restart gcchem* OutputDir/*
$ mpirun -np 6 gchp
```
\*_assuming your environment is loaded and `gchp` is in your `$PATH`_


#### Validating
You can validate the run by doing
```shell
$ ncks --chk_nan OutputDir/GCHP.SpeciesConc.*.nc4
```

##### Uses
This simulation is intended to enable CI  runtime tests. It may also be useful for tutorials since it's standalone, or for troubleshooting GCHP on a new cluster.
